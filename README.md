# Optimal

A schema based `opt` validator. Its verbose, but I've tried many other data validation libraries, and their succinctness came with a cost when it came to features. There are a lot of optimizations and improvements that can be made, so contributions are very welcome.

View the documentation: [https://hexdocs.pm/optimal](https://hexdocs.pm/optimal)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `optimal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:optimal, "~> 0.2.0"}
  ]
end
```

## Examples

```elixir
# Allow no opts
Schema.schema()

# Allow any opts
Schema.schema(extra_keys?: true)

# Allow a specific set of opts
Schema.schema(opts: [:foo, :bar, :baz])

# Allow specific types
Schema.schema(opts: [foo: :int, bar: :string, baz: :pid])

# Require certain opts
Schema.schema(opts, [foo: :int, bar: :string, baz: :pid], required: [:foo, :bar])

# Provide defaults for arguments (defaults will have to pass any type validation)
# If they provide they key, but a `nil` value, the default is *not* used.
Schema.schema(opts, [foo: :int, bar: :string, baz: :boolean], defaults: [baz: true])

# Allow only specific values for certain opts
Schema.schema(opts, [foo: :int], allow_values: [foo: [1, 2, 3]])
# Or as an enum type
Schema.schema(opts, [foo: {:enum, [1, 2, 3]}])

# Custom validations
# Read below for more info
def custom(field_value, field_name, all_opts, schema) do
  if is_special(field_value) do
    :ok
  else
    [{field_name, "must be special"}]
  end
end

Schema.schema(opts, [foo: :integer, bar: :string], custom: [&custom/4])
```

## Types
### Scalar Types

* :any
* :atom
* :binary
* :bitstring
* :boolean
* :float
* :function
* :int
* :integer
* :keyword
* :list
* :string
* :map
* :nil
* :number
* :pid
* :port
* :reference
* :tuple
* :struct

### Composite/Complex Types

* `{:keyword, value_type}` - Keyword where all values are of type `value_type`
* `{:list, type}` - List where all values are of type `value_type`
* `{:function, arity}` - A function with the arity given by `arity`
* `{:struct, Some.Struct`} - An instance of `Some.Struct`
* `%Some.Struct{}` - Same as `{:struct, Some.Struct}`
* `{:enum, [value1, value2]}` - Allows any value in the list.

## Custom Validations

Custom validations have the ability to add arbitrary errors, and additionally they can modify the `opts` as they pass through. They are run in order, and unlike all built in validations, they are only run on valid opts.

### Examples

```elixir
# Simple (returning booleans)
def is_ten(field_value, _, _, _) do
  field_value == 10
end

# Custom errors (ok/error tuples)
def is_ten(field_value, field, _, _) do
  if field_value == 10 do
    :ok
  else
    {:error, {field, "should really have equaled ten"}}
  end
end

# Returning a list of errors
def greater_than_1_and_even(field_value, field, _, _) do
  errors =
    if field_value > 1 do
      []
    else
      [{field, "should be greater than 1}]
    end

  if Integer.is_even(field_value) do
    errors
  else
    [{field, "should be even} | errors]
  end
end
```
