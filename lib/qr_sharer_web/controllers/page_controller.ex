defmodule QrSharerWeb.PageController do
  use QrSharerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
