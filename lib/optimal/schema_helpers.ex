defmodule Optimal.SchemaHelpers do
  @moduledoc """
  Helpers for building and working with schemas.
  """

  @doc """
  The schema of the opts for making an Optimal schema.
  """
  @spec schema_schema() :: Optimal.Schema.t()
  def schema_schema() do
    %Optimal.Schema{
      opts: [
        :opts,
        :required,
        :defaults,
        :extra_keys?,
        :custom,
        :describe
      ],
      types: [
        opts: [{:list, :atom}, :keyword],
        required: {:list, :atom},
        defaults: :keyword,
        extra_keys?: :boolean,
        custom: :keyword,
        describe: :keyword
      ],
      defaults: [
        opts: [],
        required: [],
        describe: [],
        defaults: [],
        extra_keys?: false,
        custom: []
      ],
      describe: [
        opts: "A list of opts accepted, or a keyword of opt name to opt type",
        required: "A list of required opts (all of which must be in `opts` as well)",
        defaults: "A keyword list of option name to a default value. Values must pass type rules",
        extra_keys?: "If enabled, extra keys not specified by the schema do not fail validation",
        custom: "A keyword list of option name (for errors) and custom validations. See README",
        describe: "A keyword list of option names to short descriptions (like these)"
      ],
      extra_keys?: false,
      custom: [
        opts: &Optimal.Type.validate_types/4
      ]
    }
  end

  @doc """
  The schema of the opts for merging two optimal schemas
  """
  @spec merge_schema() :: Optimal.Schema.t()
  def merge_schema() do
    %Optimal.Schema{
      opts: [
        :annotate,
        :add_required?
      ],
      types: [
        annotate: :string,
        add_required?: :boolean
      ],
      defaults: [
        add_required?: true
      ],
      describe: [
        annotate: "Annotates the source of the opt, to be used in displaying documentation.",
        add_required?:
          "If true, all required fields from left/right are marked as required. " <>
            "Otherwise, only takes required fields from the left."
      ]
    }
  end
end
