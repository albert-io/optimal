defmodule Optimal.Schema do
  defstruct [vex: [], defaults: [], nested_schemas: [], additional_keys?: false, nesting_path: [], allow_values: []]

  @type t :: %__MODULE__{
    vex: Keyword.t(),
    defaults: Keyword.t(),
    additional_keys?: boolean,
    nested_schemas: Keyword.t(),
    nesting_path: [atom],
    allow_values: Keyword.t()
  }

  @spec new() :: t()
  def new() do
    new(allowed: [])
  end

  @spec new(Keyword.t() | t()) :: t() | no_return
  def new(schema = %__MODULE__{}), do: schema
  def new([]), do: new(allowed: [])
  def new(opts) do
    opts =
      opts
      |> reduce_over(opts[:nested_schemas] || [], fn {key, nested}, opts ->
        Keyword.update!(opts, :nested_schemas, fn nested_schemas ->
          current_path = opts[:nesting_path] || []
          nested_schema =
            nested
            |> new()
            |> Map.put(:nesting_path, current_path ++ [key])

          Keyword.put(nested_schemas, key, nested_schema)
        end)
      end)
      |> Optimal.validate!(schema_schema())

    vex =
      []
      |> reduce_over(opts[:allowed], fn opt, vex ->
        Keyword.put(vex, opt, [])
      end)
      |> reduce_over(opts[:required], fn opt, vex ->
        Keyword.update!(vex, opt, &Keyword.put(&1, :presence, true))
      end)
      |> reduce_over(opts[:allow_values], fn {opt, values}, vex ->
        Keyword.update!(vex, opt, &Keyword.put(&1, :inclusion, values))
      end)

    %__MODULE__{
      defaults: opts[:defaults],
      vex: vex,
      additional_keys?: opts[:additional_keys?],
      nested_schemas: opts[:nested_schemas],
      nesting_path: opts[:nesting_path],
      allow_values: opts[:allow_values]
    }
  end

  @spec merge(t(), t()) :: t()
  def merge(left, right) do
    %__MODULE__{
      vex: Keyword.merge(left.vex, right.vex, fn _, v1, v2 -> Keyword.merge(v1, v2) end),
      defaults: Keyword.merge(left.defaults, right.defaults),
      additional_keys?: right.additional_keys?,
      nested_schemas: Keyword.merge(left.nested_schemas, right.nested_schemas),
      nesting_path: [],
      allow_values: Keyword.merge(left.allow_values, right.allow_values, fn _, v1, v2 -> v1 ++ v2 end)
    }
  end

  @spec reduce_over(acc, list(value), ((value, acc) -> acc)) :: acc when acc: term, value: term
  defp reduce_over(schema, list, fun) do
    Enum.reduce(list, schema, fun)
  end

  @spec schema_schema() :: t()
  defp schema_schema() do
    %__MODULE__{
      vex: [
        allowed: [],
        required: [],
        defaults: [],
        nested_schemas: [],
        nesting_path: [],
        additional_keys?: [inclusion: [true, false]],
        allow_values: []
      ],
      defaults: [required: [], defaults: [], additional_keys?: false, nested_schemas: [], nesting_path: [], allow_values: []],
      additional_keys?: false,
      nested_schemas: [],
      nesting_path: [],
      allow_values: []
    }
  end
end
