defmodule DocTest do
  use ExUnit.Case
  doctest Optimal

  import Optimal, only: [schema: 1, schema: 0, merge: 3, document: 2, document: 1]

  defp doc(name \\ "Opts", contents) do
    String.trim_trailing("""
    ---
    ## #{name}

    #{contents}
    ---
    """)
  end

  test "that an empty schema that allows no extra keys is special cased" do
    assert(document(schema()) == doc("Accepts no options."))
  end

  test "that an empty that allows extra keys is special cased" do
    schema = schema(extra_keys?: true)

    assert(document(schema) == doc("Accepts any options."))
  end

  test "that the primary header name can be changed" do
    schema = schema()

    assert(document(schema, name: "Yo") == doc("Yo", "Accepts no options."))
  end

  test "that opts with no descriptions are rendered correctly" do
    schema = schema(opts: [foo: :int])

    assert(
      document(schema) ==
        doc("""
        * `foo`(`:int`)
        """)
    )
  end

  test "that opts with descriptions are rendered correctly" do
    schema = schema(opts: [foo: :int], describe: [foo: "Name of the foo"])

    assert(
      document(schema) ==
        doc("""
        * `foo`(`:int`): Name of the foo
        """)
    )
  end

  test "that required opts are rendered in a separate section" do
    schema =
      schema(
        opts: [foo: :int, bar: :pid],
        describe: [foo: "The number of foos", bar: "The pid to send the foos to."],
        required: [:bar]
      )

    assert(
      document(schema) ==
        doc("""
        * `bar`(`:pid`) **Required**: The pid to send the foos to.
        * `foo`(`:int`): The number of foos
        """)
    )
  end

  test "that extra_keys is rendered below everything" do
    schema =
      schema(
        opts: [foo: :int, bar: :pid],
        describe: [foo: "The number of foos", bar: "The pid to send the foos to."],
        required: [:bar],
        extra_keys?: true
      )

    assert(
      document(schema) ==
        doc("""
        * `bar`(`:pid`) **Required**: The pid to send the foos to.
        * `foo`(`:int`): The number of foos

        Also accepts extra opts that are not named here.
        """)
    )
  end

  test "that merge annotations further group opts" do
    left = schema(opts: [foo: :int])
    right = schema(opts: [bar: :int])
    m1 = merge(left, right, annotate: "Base")
    second_right = schema(opts: [baz: :int], required: [:baz])
    m2 = merge(m1, second_right, annotate: "Middle")

    assert(
      document(m2) ==
        doc("""
        * `foo`(`:int`)

        #### Base

        * `bar`(`:int`)

        #### Middle

        * `baz`(`:int`) **Required**
        """)
    )
  end
end
