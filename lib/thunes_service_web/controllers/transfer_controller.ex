defmodule ThunesServiceWeb.TransferController do
  use ThunesServiceWeb, :controller

  alias ThunesService.ThunesClient

  @doc """
  POST /api/transfers
  Create a new money transfer
  """
  def create(conn, params) do
    # Extract required parameters
    transfer_params = %{
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
        # TODO: Store transaction in database
        conn
        |> put_status(:created)
        |> json(%{
          status: "success",
          data: response,
          message: "Transfer created successfully"
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          error: reason,
          message: "Failed to create transfer"
        })
    end
  end

  @doc """
  GET /api/transfers/:id
  Get transfer status by ID
  """
  def show(conn, %{"id" => transfer_id}) do
    client = ThunesClient.new()

    case ThunesClient.get_transfer_status(client, transfer_id) do
      {:ok, _response} ->
        conn
        |> put_status(:ok)
        |> json(%{
          status: "success"
        })

      {:error, :transfer_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          status: "error",
          message: "Transfer not found"
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          error: reason,
          message: "Failed to retrieve transfer status"
        })
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
          data: response
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
end
