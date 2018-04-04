defmodule OptimalTest do
  use ExUnit.Case
  doctest Optimal

  test "nested schemas are validated appropriately" do
    nested_schema = Optimal.schema(allowed: [:a, :b], required: [:a], allow_values: [a: [1, 2, 3]])
    schema = Optimal.schema(allowed: [:foos, :bar], nested_schemas: [foos: nested_schema])

    assert_raise(ArgumentError, ~r/foos\[:a\] - must be present/, fn ->
      Optimal.validate!([foos: [b: 1], bar: :none], schema)
    end)
  end
end
