# Optimal

[![Build Status](https://travis-ci.com/albert-io/optimal.svg?branch=master)](https://travis-ci.com/albert-io/optimal) [![Ebert](https://ebertapp.io/github/albert-io/optimal.svg)](https://ebertapp.io/github/albert-io/optimal) [![Coverage Status](https://coveralls.io/repos/github/albert-io/optimal/badge.svg?branch=master)](https://coveralls.io/github/albert-io/optimal?branch=master) [![Inline docs](http://inch-ci.org/github/albert-io/optimal.svg)](http://inch-ci.org/github/albert-io/optimal)

A schema based `opt` validator. Its verbose, but I've tried many other data validation libraries, and their succinctness came with a cost when it came to features. There are a lot of optimizations and improvements that can be made, so contributions are very welcome.

View the documentation: [https://hexdocs.pm/optimal](https://hexdocs.pm/optimal)

## Roadmap

* Better error messages, both for type mismatches and in general
* Supporting nested schemas
* Optimize. The schema based design allows schemas to be declared at compile time (for instance in module attributes) and that should be leveraged as much as possible to ensure that validating a schema does no work that could be done when building the schema.
* Macro. We could potentially provide something that can partially validate opts at compile time. For instance, any literal values or known values could be validated at compile time.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `optimal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:optimal, "~> 0.3.0"}
  ]
end
```

## Getting Started Examples

```elixir
# Allow no opts
Optimal.schema()

# Allow any opts
Optimal.schema(extra_keys?: true)

# Allow a specific set of opts
Optimal.schema(opts: [:foo, :bar, :baz])

# Allow specific types
Optimal.schema(opts: [foo: :int, bar: :string, baz: :pid])

# Require certain opts
Optimal.schema(opts, [foo: :int, bar: :string, baz: :pid], required: [:foo, :bar])

# Provide defaults for arguments (defaults will have to pass any type validation)
# If they provide they key, but a `nil` value, the default is *not* used.
Optimal.schema(opts, [foo: :int, bar: :string, baz: :boolean], defaults: [baz: true])

# Allow only specific values for certain opts
Optimal.schema(opts, [foo: {:enum, [1, 2, 3]}])

# Custom validations
# Read below for more info
def custom(field_value, field_name, all_opts, schema) do
  if is_special(field_value) do
    :ok
  else
    [{field_name, "must be special"}]
  end
end

Optimal.schema(opts, [foo: :integer, bar: :string], custom: [&custom/4])
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

## Auto Documentation

If your schemas are defined at compile time, it is possible to interpolate a generated documentation for them into your docstrings.
If you are doing this, you may also want to leverage the `describe` opt when building schemas, that lets you attach descriptions.

For example:

```elixir

@opts Optimal.schema(opts: [
    foo: [:int, :string],
    bars: {:list, :int}
  ],
  required: [:foo],
  describe: [
    foo: "The id of the foo you want",
    bars: "The ids of all of the bars you want"
  ],
  defaults: [
    bars: []
  ],
  extra_keys?: true
)

@doc """
This does a special thing.

#{Optimal.Doc.document(@opts)}

More in-depth documentation
"""
def my_special_function(opts) do

end
```

This would generate a docstring that looks like:

### Doc Example

This does a special thing.

---

## Opts

* `foo`(`[:int, :string]`) **Required**: The id of the foo you want
* `bars`(`{:list, :int}`): The ids of all of the bars you want - Default: []

Also accepts extra opts that are not named here.

---

More in-depth documentation

## Schema merging

This behavior is not set in stone, and will probably need to take a `strategy` option to support different kinds of merging opt schemas. This is very useful when working with many functions that are more specific versions of some generic action, or that all eventually call into the same function and need to accept that function's opts as well.

```elixir

schema1 = Optimal.schema(opts: [foo: :int])
schema2 = Optimal.schema(opts: [foo: :string, bar: :int])

Optimal.merge(schema1, schema2) == Optimal.schema(opts: [foo: [:int, :string], bar: :int])
```

### Merge annotations

You can provide an annotation when merging, and options will be further grouped by that annotation.

```elixir
Optimal.merge(schema1, schema2, annotate: "Shared")
```

---

* `id`(`:int`) **Required**
* `foo`(`:int`)

#### Shared

* `baz`(`:int`)
* `bar`(`:int`)

---
