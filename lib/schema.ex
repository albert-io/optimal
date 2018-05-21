defmodule Optimal.Schema do
  defstruct opts: [],
            defaults: [],
            required: [],
            additional_keys?: false,
            allow_values: [],
            types: [],
            custom: []

  @type t :: %__MODULE__{
          opts: [atom | {atom, term}],
          defaults: Keyword.t(),
          required: [],
          additional_keys?: boolean,
          allow_values: Keyword.t(),
          types: Keyword.t(),
          custom: Keyword.t()
        }

  @spec new() :: t()
  def new() do
    new(opts: [])
  end

  @spec new(Keyword.t() | t()) :: t() | no_return
  def new(schema = %__MODULE__{}), do: schema
  def new([]), do: new(opts: [])

  def new(opts) do
    opts = Optimal.validate!(opts, schema_schema())

    %__MODULE__{
      opts: opt_keys(opts[:opts]),
      types: to_keyword(opts[:opts]),
      defaults: opts[:defaults],
      additional_keys?: opts[:additional_keys?],
      allow_values: opts[:allow_values],
      required: opts[:required],
      custom: opts[:custom]
    }
  end

  @spec opt_keys([atom | {atom, term}]) :: atom
  defp opt_keys(opts) do
    Enum.map(opts, fn
      {opt, _} -> opt
      opt -> opt
    end)
  end

  @spec to_keyword([atom | {atom, term}]) :: Keyword.t()
  defp to_keyword(opts) do
    Enum.map(opts, fn
      {opt, value} -> {opt, value}
      opt -> {opt, :any}
    end)
  end

  @spec merge(t(), t()) :: t()
  def merge(left, right) do
    %__MODULE__{
      opts: Enum.uniq(left.opts ++ right.opts),
      defaults: Keyword.merge(left.defaults, right.defaults),
      additional_keys?: right.additional_keys?,
      allow_values:
        Keyword.merge(left.allow_values, right.allow_values, fn _, v1, v2 -> v1 ++ v2 end),
      # TODO: Smarter type merge
      types: Keyword.merge(left.types, right.types)
    }
  end

  @spec schema_schema() :: t()
  defp schema_schema() do
    %__MODULE__{
      opts: [
        :opts,
        :required,
        :defaults,
        :additional_keys?,
        :allow_values,
        :custom
      ],
      types: [
        opts: [{:list, :atom}, :keyword],
        required: {:list, :atom},
        defaults: :keyword,
        additional_keys?: :boolean,
        allow_values: {:keyword, :list},
        custom: :keyword
      ],
      defaults: [
        required: [],
        defaults: [],
        additional_keys?: false,
        allow_values: [],
        custom: []
      ],
      additional_keys?: false,
      allow_values: [],
      custom: [
        opts: &Optimal.Type.validate_types/4
      ]
    }
  end
end
