defmodule Optimal.MixProject do
  use Mix.Project

  def project do
    [
      app: :optimal,
      version: "0.1.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A schema based `opt` validator",
      package: [
        maintainers: ["Zach Daniel"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/albert-io/optimal"},
        source_url: "https://github.com/albert-io/optimal"
      ]
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
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
