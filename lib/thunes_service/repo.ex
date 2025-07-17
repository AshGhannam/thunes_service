defmodule ThunesService.Repo do
  use Ecto.Repo,
    otp_app: :thunes_service,
    adapter: Ecto.Adapters.SQLite3
end
