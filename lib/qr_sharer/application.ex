defmodule QrSharer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Run migrations
    QrSharer.Release.migrate()

    children = [
      QrSharer.Repo,
      QrSharer.Scheduler,
      QrSharer.LoyaltyCards.Supervisor,
      QrSharerWeb.Telemetry,
      {Phoenix.PubSub, name: QrSharer.PubSub},
      QrSharerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: QrSharer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    QrSharerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
