defmodule QrSharerWeb.Auth do
  @moduledoc """
  Auth module for LiveViews
  """
  import Phoenix.LiveView
  alias Plug.Conn
  alias QrSharerWeb.Router.Helpers, as: Routes

  def require_user(conn, _) do
    conn = Conn.fetch_session(conn)

    case Conn.get_session(conn, :user_id) do
      nil ->
        conn
        |> Phoenix.Controller.redirect(to: Routes.login_path(conn, :login))
        |> Conn.halt()

      _ ->
        conn
    end
  end

  def on_mount(:set_user, _params, %{"user_id" => user_id}, socket) do
    {:cont, Phoenix.Component.assign(socket, :user_id, user_id)}
  end

  def on_mount(:set_user, _params, _session, socket) do
    {:halt, redirect(socket, to: Routes.login_path(socket, :login))}
  end
end
