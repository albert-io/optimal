defmodule TypeTest do
  use ExUnit.Case

  import Optimal, only: [schema: 1, validate!: 2]

  defmacrop error!(opts, schema, message) do
    quote do
      assert_raise ArgumentError, unquote(message), fn ->
        validate!(unquote(opts), unquote(schema))
      end
    end
  end

  defmodule TestStruct do
    defstruct [:foo]
  end

  defmodule TestStruct2 do
    defstruct [:foo]
  end

  test "that type validation does not fail non-present non-required opts" do
    schema = schema(opts: [foo: :int])
    opts = []

    validate!(opts, schema)
  end

  test "that strings cannot be provided for integers" do
    schema = schema(opts: [foo: :int])
    opts = [foo: "1"]
    message = "Opt Validation Error: foo - must be of type :int"

    error!(opts, schema, message)
  end

  test "that int and integer can be provided for integers" do
    schema = schema(opts: [foo: :int, bar: :integer])
    opts = [foo: 1, bar: 2]

    validate!(opts, schema)
  end

  test "that integers cannot be provided for strings" do
    schema = schema(opts: [foo: :string])
    opts = [foo: 1]
    message = "Opt Validation Error: foo - must be of type :string"

    error!(opts, schema, message)
  end

  test "that string, bitstring and binary can be provided for strings" do
    schema = schema(opts: [foo: :string, bar: :bitstring, buz: :binary])
    opts = [foo: "foo", bar: "biz", buz: "blart"]

    validate!(opts, schema)
  end

  test "that integers cannot be provided for floats" do
    schema = schema(opts: [foo: :float])
    opts = [foo: 1]

    message = "Opt Validation Error: foo - must be of type :float"

    error!(opts, schema, message)
  end

  test "that a regular list cannot be provided for a keyword" do
    schema = schema(opts: [foo: :keyword])
    opts = [foo: [1]]

    message = "Opt Validation Error: foo - must be of type :keyword"

    error!(opts, schema, message)
  end

  test "that a keyword list fails on invalid value types" do
    schema = schema(opts: [foo: {:keyword, :integer}])
    opts = [foo: [bar: "none"]]

    message = "Opt Validation Error: foo - must be of type {:keyword, :integer}"

    error!(opts, schema, message)
  end

  test "that a scalar value cannot be used for a list" do
    schema = schema(opts: [foo: :list])
    opts = [foo: 1]

    message = "Opt Validation Error: foo - must be of type :list"

    error!(opts, schema, message)
  end

  test "that an integer cannot be used for a boolean value" do
    schema = schema(opts: [foo: :boolean])
    opts = [foo: 10]

    message = "Opt Validation Error: foo - must be of type :boolean"

    error!(opts, schema, message)
  end

  test "that a boolean validates properly" do
    schema = schema(opts: [foo: :boolean])
    opts = [foo: true]

    validate!(opts, schema)
  end

  test "that a string cant be used for an atom" do
    schema = schema(opts: [foo: :atom])
    opts = [foo: "hello"]

    message = "Opt Validation Error: foo - must be of type :atom"

    error!(opts, schema, message)
  end

  test "that list fails on invalid member types" do
    schema = schema(opts: [foo: {:list, :atom}])
    opts = [foo: ["hello"]]

    message = "Opt Validation Error: foo - must be of type {:list, :atom}"

    error!(opts, schema, message)
  end

  test "that a string cannot be used for a function" do
    schema = schema(opts: [foo: :function])
    opts = [foo: "hello"]

    message = "Opt Validation Error: foo - must be of type :function"

    error!(opts, schema, message)
  end

  test "that a function of the incorrect arity cannot be used when arity is specified" do
    schema = schema(opts: [foo: {:function, 2}])
    opts = [foo: fn i -> i * i end]

    message = "Opt Validation Error: foo - must be of type {:function, 2}"

    error!(opts, schema, message)
  end

  test "that a map cannot be provided for a struct" do
    schema = schema(opts: [foo: :struct])
    opts = [foo: %{}]

    message = "Opt Validation Error: foo - must be of type :struct"

    error!(opts, schema, message)
  end

  test "that the incorrect struct cannot be used when struct is specified" do
    schema = schema(opts: [foo: {:struct, TestStruct}])
    opts = [foo: %TestStruct2{}]

    message = "Opt Validation Error: foo - must be of type {:struct, TypeTest.TestStruct}"

    error!(opts, schema, message)
  end

  test "that a struct can be specified by just passing an instance of it" do
    schema = schema(opts: [foo: %TestStruct{}])
    opts = [foo: %TestStruct2{}]

    message = "Opt Validation Error: foo - must be of type {:struct, TypeTest.TestStruct}"

    error!(opts, schema, message)
  end

  test "that a schema fails at schema generation time with an unknown type" do
    assert_raise ArgumentError, "Opt Validation Error: opts - No such Optimal type: :foo", fn ->
      schema(opts: [foo: :foo])
    end
  end

  test "that a list provided as a type allows for any of the types to pass" do
    schema = schema(opts: [foo: [:integer, :string]])
    opts1 = [foo: "hello"]
    opts2 = [foo: 1]

    validate!(opts1, schema)
    validate!(opts2, schema)
  end

  test "that an empty nested schema does not error" do
    nested_schema = schema(opts: [])
    schema = schema(opts: [foo: nested_schema])

    opts = [foo: []]

    validate!(opts, schema)
  end

  test "that a valid nested schema transforms itself appropriately" do
    nested_schema = schema(opts: [bar: :integer], defaults: [bar: 1])
    schema = schema(opts: [foo: nested_schema])

    opts = [foo: []]

    result = validate!(opts, schema)

    assert(result[:foo] == [bar: 1])
  end

  test "that an invalid nested schema surfaces any errors" do
    nested_schema = schema(opts: [bar: :integer], required: [:bar])
    schema = schema(opts: [foo: nested_schema])

    opts = [foo: []]

    assert_raise ArgumentError,
                 "Opt Validation Error: foo - nested field bar is required",
                 fn ->
                   validate!(opts, schema)
                 end
  end

  test "that a valid list of keywords aligning to a schema may be used" do
    nested_schema = schema(opts: [bar: :integer], defaults: [bar: 1])

    schema = schema(opts: [foo: {:list, nested_schema}])

    opts = [foo: [[bar: 2], []]]

    result = validate!(opts, schema)

    assert(result[:foo] == [[bar: 2], [bar: 1]])
  end

  test "that a valid keyword list with schemas as values may be used" do
    nested_schema = schema(opts: [bar: :integer], defaults: [bar: 1])

    schema = schema(opts: [foo: {:keyword, nested_schema}])

    opts = [foo: [thing: [bar: 2], other_thing: []]]

    result = validate!(opts, schema)

    assert(result[:foo] == [thing: [bar: 2], other_thing: [bar: 1]])
  end

  test "that an error in a list of schemas is surfaced with the index" do
    nested_schema = schema(opts: [bar: :integer], required: [:bar])
    schema = schema(opts: [foo: {:list, nested_schema}])

    opts = [foo: [[]]]

    assert_raise ArgumentError,
                 "Opt Validation Error: foo - nested field [0][bar] is required",
                 fn ->
                   validate!(opts, schema)
                 end
  end

  test "that an error in a keyword list of schemas is surfaced with the key" do
    nested_schema = schema(opts: [bar: :integer], required: [:bar])
    schema = schema(opts: [foo: {:keyword, nested_schema}])

    opts = [foo: [foo: []]]

    assert_raise ArgumentError,
                 "Opt Validation Error: foo - nested field [foo][bar] is required",
                 fn ->
                   validate!(opts, schema)
                 end
  end
end
