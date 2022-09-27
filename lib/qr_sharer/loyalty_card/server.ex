defmodule QrSharer.LoyaltyCards.Server do
  @moduledoc """
  GenServer for each loyalty card
  """
  use GenServer

  alias QrSharer.LoyaltyCards

  def start_link(card) do
    GenServer.start_link(__MODULE__, card, name: {:global, server_name(card.id)})
  end

  def get_qr_code(card_id, user_id) do
    GenServer.call(get_pid(card_id), {:get_qr_code, user_id})
  end

  ## Callbacks
  @impl true
  def init(card) do
    {:ok, qr_code} = LoyaltyCards.generate_qr_code(card)

    card
    |> Map.from_struct()
    |> Map.put(:qr_code, qr_code)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_call({:get_qr_code, user_id}, _from, card) do
    if LoyaltyCards.get_uses_remaining(card, user_id) > 0 do
      if LoyaltyCards.card_cooled_down?(card) do
        {:ok, updated_card} = LoyaltyCards.use_card(card)
        card = Map.merge(card, Map.from_struct(updated_card))
        {:reply, {:ok, card.qr_code, updated_card}, card}
      else
        {:reply, {:error, :card_not_cooled_down}, card}
      end
    else
      {:reply, {:error, :no_uses_remaining}, card}
    end
  end

  defp get_pid(card_id) do
    card_id
    |> server_name()
    |> :global.whereis_name()
  end

  defp server_name(card_id), do: {__MODULE__, "#{card_id}"}
end
