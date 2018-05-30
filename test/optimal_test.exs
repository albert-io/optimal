defmodule OptimalTest do
  use ExUnit.Case
  doctest Optimal

  import Optimal, only: [schema: 1, schema: 0, validate!: 2, merge: 3]

  defmacrop error!(opts, schema, message) do
    quote do
      assert_raise ArgumentError, unquote(message), fn ->
        validate!(unquote(opts), unquote(schema))
      end
    end
  end

  defp simple_equals_1(value, _field_name, _opts, _schema) do
    value == 1
  end

  defp two_to_one(value, field_name, opts, _schema) do
    if value == 2 do
      {:ok, Keyword.put(opts, field_name, 1)}
    else
      :ok
    end
  end

  defp message_equals_1(value, field_name, _opts, _schema) do
    if value == 1 do
      :ok
    else
      [{field_name, "really should have equaled 1!!!"}]
    end
  end

  test "an empty schema succeeds with no opts" do
    schema = schema()
    opts = []

    validate!(opts, schema)
  end

  test "an empty schema fails when an opt is provided, as no extra keys are allowed" do
    schema = schema()
    opts = [foo: 1]

    message = "Opt Validation Error: foo - is not allowed (no extra keys)"

    error!(opts, schema, message)
  end

  test "no extra keys displays errors for all extra keys" do
    schema = schema()
    opts = [foo: 1, bar: 2, baz: 3]

    message =
      "Opt Validation Error: baz - is not allowed (no extra keys)" <>
        ", bar - is not allowed (no extra keys)" <> ", foo - is not allowed (no extra keys)"

    error!(opts, schema, message)
  end

  test "an allowed opt does not raise errors" do
    schema = schema(opts: [:foo, :bar])
    opts = [foo: 1]

    validate!(opts, schema)
  end

  test "a present required opt does not raise errors" do
    schema = schema(opts: [:foo, :bar], required: [:foo])
    opts = [foo: 1]

    validate!(opts, schema)
  end

  test "raises if opts are not a keyword list or map" do
    schema = schema()
    opts = 10

    message = "Opt Validation Error: opts - opts must be a keyword list or a map."
    error!(opts, schema, message)
  end

  test "a custom check does not raise errors on success" do
    schema = schema(opts: [:foo], custom: [foo: &simple_equals_1/4])
    opts = [foo: 1]

    validate!(opts, schema)
  end

  test "a custom check raises the default error message on failure if none is provided" do
    schema = schema(opts: [:foo], custom: [foo: &simple_equals_1/4])
    opts = [foo: 2]

    message = "Opt Validation Error: foo - failed a custom validation"

    error!(opts, schema, message)
  end

  test "a custom check can return its own error" do
    schema = schema(opts: [:foo], custom: [foo: &message_equals_1/4])
    opts = [foo: 2]

    message = "Opt Validation Error: foo - really should have equaled 1!!!"

    error!(opts, schema, message)
  end

  test "a custom check can also modify the opts" do
    schema = schema(opts: [:foo], custom: [foo: &two_to_one/4])
    opts = [foo: 2]

    new_opts = validate!(opts, schema)

    assert(new_opts[:foo] == 1)
  end

  test "a merge that doesn't add required fields only has required fields from the left" do
    left = schema(opts: [:foo], required: [:foo])
    right = schema(opts: [:bar], required: [:bar])

    schema = merge(left, right, add_required?: false)

    assert(schema.required == [:foo])
  end
end
