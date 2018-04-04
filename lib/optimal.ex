defmodule Optimal do
  @moduledoc """
  Documentation for Optimal.
  """

  @type vex_error :: {:error, atom, atom, String.t()}
  @type validation_result :: {:ok, Keyword.t()} | {:error, [vex_error]}

  @doc """
  Validates opts according to a schema or the constructor for a schema. Raises on invalid opts.

      iex> Optimal.validate!([reticulate_splines?: true], allowed: [:reticulate_splines?])
      [reticulate_splines?: true]
      iex> Optimal.validate!([reticulate_splines?: true], allowed: [:load_textures?], additional_keys?: true)
      [reticulate_splines?: true]
      iex> schema = Optimal.schema(allowed: [:reticulate_splines?], required: [:reticulate_splines?], additional_keys?: true)
      ...> Optimal.validate!([reticulate_splines?: true, hack_interwebs?: true], schema)
      [reticulate_splines?: true, hack_interwebs?: true]
      iex> Optimal.validate!([], allowed: [:reticulate_splines?], required: [:reticulate_splines?])
      ** (ArgumentError) Opt Validation Error: reticulate_splines? - must be present
  """
  @spec validate!(opts :: Keyword.t(), schema :: Optimal.Schema.t() | Keyword.t()) :: Keyword.t() | no_return
  def validate!(opts, schema = %Optimal.Schema{}) do
    case validate(opts, schema) do
      {:ok, opts} -> opts
      {:error, errors} ->
        message = message(errors)
        raise ArgumentError, message
    end
  end
  def validate!(opts, schema_config) do
    validate!(opts, schema(schema_config))
  end

  @spec validate(opts :: Keyword.t(), schema :: Optimal.Schema.t()) :: {:ok, Keyword.t()} | {:error, [vex_error]}
  def validate(opts, _schema) when not(is_list(opts)) do
    {:error, [{:error, :opts, :opts, "opts must be a keyword list."}]}
  end
  def validate(opts, schema) do
    with_defaults =
      Enum.reduce(schema.defaults, opts, fn {default, value}, opts ->
        Keyword.put_new(opts, default, value)
      end)

    with_defaults
    |> Vex.validate(schema.vex)
    |> validate_additional_keys(opts, schema)
    |> validate_nested_schemas(opts, schema)
  end

  @spec schema(Keyword.t()) :: Optimal.Schema.t()
  def schema(opts) do
    Optimal.Schema.new(opts)
  end

  @spec validate_additional_keys(validation_result(), Keyword.t(), Optimal.Schema.t()) :: validation_result()
  defp validate_additional_keys(validation_result, _opts, %{additional_keys?: true}), do: validation_result
  defp validate_additional_keys(validation_result, opts, %{vex: vex}) do
    extra_keys =
      opts
      |> Keyword.keys()
      |> Kernel.--(Keyword.keys(vex))

    Enum.reduce(extra_keys, validation_result, &add_not_allowed_error/2)
  end

  @spec validate_nested_schemas(validation_result(), Keyword.t(), Optimal.Schema.t()) :: validation_result()
  defp validate_nested_schemas(validation_result, opts, %{nested_schemas: nested_schemas}) do
    nested_schemas
    |> Enum.reduce({validation_result, opts}, &validate_nested_schema/2)
    |> elem(0)
  end

  @spec validate_nested_schema({atom, Optimal.Schema.t()}, {validation_result(), Keyword.t()}) :: {validation_result(), Keyword.t()}
  defp validate_nested_schema({key, schema}, {result, opts}) do
    case validate(opts[key], schema) do
      {:ok, valid_opts} ->
        case result do
          {:ok, _} ->
            with_nested_validation = Keyword.put(opts, key, valid_opts)
            {{:ok, with_nested_validation}, with_nested_validation}
          _ ->
            {result, opts}
        end
      {:error, errors} ->
        errors = Enum.map(errors, fn {:error, field, name, message} -> {:error, schema.nesting_path ++ [field], name, message} end)
        {add_errors(result, errors), opts}
    end
  end

  @spec add_not_allowed_error(atom, validation_result()) :: {:error, [vex_error]}
  defp add_not_allowed_error(field, result) do
    add_errors(result, {:error, field, :presence, "is not allowed (no extra fields)"})
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

  defp short_message({_, path, _, message}) when is_list(path) do
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
  defp short_message({_, field, _, message}) do
    "#{field} - #{message}"
  end
end
