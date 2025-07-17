defmodule ThunesServiceWeb.TransferController do
  use ThunesServiceWeb, :controller

  alias ThunesService.ThunesClient
  alias ThunesService.Transactions

  @doc """
  POST /api/transfers
  Create a new money transfer
  """
  def create(conn, params) do
    # Generate external ID for tracking
    external_id = generate_external_id()

    # Create initial transaction record
    transaction_attrs = %{
      external_id: external_id,
      sender_name: params["sender_name"],
      sender_country: params["sender_country"],
      receiver_name: params["receiver_name"],
      receiver_country: params["receiver_country"],
      amount: Decimal.new(params["amount"]),
      currency: params["currency"],
      status: "pending"
    }

    case Transactions.create_transaction(transaction_attrs) do
      {:ok, transaction} ->
        # Prepare parameters for Thunes API
        transfer_params = %{
          "external_id" => external_id,
          "sender" => %{
            "name" => params["sender_name"],
            "country" => params["sender_country"]
          },
          "receiver" => %{
            "name" => params["receiver_name"],
            "country" => params["receiver_country"]
          },
          "amount" => params["amount"],
          "currency" => params["currency"]
        }

        client = ThunesClient.new()

        case ThunesClient.create_transfer(client, transfer_params) do
          {:ok, response} ->
            # Update transaction with Thunes response
            Transactions.update_transaction(transaction, %{
              thunes_transaction_id: response["id"],
              status: "processing",
              metadata: response
            })

            conn
            |> put_status(:created)
            |> json(%{
              status: "success",
              data: %{
                external_id: external_id,
                thunes_id: response["id"],
                status: "processing"
              },
              message: "Transfer created successfully"
            })

          {:error, reason} ->
            # Update transaction with error
            Transactions.update_transaction(transaction, %{
              status: "failed",
              error_message: inspect(reason)
            })

            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              status: "error",
              error: reason,
              external_id: external_id,
              message: "Failed to create transfer"
            })
        end

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          errors: transform_changeset_errors(changeset),
          message: "Invalid transaction data"
        })
    end
  end

  @doc """
  GET /api/transfers/:id
  Get transfer status by ID
  """
  def show(conn, %{"id" => transfer_id}) do
    case Transactions.get_transaction_by_external_id(transfer_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{
          status: "error",
          message: "Transfer not found"
        })

      transaction ->
        # If we have a Thunes transaction ID, check for updates
        if transaction.thunes_transaction_id do
          client = ThunesClient.new()

          case ThunesClient.get_transfer_status(client, transaction.thunes_transaction_id) do
            {:ok, response} ->
              # Update local transaction status
              updated_status = map_thunes_status(response["status"])
              
              Transactions.update_transaction(transaction, %{
                status: updated_status,
                .merge(transaction.metadata || %{}, response)
              })

              conn
              |> put_status(:ok)
              |> json(%{
                status: "success",
                data: %{
                  external_id: transaction.external_id,
                  thunes_id: transaction.thunes_transaction_id,
                  status: updated_status,
                  amount: transaction.amount,
                  currency: transaction.currency,
                  created_at: transaction.inserted_at
                }
              })

            {:error, :transfer_not_found} ->
              conn
              |> put_status(:not_found)
              |> json(%{
                status: "error",
                message: "Transfer not found on Thunes"
              })

            {:error, _reason} ->
              # Return local data if API is unavailable
              conn
              |> put_status(:ok)
              |> json(%{
                status: "success",
                data: %{
                  external_id: transaction.external_id,
                  status: transaction.status,
                  amount: transaction.amount,
                  currency: transaction.currency,
                  created_at: transaction.inserted_at
                },
                message: "Showing cached status (API unavailable)"
              })
          end
        else
          # Return local transaction data
          conn
          |> put_status(:ok)
          |> json(%{
            status: "success",
            data: %{
              external_id: transaction.external_id,
              status: transaction.status,
              amount: transaction.amount,
              currency: transaction.currency,
              created_at: transaction.inserted_at
            }
          })
        end
    end
  end

  @doc """
  GET /api/quote
  Get a quote for a money transfer
  """
  def quote(conn, params) do
    quote_params = %{
      "amount" => params["amount"],
      "currency" => params["currency"],
      "destination_country" => params["destination_country"]
    }

    client = ThunesClient.new()

    case ThunesClient.get_quote(client, quote_params) do
      {:ok, response} ->
        conn
        |> put_status(:ok)
        |> json(%{
          status: "success",
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          error: reason,
          message: "Failed to get quote"
        })
    end
  end

  # Private helper functions

  defp generate_external_id do
    "TXN-" <> (:crypto.strong_rand_bytes(8) |> Base.encode16())
  end

  defp map_thunes_status("completed"), do: "completed"
  defp map_thunes_status("failed"), do: "failed"
  defp map_thunes_status("cancelled"), do: "cancelled"
  defp map_thunes_status("processing"), do: "processing"
  defp map_thunes_status(_), do: "pending"

  defp transform_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end

