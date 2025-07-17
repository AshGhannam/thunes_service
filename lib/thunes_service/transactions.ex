defmodule ThunesService.Transactions do
  @moduledoc """
  The Transactions context for managing money transfer records.
  """

  import Ecto.Query, warn: false
  alias ThunesService.Repo
  alias ThunesService.Transactions.Transaction

  @doc """
  Returns the list of transactions.
  """
  def list_transactions do
    Repo.all(from t in Transaction, order_by: [desc: t.inserted_at])
  end

  @doc """
  Gets a single transaction.
  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Gets a transaction by external_id.
  """
  def get_transaction_by_external_id(external_id) do
    Repo.get_by(Transaction, external_id: external_id)
  end

  @doc """
  Creates a transaction.
  """
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, transaction} ->
        # Broadcast to subscribers
        Phoenix.PubSub.broadcast(
          ThunesService.PubSub,
          "transactions",
          {:transaction_created, transaction}
        )

        {:ok, transaction}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a transaction.
  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_transaction} ->
        # Broadcast to subscribers
        Phoenix.PubSub.broadcast(
          ThunesService.PubSub,
          "transactions",
          {:transaction_updated, updated_transaction}
        )

        {:ok, updated_transaction}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a transaction.
  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.
  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  @doc """
  Gets transaction statistics for dashboard.
  """
  def get_transaction_stats do
    query =
      from t in Transaction,
        select: %{
          total_count: count(t.id),
          total_amount: sum(t.amount),
          successful_count: count(t.id, :distinct) |> filter(t.status == "completed"),
          pending_count: count(t.id, :distinct) |> filter(t.status == "pending"),
          failed_count: count(t.id, :distinct) |> filter(t.status == "failed")
        }

    Repo.one(query) ||
      %{
        total_count: 0,
        total_amount: Decimal.new("0"),
        successful_count: 0,
        pending_count: 0,
        failed_count: 0
      }
  end
end
