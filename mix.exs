defmodule Optimal.MixProject do
  use Mix.Project

  @version "1.1.0"

  def project do
    [
      app: :optimal,
      version: @version,
      elixir: "~> 1.0",
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
      maintainers: ["Alec Hartung"],
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
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false, warn_if_outdated: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
