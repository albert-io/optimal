defmodule Optimal.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :optimal,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A schema based `opt` validator",
      docs: docs(),
      package: package()
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
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.6", only: :test},
      {:inch_ex, "~> 0.5", only: [:dev, :test]}
    ]
  end
end
