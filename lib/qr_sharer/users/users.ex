defmodule QrSharer.Users do
  @moduledoc """
  Context module for users
  """

  import Ecto.Query
  alias QrSharer.Repo
  alias QrSharer.Users.User

  def get_user(user_id), do: Repo.get(User, user_id)

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def edit_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(user) do
    Repo.delete(user)
  end

  def login(username, password) do
    from(u in User, where: u.username == ^username)
    |> Repo.one()
    |> case do
      %User{password_hash: password_hash} = user ->
        if Argon2.verify_pass(password, password_hash) do
          {:ok, user}
        else
          {:error, "Incorrect credentials"}
        end

      nil ->
        {:error, "Incorrect credentials"}
    end
  end
end
