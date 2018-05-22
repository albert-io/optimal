defmodule Optimal do
  @moduledoc """
  Documentation for Optimal.
  """

  @type error :: {atom, String.t()}
  @type validation_result :: {:ok, Keyword.t()} | {:error, [error]}

  defdelegate schema(opts), to: Optimal.Schema, as: :new
  defdelegate schema(), to: Optimal.Schema, as: :new
  defdelegate merge(left, right), to: Optimal.Schema, as: :merge

  @doc """
  Validates opts according to a schema or the constructor for a schema. Raises on invalid opts.

      iex> Optimal.validate!([reticulate_splines?: true], opts: [:reticulate_splines?])
      [reticulate_splines?: true]
      iex> Optimal.validate!([reticulate_splines?: true], opts: [:load_textures?], extra_keys?: true)
      [reticulate_splines?: true]
      iex> schema = Optimal.schema(opts: [:reticulate_splines?], required: [:reticulate_splines?], extra_keys?: true)
      ...> Optimal.validate!([reticulate_splines?: true, hack_interwebs?: true], schema)
      [reticulate_splines?: true, hack_interwebs?: true]
      iex> Optimal.validate!([], opts: [:reticulate_splines?], required: [:reticulate_splines?])
      ** (ArgumentError) Opt Validation Error: reticulate_splines? - is required

  """
  @spec validate!(opts :: Keyword.t(), schema :: Optimal.Schema.t() | Keyword.t()) ::
          Keyword.t() | no_return
  def validate!(opts, schema = %Optimal.Schema{}) do
    case validate(opts, schema) do
      {:ok, opts} ->
        opts

      {:error, errors} ->
        message = message(errors)
        raise ArgumentError, message
    end
  end

  def validate!(opts, schema_config) do
    validate!(opts, schema(schema_config))
  end

  @spec validate(opts :: Keyword.t(), schema :: Optimal.Schema.t()) ::
          {:ok, Keyword.t()} | {:error, [error]}
  def validate(opts, schema) when is_map(opts) do
    validate(Enum.into(opts, []), schema)
  end
  def validate(opts, schema) when is_list(opts) do
    with_defaults =
      Enum.reduce(schema.defaults, opts, fn {default, value}, opts ->
        Keyword.put_new(opts, default, value)
      end)

    {:ok, with_defaults}
    |> validate_required(with_defaults, schema)
    |> validate_inclusion(with_defaults, schema)
    |> validate_types(with_defaults, schema)
    |> validate_extra_keys(with_defaults, schema)
    |> validate_custom(schema)
  end
  def validate(_opts, _schema) do
    {:error, [{:opts, "opts must be a keyword list or a map."}]}
  end

  @spec validate_custom(validation_result(), Optimal.Schema.t()) :: validation_result()
  defp validate_custom(
         validation_result = {:ok, opts},
         schema = %{custom: [{field, custom} | rest]}
       ) do
    result =
      case custom.(opts[field], field, opts, schema) do
        true ->
          validation_result
        false ->
          add_errors(validation_result, {field, "failed a custom validation"})
        :ok ->
          validation_result

        {:ok, updated_opts} ->
          {:ok, updated_opts}

        {:error, error_or_errors} ->
          add_errors(validation_result, error_or_errors)
        [] ->
          validation_result

        errors when is_list(errors) ->
          add_errors(validation_result, errors)
      end

    validate_custom(result, %{schema | custom: rest})
  end

  defp validate_custom(validation_result, _schema), do: validation_result

  @spec validate_types(validation_result(), Keyword.t(), Optimal.Schema.t()) ::
          validation_result()
  defp validate_types(validation_result, opts, %{types: types}) do
    Enum.reduce(types, validation_result, fn {field, type}, result ->
      cond do
        !Keyword.has_key?(opts, field) -> result
        Optimal.Type.matches_type?(type, opts[field]) -> result
        true ->
          message = "must be of type " <> sanitize_type(type)
          add_errors(result, {field, message})
      end
    end)
  end

  @spec sanitize_type(term) :: String.t()
  defp sanitize_type(%struct{}), do: sanitize_type({:struct, struct})
  defp sanitize_type(term), do: inspect(term)

  @spec validate_required(validation_result(), Keyword.t(), Optimal.Schema.t()) ::
          validation_result()
  defp validate_required(validation_result, opts, %{required: required}) do
    Enum.reduce(required, validation_result, fn key, result ->
      if is_nil(opts[key]) do
        add_errors(result, {key, "is required"})
      else
        result
      end
    end)
  end

  @spec validate_inclusion(validation_result(), Keyword.t(), Optimal.Schema.t()) ::
          validation_result()
  defp validate_inclusion(validation_result, opts, %{allow_values: allow_values}) do
    opts
    |> Keyword.take(Keyword.keys(allow_values))
    |> Enum.reduce(validation_result, fn {key, value}, result ->
      if value in allow_values[key] do
        result
      else
        add_errors(result, {key, "must be one of #{inspect(allow_values[key])}"})
      end
    end)
  end

  @spec validate_extra_keys(validation_result(), Keyword.t(), Optimal.Schema.t()) ::
          validation_result()
  defp validate_extra_keys(validation_result, _opts, %{extra_keys?: true}),
    do: validation_result

  defp validate_extra_keys(validation_result, opts, %{opts: keys}) do
    extra_keys =
      opts
      |> Keyword.keys()
      |> Kernel.--(keys)

    Enum.reduce(
      extra_keys,
      validation_result,
      &add_errors(&2, {&1, "is not allowed (no extra keys)"})
    )
  end

  defp add_errors({:ok, _opts}, error_or_errors) do
    add_errors({:error, []}, error_or_errors)
  end

  defp add_errors({:error, existing_errors}, error_or_errors) do
    errors = List.wrap(error_or_errors)
    {:error, errors ++ existing_errors}
  end

  defp message(errors) do
    short_messages =
      errors
      |> Enum.map(&short_message/1)
      |> Enum.join(", ")

    "Opt Validation Error: " <> "#{short_messages}"
  end

  defp short_message({path, message}) when is_list(path) do
    path =
      path
      |> Enum.with_index()
      |> Enum.map(fn {elem, i} ->
        if i == 0 do
          elem
        else
          "[:#{elem}]"
        end
      end)
      |> Enum.join()

    "#{path} - #{message}"
  end

  defp short_message({field, message}) do
    "#{field} - #{message}"
  end
end
