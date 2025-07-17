defmodule ThunesService.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :external_id, :string
    field :thunes_transaction_id, :string
    field :sender_name, :string
    field :sender_country, :string
    field :receiver_name, :string
    field :receiver_country, :string
    field :amount, :decimal
    field :currency, :string
    field :exchange_rate, :decimal
    field :fee, :decimal
    field :status, :string, default: "pending"
    field :error_message, :string
    field :metadata, :map
    field :quote_data, :map
    field :completed_at, :utc_datetime

    belongs_to :user, ThunesService.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :external_id,
      :thunes_transaction_id,
      :sender_name,
      :sender_country,
      :receiver_name,
      :receiver_country,
      :amount,
      :currency,
      :exchange_rate,
      :fee,
      :status,
      :error_message,
      :metadata,
      :quote_data,
      :completed_at,
      :user_id
    ])
    |> validate_required([
      :external_id,
      :sender_name,
      :sender_country,
      :receiver_name,
      :receiver_country,
      :amount,
      :currency,
      :status
    ])
    |> validate_length(:external_id, min: 3, max: 100)
    |> validate_length(:sender_name, min: 2, max: 100)
    |> validate_length(:receiver_name, min: 2, max: 100)
    |> validate_length(:sender_country, is: 2)
    |> validate_length(:receiver_country, is: 2)
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:status, ["pending", "processing", "completed", "failed", "cancelled"])
    |> validate_format(:currency, ~r/^[A-Z]{3}$/, message: "must be a 3-letter currency code")
    |> unique_constraint(:external_id)
    |> validate_completion_status()
  end

  defp validate_completion_status(changeset) do
    status = get_change(changeset, :status)
    completed_at = get_change(changeset, :completed_at)

    case {status, completed_at} do
      {"completed", nil} ->
        put_change(changeset, :completed_at, DateTime.utc_now())

      {status, _} when status in ["pending", "processing", "failed", "cancelled"] ->
        changeset

      _ ->
        changeset
    end
  end
end
