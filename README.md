# Optimal

Optimal is a schema based `opt` validator. It is verbose, but I've tried many other data validation libraries, and their succinctness came with a cost when it came to features. There are still a lot of optimizations and improvements that can be made, so contributions are very welcome.

This `opt` validator has a bit of a niche. It fits in just fine with validating any keyword list, but its especially useful for validating compile-time options, like ones provided to functions in a DSL.

View the documentation: [https://hexdocs.pm/optimal](https://hexdocs.pm/optimal)

## Roadmap

* Better error messages, both for type mismatches and in general
* Optimize. The schema based design allows schemas to be declared at compile time (for instance in module attributes) and that should be leveraged as much as possible to ensure that validating a schema does no work that could be done when building the schema.
* Macro. We could potentially provide something that can partially validate opts at compile time. For instance, any literal values or known values could be validated at compile time.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `optimal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:optimal, "~> 0.3.7"}
  ]
end
```

## Getting Started 

### Validation Examples

To use Optimal, you define your validation rules as an Optimal schema and then validate input against it using the `Optimal.validate/2` or `Optimal.validate!/2` functions.
 
Validate a keyword list:
```elixir
iex> schema = Optimal.schema(opts: [:foo, :bar, :baz])
iex> my_list = [{:foo, "foo val"}, {:bar, "bar val"}, {:baz, "bazz val"}]
iex> Optimal.validate(my_list, schema)
{:ok, [foo: "foo val", bar: "bar val", baz: "bazz val"]}
```

Or validate a map:

```elixir
iex> my_map = %{foo: "foo val", bar: "bar val", baz: "bazz val"}
%{bar: "bar val", baz: "bazz val", foo: "foo val"}
iex> Optimal.validate(my_map, schema)
{:ok, [bar: "bar val", baz: "bazz val", foo: "foo val"]}
```

Notice that in both cases, a keyword list is returned.

Use `Optimal.validate!/2` to return an error instead of a tuple:
```elixir
iex> bad_map = %{d: "not allowed"}
%{other: "stuff"}
iex> schema = Optimal.schema(opts: [:a, :b, :c])
iex> Optimal.validate!(bad_map, schema)
** (ArgumentError) Opt Validation Error: other - is not allowed (no extra keys)
    (optimal) lib/optimal.ex:44: Optimal.validate!/2
```

You can require that your inputs be of a certain type:

```elixir
iex> schema = Optimal.schema(opts: [age: :int, name: :string])
iex> my_data = [{:age, 12}, {:name, false}]
iex> Optimal.validate(my_data, schema)
{:error, [name: "must be of type :string"]}
```

### Schema Examples

Define your validation rules in your schema.

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
Optimal.schema(opts: [foo: :int, bar: :string, baz: :pid], required: [:foo, :bar])

# Provide defaults for arguments (defaults will have to pass any type validation)
# If they provide they key, but a `nil` value, the default is *not* used.
Optimal.schema(opts: [foo: :int, bar: :string, baz: :boolean], defaults: [baz: true])

# Allow only specific values for certain opts
Optimal.schema(opts: [foo: {:enum, [1, 2, 3]}])

# Custom validations
# Read below for more info
def custom(field_value, field_name, all_opts, schema) do
  if is_special(field_value) do
    :ok
  else
    [{field_name, "must be special"}]
  end
end

Optimal.schema(opts: [foo: :integer, bar: :string], custom: [bar: &custom/4])
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
* `{:list, value_type}` - List where all values are of type `value_type`
* `{:function, arity}` - A function with the arity given by `arity`
* `{:struct, Some.Struct`} - An instance of `Some.Struct`
* `%Some.Struct{}` - Same as `{:struct, Some.Struct}`
* `{:enum, [value1, value2]}` - Allows any value in the list.
* `{:tuple, tuple_size}` - Tuple with size `tuple_size`.
* `{:tuple, {type1, type2, ...}}` - Tuple with given type structure, so the first element is of type `type1`, etc.
* `{:tuple, tuple_size, value_type}` - Tuple with size `tuple_size` and every element of type `value_type`.
* A nested optimal schema - Will validate that the provided keyword list adheres to the schema.

## Custom Validations

Your custom validators are defined as keyword list added to the `custom:` atom, e.g.

```elixir
Optimal.schema(opts: [foo: :integer, bar: :string], custom: [bar: &my_custom_validator/4])
```

Custom validations have the ability to add arbitrary errors and can modify the `opts` as they pass through. They are run in order, and unlike all built in validations, they are only run on valid opts. In other words, the custom validators run _after_ the other validators.

Your custom validation functions should receive 4 arguments:
 
* field value
* field id (atom)
* options
* schema

And they may return several different types of responses:

* `true` / `false` to indicate whether it passed or failed validation
* `:ok` to indicate that it passed validation
* `{:ok, updated_options}` to provide modifications to the options before output
* `{:error, error_or_errors}` to provide a custom message(s) about a failed validation
* `[]` to indicate that it passed validation
* a list of errors to indicate why it failed validation

### Custom Validator Usage Example

Because custom validators can modify the `opts`, we can change the final output to a map (arbitrarily, this validation rule is attached to the `c` field):

```elixir
iex> my_data = [{:a, "Apple"}, {:b, "Boy"}, {:c, "Cat"}]
iex> schema = Optimal.schema(opts: [a: :string, b: :string, c: :string], custom: [c: fn _, _, opts, _ -> {:ok, Enum.into(opts, %{})} end])
iex> Optimal.validate(my_data, schema)                                      
{:ok, %{a: "Apple", b: "Boy", c: "Cat"}
```

### Custom Validation Function Examples

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
      [{field, "should be greater than 1"}]
    end

  if Integer.is_even(field_value) do
    errors
  else
    [{field, "should be even"} | errors]
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
