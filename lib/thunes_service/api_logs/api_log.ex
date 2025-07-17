defmodule ThunesService.ApiLogs.ApiLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "api_logs" do
    field :method, :string
    field :url, :string
    field :request_headers, :map
    field :request_body, :map
    field :response_status, :integer
    field :response_headers, :map
    field :response_body, :map
    field :duration_ms, :integer
    field :success, :boolean, default: false
    field :error_type, :string

    belongs_to :transaction, ThunesService.Transactions.Transaction

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(api_log, attrs) do
    api_log
    |> cast(attrs, [
      :method,
      :url,
      :request_headers,
      :request_body,
      :response_status,
      :response_headers,
      :response_body,
      :duration_ms,
      :success,
      :error_type,
      :transaction_id
    ])
    |> validate_required([:method, :url])
    |> validate_inclusion(:method, ["GET", "POST", "PUT", "DELETE", "PATCH"])
    |> validate_format(:url, ~r/^https?:\/\//, message: "must be a valid URL")
    |> validate_number(:duration_ms, greater_than_or_equal_to: 0)
    |> validate_number(:response_status, greater_than_or_equal_to: 100, less_than: 600)
  end
end
