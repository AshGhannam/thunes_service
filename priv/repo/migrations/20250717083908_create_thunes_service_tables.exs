defmodule ThunesService.Repo.Migrations.CreateThunesServiceTables do
  use Ecto.Migration

  def change do
    # Thunes configurations table
    create table(:thunes_configurations) do
      add :name, :string, null: false
      add :api_key, :string, null: false
      add :api_secret, :string, null: false
      add :base_url, :string, null: false
      add :is_sandbox, :boolean, default: true
      add :is_active, :boolean, default: false
      add :description, :text
      add :timeout_ms, :integer, default: 30000

      timestamps(type: :utc_datetime)
    end

    create unique_index(:thunes_configurations, [:name])
    create index(:thunes_configurations, [:is_active])

    # Transactions table for tracking money transfers
    create table(:transactions) do
      add :external_id, :string, null: false
      add :thunes_transaction_id, :string
      add :sender_name, :string, null: false
      add :sender_country, :string, null: false
      add :receiver_name, :string, null: false
      add :receiver_country, :string, null: false
      add :amount, :decimal, precision: 15, scale: 2, null: false
      add :currency, :string, null: false
      add :exchange_rate, :decimal, precision: 15, scale: 6
      add :fee, :decimal, precision: 15, scale: 2
      add :status, :string, null: false, default: "pending"
      add :error_message, :text
      add :metadata, :map
      add :quote_data, :map
      add :completed_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:transactions, [:external_id])
    create index(:transactions, [:thunes_transaction_id])
    create index(:transactions, [:status])
    create index(:transactions, [:user_id])
    create index(:transactions, [:sender_country])
    create index(:transactions, [:receiver_country])
    create index(:transactions, [:inserted_at])

    # API logs table for comprehensive audit trail
    create table(:api_logs) do
      add :method, :string, null: false
      add :url, :string, null: false
      add :request_headers, :map
      add :request_body, :map
      add :response_status, :integer
      add :response_headers, :map
      add :response_body, :map
      add :duration_ms, :integer
      add :success, :boolean, default: false
      add :error_type, :string
      add :transaction_id, references(:transactions, on_delete: :nilify_all)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:api_logs, [:method])
    create index(:api_logs, [:response_status])
    create index(:api_logs, [:success])
    create index(:api_logs, [:transaction_id])
    create index(:api_logs, [:inserted_at])
    create index(:api_logs, [:duration_ms])

    # Countries table for supported transfer destinations
    create table(:countries) do
      add :code, :string, null: false
      add :name, :string, null: false
      add :currency, :string, null: false
      add :is_supported, :boolean, default: true
      add :min_amount, :decimal, precision: 15, scale: 2
      add :max_amount, :decimal, precision: 15, scale: 2
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:countries, [:code])
    create index(:countries, [:is_supported])
    create index(:countries, [:currency])
  end
end
