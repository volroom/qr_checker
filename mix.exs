defmodule QrSharer.MixProject do
  use Mix.Project

  def project do
    [
      app: :qr_sharer,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {QrSharer.Application, []},
      extra_applications: [:crypto, :logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    # TODO: update deps
    [
      {:argon2_elixir, "~> 3.0"},
      {:credo, "~> 1.6"},
      {:ecto_sql, "~> 3.8"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:floki, ">= 0.33.0", only: :test},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.6.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.18.0"},
      {:plug_cowboy, "~> 2.5"},
      {:qr_code, "~> 2.3"},
      {:quantum, "~> 3.5"},
      {:quantum_storage_persistent_ets, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.7"},
      {:tzdata, "~> 1.1"},
      {:uuid, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
