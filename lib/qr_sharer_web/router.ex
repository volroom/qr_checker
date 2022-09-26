defmodule QrSharerWeb.Router do
  @moduledoc false
  use QrSharerWeb, :router
  import QrSharerWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {QrSharerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", QrSharerWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/login", LoginController, :login
    post "/login", LoginController, :login
    post "/logout", LoginController, :logout
  end

  scope "/cards", QrSharerWeb do
    pipe_through [:browser, :require_user]

    live_session :main, on_mount: {QrSharerWeb.Auth, :set_user} do
      live "/", CardsLive, :index
      live "/new", CardsLive, :new
    end
  end
end
