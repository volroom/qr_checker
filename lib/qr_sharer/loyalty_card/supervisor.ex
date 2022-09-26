defmodule QrSharer.LoyaltyCards.Supervisor do
  @moduledoc """
  Supervisor for each loyalty card GenServer
  """
  use Supervisor

  def start_link(_), do: Supervisor.start_link(__MODULE__, nil, name: __MODULE__)

  def wipe_stats do
    :ok = QrSharer.LoyaltyCards.wipe_stats()

    __MODULE__
    |> Process.whereis()
    |> Process.exit(:kill)
  end

  @impl true
  def init(_init_arg) do
    children = Enum.map(QrSharer.LoyaltyCards.list_cards(), &{QrSharer.LoyaltyCards.Server, &1})
    Supervisor.init(children, strategy: :one_for_one)
  end
end
