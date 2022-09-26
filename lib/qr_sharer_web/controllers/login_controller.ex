defmodule QrSharerWeb.LoginController do
  use QrSharerWeb, :controller
  alias QrSharer.Users.User

  def login(%{method: "GET"} = conn, _params) do
    conn = fetch_session(conn)

    case get_session(conn, :user_id) do
      nil ->
        changeset = User.changeset(%User{}, %{})
        render(conn, "login.html", changeset: changeset)

      _ ->
        redirect_to_cards(conn)
    end
  end

  def login(%{method: "POST"} = conn, params) do
    %{"user" => %{"password" => password, "username" => username}} = params

    case QrSharer.Users.login(username, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> redirect_to_cards()

      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: Routes.login_path(conn, :login))
    end
  end

  def logout(conn, _params) do
    # TODO: delete sesh/cookies
    conn
  end

  defp redirect_to_cards(conn) do
    redirect(conn, to: Routes.cards_path(conn, :index))
  end
end
