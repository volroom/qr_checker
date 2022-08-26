defmodule QrSharer.Repo do
  use Ecto.Repo,
    otp_app: :qr_sharer,
    adapter: Ecto.Adapters.SQLite3
end
