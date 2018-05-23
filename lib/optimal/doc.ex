defmodule Optimal.Doc do
  @moduledoc """
  Automatic opt documentation, to be placed into your function docstrings
  """

  alias Optimal.Schema

  @document_opts Optimal.schema(
                   opts: [name: :string, header_depth: :int],
                   defaults: [name: "Opts", header_depth: 1],
                   describe: [
                     name: "The top level header for the opts documentation",
                     header_depth: "How many `#` to prepend before any heading"
                   ]
                 )

  # These opts cannot be auto-documented, so must be regenerated manually
  @doc """
  ---
  ## Opts

  * `name`(`:string`): The top level header for the opts documentation - Default: "Opts"
  * `header_depth`(`:int`): How many `#` to prepend before any heading - Default: 1

  ---
  """
  @spec document(schema :: Optimal.schema(), doc_opts :: Keyword.t()) :: String.t()
  def document(schema, doc_opts \\ [])

  def document(%Schema{opts: [], extra_keys?: false}, doc_opts) do
    doc_opts = Optimal.validate!(doc_opts, @document_opts)

    "---\n" <>
      header(1, doc_opts[:header_depth]) <>
      doc_opts[:name] <> "\n\nAccepts no options.\n" <> "---"
  end

  def document(%Schema{opts: [], extra_keys?: true}, doc_opts) do
    doc_opts = Optimal.validate!(doc_opts, @document_opts)

    "---\n" <>
      header(1, doc_opts[:header_depth]) <>
      doc_opts[:name] <> "\n\nAccepts any options.\n" <> "---"
  end

  def document(schema, doc_opts) do
    doc_opts = Optimal.validate!(doc_opts, @document_opts)

    prefix = "---\n" <> header(1, doc_opts[:header_depth]) <> doc_opts[:name] <> "\n\n"

    documented_opts = prefix <> document_opts(schema.opts, schema, doc_opts) <> "\n"

    with_extra_keys =
      if schema.extra_keys? do
        documented_opts <> "\nAlso accepts extra opts that are not named here.\n"
      else
        documented_opts
      end

    with_extra_keys <> "\n---"
  end

  defp document_opts([], _, _), do: ""

  defp document_opts(opts, schema, doc_opts) do
    opts
    |> Enum.group_by(fn opt ->
      schema.annotations[opt]
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map_join("\n", fn {annotation, opts} ->
      if annotation do
        "\n" <>
          header(3, doc_opts[:header_depth]) <>
          to_string(annotation) <> "\n\n" <> do_document_opts(opts, schema)
      else
        do_document_opts(opts, schema)
      end
    end)
  end

  defp do_document_opts(opts, schema) do
    opts
    |> Enum.sort_by(fn opt ->
      opt not in schema.required
    end)
    |> Enum.map_join("\n", fn opt ->
      string_opt = "`" <> Atom.to_string(opt) <> "`"
      string_type = "`" <> inspect(schema.types[opt]) <> "`"
      description = schema.describe[opt]

      required =
        if opt in schema.required do
          " **Required**"
        else
          ""
        end

      prefix = "* " <> string_opt <> "(" <> string_type <> ")"

      with_description_and_type =
        if description do
          prefix <> required <> ": " <> description
        else
          prefix <> required
        end

      if Keyword.has_key?(schema.defaults, opt) do
        with_description_and_type <> " - Default: " <> inspect(schema.defaults[opt])
      else
        with_description_and_type
      end
    end)
  end

  defp header(depth, header_depth_opt), do: String.duplicate("#", header_depth_opt + depth) <> " "
end
