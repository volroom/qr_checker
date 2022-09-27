defmodule QrSharer.LoyaltyCards.Supervisor do
  @moduledoc """
  Supervisor for each loyalty card GenServer
  """
  use Supervisor

  alias QrSharer.LoyaltyCards.Server

  def start_link(_), do: Supervisor.start_link(__MODULE__, nil, name: __MODULE__)

  def wipe_stats do
    :ok = QrSharer.LoyaltyCards.wipe_stats()

    __MODULE__
    |> Process.whereis()
    |> Process.exit(:kill)
  end

  # TODO: update liveviews after wipe stats

  def add_card_server(card) do
    Supervisor.start_child(__MODULE__, Supervisor.child_spec({Server, card}, id: card.id))
  end

  @impl true
  def init(_init_arg) do
    children =
      Enum.map(
        QrSharer.LoyaltyCards.list_cards(),
        &Supervisor.child_spec({Server, &1}, id: &1.id)
      )

    Supervisor.init(children, strategy: :one_for_one)
  end
end
