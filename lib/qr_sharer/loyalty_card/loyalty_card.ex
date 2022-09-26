defmodule QrSharer.LoyaltyCards.LoyaltyCard do
  @moduledoc """
  Schema and changesets for loyalty cards
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias QrSharer.Users.User

  schema "loyalty_cards" do
    field :cooldown_minutes, :integer, default: 30
    field :last_used, :utc_datetime
    field :max_uses, :integer
    field :name, :string
    field :owner_quota, :integer, default: 2
    field :qr_data, :string
    field :uses_today, :integer, default: 0

    belongs_to :owner, User
    timestamps(type: :utc_datetime)
  end

  def changeset(loyalty_card, attrs) do
    loyalty_card
    |> cast(attrs, [
      :cooldown_minutes,
      :last_used,
      :max_uses,
      :name,
      :owner_quota,
      :qr_data,
      :uses_today,
      :owner_id
    ])
    |> validate_required([
      :cooldown_minutes,
      :max_uses,
      :name,
      :owner_quota,
      :qr_data,
      :uses_today
    ])
  end
end
