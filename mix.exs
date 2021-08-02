defmodule BarcodeGenerator.MixProject do
  use Mix.Project

  @version "1.0.0"
  @repo_url "https://github.com/jeroenvisser101/barcode_generator"

  def project do
    [
      app: :barcode_generator,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),

      # Hex
      package: package(),
      description: "A tiny package generating GTIN barcodes, efficiently",

      # Docs
      name: "BarcodeGenerator",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flow, "~> 1.0", optional: true},
      {:ex_doc, ">= 0.19.0", only: :dev},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Jeroen Visser"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  defp docs do
    [
      main: "BarcodeGenerator",
      source_ref: "v#{@version}",
      source_url: @repo_url
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:flow, :gen_stage],
      plt_file:
        {:no_warn, ".dialyzer/elixir-#{System.version()}-erlang-otp-#{System.otp_release()}.plt"}
    ]
  end
end
