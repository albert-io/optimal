defmodule Optimal.MixProject do
  use Mix.Project

  @version "0.3.6"

  def project do
    [
      app: :optimal,
      version: @version,
      elixir: "~> 1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A schema based `opt` validator",
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls.travis": :test
      ]
    ]
  end

  def docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/optimal",
      source_url: "https://github.com/albert-io/optimal",
      extras: [
        "README.md"
      ]
    ]
  end

  def package do
    [
      maintainers: ["Zach Daniel"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/albert-io/optimal"},
      source_url: "https://github.com/albert-io/optimal",
      files: ~w(.formatter.exs mix.exs README.md lib)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.20.1", only: :dev},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:inch_ex, "~> 2.0", only: [:dev, :test]},
      {:dialyxir,
       github: "jeremyjh/dialyxir",
       ref: "00c1e32153b54e4b54f0d33f999d642c00dcd72b",
       only: [:dev],
       runtime: false}
    ]
  end
end
