defmodule Optimal.Type do
  @moduledoc """
  Exposes functions for validating types, and determining if a value matches a type.
  """

  @scalar_types [
    :any,
    :atom,
    :binary,
    :bitstring,
    :boolean,
    :float,
    :function,
    :int,
    :integer,
    :keyword,
    :list,
    :map,
    nil,
    :number,
    :pid,
    :port,
    :reference,
    :string,
    :struct,
    :tuple
  ]

  @spec validate_types(
          types :: Keyword.t(),
          field_name :: atom,
          opts :: Keyword.t(),
          schema :: Optimal.schema()
        ) :: [
          {atom, String.t()}
        ]
  def validate_types(types, field_name, _opts, _schema) do
    Enum.reduce(types, [], fn field_and_type, errors ->
      type =
        case field_and_type do
          {_field, type} -> type
          _ -> :any
        end

      if valid_type?(type) do
        errors
      else
        [{field_name, "No such Optimal type: #{inspect(type)}"}]
      end
    end)
  end

  @spec matches_type?(type :: term, value :: term) :: boolean
  def matches_type?(types, value) when is_list(types),
    do: Enum.any?(types, &matches_type?(&1, value))

  def matches_type?(:any, _), do: true

  def matches_type?({:keyword, value_type}, value) do
    matches_type?(:keyword, value) and
      Enum.all?(value, fn {_k, v} -> matches_type?(value_type, v) end)
  end

  def matches_type?({:list, type}, value) do
    matches_type?(:list, value) and Enum.all?(value, &matches_type?(type, &1))
  end

  def matches_type?({:function, arity}, value) when is_function(value, arity), do: true
  def matches_type?({:function, _}, _), do: false
  def matches_type?({:struct, struct}, %struct{}), do: true
  def matches_type?({:struct, _}, _), do: false
  def matches_type?(%struct{}, %struct{}), do: true
  def matches_type?(%_{}, _), do: false
  def matches_type?({:enum, list}, value), do: value in list
  # Below this line is only scalar types. Do not move things below/above this line.
  def matches_type?(type, _) when type not in @scalar_types,
    do: raise("Unreachable: no type #{inspect(type)}")

  def matches_type?(:int, value) when is_integer(value), do: true
  def matches_type?(:integer, value) when is_integer(value), do: true
  def matches_type?(:bitstring, value) when is_bitstring(value), do: true
  def matches_type?(:string, value) when is_binary(value), do: true
  def matches_type?(:binary, value) when is_binary(value), do: true
  def matches_type?(:float, value) when is_float(value), do: true
  def matches_type?(:keyword, value), do: Keyword.keyword?(value)
  def matches_type?(:list, value) when is_list(value), do: true
  def matches_type?(:boolean, value) when is_boolean(value), do: true
  def matches_type?(:atom, value) when is_atom(value), do: true
  def matches_type?(nil, nil), do: true
  def matches_type?(:function, value) when is_function(value), do: true
  def matches_type?(:map, value) when is_map(value), do: true
  def matches_type?(:number, value) when is_number(value), do: true
  def matches_type?(:pid, value) when is_pid(value), do: true
  def matches_type?(:port, value) when is_port(value), do: true
  def matches_type?(:reference, value) when is_reference(value), do: true
  def matches_type?(:tuple, value) when is_tuple(value), do: true
  def matches_type?(:struct, %_{}), do: true
  def matches_type?(_, _), do: false

  @spec valid_type?(term) :: boolean
  def valid_type?(:any), do: true
  def valid_type?(types) when is_list(types), do: Enum.all?(types, &valid_type?/1)
  def valid_type?({:function, i}) when is_integer(i) and i >= 0, do: true
  def valid_type?({:keyword, type}), do: valid_type?(type)
  def valid_type?({:list, type}), do: valid_type?(type)
  def valid_type?({:struct, module}) when is_atom(module), do: true
  def valid_type?({:enum, values}) when is_list(values), do: true
  def valid_type?(%_{}), do: true
  def valid_type?(type) when type in @scalar_types, do: true
  def valid_type?(_), do: false

  # There may be missing cases here.
  @spec merge(left :: term, right :: term) :: term
  def merge(same, same), do: same
  def merge({:enum, left}, {:enum, right}), do: {:enum, left ++ right}
  def merge(left, right), do: [left, right]
end
