defmodule Optimal.Schema do
  @moduledoc """
  Functions for generating and validating the opts that generate a schema.
  """

  defstruct opts: [],
            defaults: [],
            describe: [],
            required: [],
            extra_keys?: false,
            types: [],
            custom: [],
            annotations: []

  @type t :: %__MODULE__{
          opts: [atom],
          defaults: Keyword.t(),
          describe: Keyword.t(),
          required: [atom],
          extra_keys?: boolean,
          types: Keyword.t(),
          custom: Keyword.t(),
          annotations: Keyword.t()
        }

  # These opts cannot be auto-documented, so must be regenerated manually
  @doc """
  Create a new schema.

  ---
  ## Opts

  * `opts`(`[{:list, :atom}, :keyword]`): A list of opts accepted, or a keyword of opt name to opt type - Default: []
  * `required`(`{:list, :atom}`): A list of required opts (all of which must be in `opts` as well) - Default: []
  * `defaults`(`:keyword`): A keyword list of option name to a default value. Values must pass type rules - Default: []
  * `extra_keys?`(`:boolean`): If enabled, extra keys not specified by the schema do not fail validation - Default: false
  * `custom`(`:keyword`): A keyword list of option name (for errors) and custom validations. See README - Default: []
  * `describe`(`:keyword`): A keyword list of option names to short descriptions (like these) - Default: []

  ---

  A custom validation is run on the types provided at schema creation time, to ensure they are all valid types.
  """
  @spec new() :: t()
  def new() do
    new(opts: [])
  end

  @spec new(opts :: Keyword.t()) :: t() | no_return
  def new([]), do: new(opts: [])

  def new(opts) do
    opts = Optimal.validate!(opts, Optimal.SchemaHelpers.schema_schema())

    %__MODULE__{
      opts: opt_keys(opts[:opts]),
      types: to_keyword(opts[:opts]),
      defaults: opts[:defaults],
      describe: opts[:describe],
      extra_keys?: opts[:extra_keys?],
      required: opts[:required],
      custom: opts[:custom],
      annotations: []
    }
  end

  # These opts cannot be auto-documented, so must be regenerated manually
  @doc """
  Merges two optimal schemas to create a superset schema.

  ---
  ## Opts

  * `annotate`(`:string`): Annotates the source of the opt, to be used in displaying documentation.

  ---
  """
  @spec merge(left :: t(), right :: t(), opts :: Keyword.t()) :: t()
  def merge(left, right, opts \\ []) do
    opts = Optimal.validate!(opts, Optimal.SchemaHelpers.merge_schema())

    %__MODULE__{
      opts: Enum.uniq(left.opts ++ right.opts),
      defaults: Keyword.merge(left.defaults, right.defaults),
      extra_keys?: right.extra_keys? || left.extra_keys?,
      describe:
        Keyword.merge(left.describe, right.describe, fn _, v1, v2 -> v1 <> " | " <> v2 end),
      types: merge_types(left.types, right.types),
      custom: left.custom ++ right.custom,
      required: Enum.uniq(left.required ++ right.required),
      annotations: merge_annotations(left, right, opts[:annotate])
    }
  end

  defp opt_keys(opts) do
    Enum.map(opts, fn
      {opt, _} -> opt
      opt -> opt
    end)
  end

  defp to_keyword(opts) do
    Enum.map(opts, fn
      {opt, value} -> {opt, value}
      opt -> {opt, :any}
    end)
  end

  defp merge_types(left, right) do
    Keyword.merge(left, right, fn _, v1, v2 -> Optimal.Type.merge(v1, v2) end)
  end

  defp merge_annotations(left, right, annotation) when is_bitstring(annotation) do
    base_annotations = Keyword.merge(left.annotations, right.annotations)

    right.opts
    |> Enum.map(&{&1, annotation})
    |> Keyword.merge(base_annotations)
  end

  defp merge_annotations(left, right, nil) do
    Keyword.merge(left.annotations, right.annotations)
  end
end
