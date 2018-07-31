defmodule Optimal do
  @moduledoc """
  Documentation for Optimal.
  """

  @type schema() :: Optimal.Schema.t()
  @type error :: {atom, String.t()}
  @type validation_result :: {:ok, Keyword.t()} | {:error, [error]}

  @doc "See `Optimal.Schema.new/1`"
  defdelegate schema(opts), to: Optimal.Schema, as: :new
  defdelegate schema(), to: Optimal.Schema, as: :new

  @doc "See `Optimal.Schema.merge/2`"
  defdelegate merge(left, right), to: Optimal.Schema
  defdelegate merge(left, right, opts), to: Optimal.Schema

  @doc "See `Optimal.Doc.document/2`"
  defdelegate document(schema, opts), to: Optimal.Doc
  defdelegate document(schema), to: Optimal.Doc

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
  @spec validate!(opts :: Keyword.t(), schema :: schema()) :: Keyword.t() | no_return
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
    |> validate_types(with_defaults, schema)
    |> validate_extra_keys(with_defaults, schema)
    |> validate_custom(schema)
  end

  def validate(_opts, _schema) do
    {:error, [{:opts, "opts must be a keyword list or a map."}]}
  end

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

  defp validate_types(validation_result, opts, %{types: types}) do
    Enum.reduce(types, validation_result, fn {field, type}, result ->
      cond do
        !Keyword.has_key?(opts, field) ->
          result

        match?(%Optimal.Schema{}, type) ||
            match?({nested_type, %Optimal.Schema{}} when nested_type in [:keyword, :list], type) ->
          validate_nested_schema(result, type, opts, field)

        Optimal.Type.matches_type?(type, opts[field]) ->
          result

        true ->
          message = "must be of type " <> sanitize_type(type)
          add_errors(result, {field, message})
      end
    end)
  end

  defp validate_nested_schema(result, type, opts, field) do
    case do_nested_schema_validation(type, opts[field]) do
      {:ok, value} ->
        update_result_key(result, field, value)

      {:error, message} ->
        add_errors(result, {field, message})
    end
  end

  defp do_nested_schema_validation({:list, _schema}, value)
       when not is_list(value) do
    {:error, "expected a list of keywords conforming to a subschema"}
  end

  defp do_nested_schema_validation({:list, schema}, value) do
    nested_opts_result =
      value
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {keyword, index}, {opts_acc, errors_acc} ->
        case validate(keyword, schema) do
          {:ok, new_opts} ->
            {[new_opts | opts_acc], errors_acc}

          {:error, errors} ->
            message = nested_error_message(index, errors)

            {opts_acc, [message | errors_acc]}
        end
      end)

    case nested_opts_result do
      {opts_acc, []} ->
        {:ok, Enum.reverse(opts_acc)}

      {_, errors} ->
        message = Enum.join(errors, ", ")
        {:error, message}
    end
  end

  defp do_nested_schema_validation({:keyword, schema}, value) do
    nested_opts_result =
      value
      |> Enum.reduce({[], []}, fn {key, keyword}, {opts_acc, errors_acc} ->
        case validate(keyword, schema) do
          {:ok, new_opts} ->
            {[{key, new_opts} | opts_acc], errors_acc}

          {:error, errors} ->
            message = nested_error_message(key, errors)

            {opts_acc, [message | errors_acc]}
        end
      end)

    case nested_opts_result do
      {opts_acc, []} ->
        {:ok, Enum.reverse(opts_acc)}

      {_, errors} ->
        message = Enum.join(errors, ", ")
        {:error, message}
    end
  end

  defp do_nested_schema_validation(schema = %Optimal.Schema{}, value) do
    case validate(value, schema) do
      {:ok, new_opts} ->
        {:ok, new_opts}

      {:error, errors} ->
        message =
          Enum.map_join(errors, ", ", fn {nested_field, message} ->
            "nested field #{nested_field} #{message}"
          end)

        {:error, message}
    end
  end

  defp nested_error_message(nesting, errors) do
    Enum.map_join(errors, ", ", fn {nested_field, message} ->
      "nested field [#{nesting}][#{nested_field}] #{message}"
    end)
  end

  defp sanitize_type(%struct{}), do: sanitize_type({:struct, struct})
  defp sanitize_type(term), do: inspect(term)

  defp validate_required(validation_result, opts, %{required: required}) do
    Enum.reduce(required, validation_result, fn key, result ->
      if is_nil(opts[key]) do
        add_errors(result, {key, "is required"})
      else
        result
      end
    end)
  end

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

  defp update_result_key({:ok, opts}, field, value) do
    {:ok, Keyword.put(opts, field, value)}
  end

  defp update_result_key(other, _, _) do
    other
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
