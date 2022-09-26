defmodule QrSharer.Users.User do
  @moduledoc """
  Schema and changesets for users
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :username, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :username])
    |> maybe_set_password()
  end

  def maybe_set_password(changeset) do
    password = get_change(changeset, :password)

    if password do
      changeset
      |> put_change(:password_hash, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
