defmodule QrSharer.Repo.Migrations.CreateLoyaltyCards do
  use Ecto.Migration

  def change do
    create table(:loyalty_cards) do
      add :cooldown_minutes, :integer
      add :last_used, :timestamptz
      add :max_uses, :integer, null: false
      add :name, :string, null: false
      add :owner_quota, :integer, null: false
      add :owner_id, references(:users), null: false
      add :qr_data, :string, null: false
      add :uses_today, :integer, null: false

      timestamps(type: :timestamptz)
    end
  end
end
