defmodule QrSharer.LoyaltyCards do
  @moduledoc """
  Context module for loyalty cards
  """
  import Ecto.Query

  alias QrSharer.Repo
  alias QrSharer.LoyaltyCards.LoyaltyCard

  def create_loyalty_card(attrs, user_id) do
    attrs =
      attrs
      |> Enum.into(%{}, fn {key, val} -> {String.to_existing_atom(key), val} end)
      |> Map.put(:owner_id, user_id)

    %LoyaltyCard{}
    |> LoyaltyCard.changeset(attrs)
    |> Repo.insert()
  end

  def list_cards, do: Repo.all(LoyaltyCard)

  def get_uses_remaining(%{owner_id: user_id} = card, user_id) do
    card.max_uses - card.uses_today
  end

  def get_uses_remaining(card, _) do
    card.max_uses - card.owner_quota - card.uses_today
  end

  def card_cooled_down?(%{last_used: nil}), do: true

  def card_cooled_down?(card) do
    earliest_possible_time = Timex.shift(card.last_used, minutes: card.cooldown_minutes)
    Timex.after?(Timex.now(), earliest_possible_time)
  end

  def generate_qr_code(card) do
    case QRCode.create(card.qr_data) do
      {:ok, qr_code} ->
        qr_code
        |> QRCode.Svg.create()
        |> Base.encode64()
        |> then(&{:ok, &1})

      error ->
        error
    end
  end

  def use_card(card) do
    now = Timex.now()

    from(
      c in LoyaltyCard,
      where: c.id == ^card.id,
      update: [inc: [uses_today: 1], set: [last_used: ^now, updated_at: ^now]],
      select: c
    )
    |> Repo.update_all([])
    |> case do
      {1, [card]} -> {:ok, card}
      _ -> {:error, card}
    end
  end

  def wipe_stats do
    now = Timex.now()

    from(
      c in LoyaltyCard,
      update: [set: [last_used: nil, uses_today: 0, updated_at: ^now]]
    )
    |> Repo.update_all([])
    |> case do
      {rows, _} when is_integer(rows) -> :ok
      error -> error
    end
  end
end
