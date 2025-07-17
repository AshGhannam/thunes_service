defmodule ThunesService.ThunesClient do
  @moduledoc """
  Client for interacting with the Thunes Money Transfer API
  Handles authentication, requests, and comprehensive error handling
  """

  require Logger

  @base_url "https://api.thunes.com"

  @base_url "https://api.thunes.com"
  @sandbox_url "https://api-sandbox.thunes.com"
  @timeout 30_000

  defstruct [:api_key, :api_secret, :base_url, :timeout]

  @type t :: %__MODULE__{
          api_key: String.t(),
          api_secret: String.t(),
          base_url: String.t(),
          timeout: integer()
        }

  @doc """
  Creates a new Thunes client with configuration
  """
  def new(opts \\ []) do
    %__MODULE__{
      api_key: Keyword.get(opts, :api_key) || get_config(:api_key),
      api_secret: Keyword.get(opts, :api_secret) || get_config(:api_secret),
      base_url: (Keyword.get(opts, :sandbox, true) && @sandbox_url) || @base_url,
      timeout: Keyword.get(opts, :timeout, @timeout)
    }
  end

  @doc """
  Get a quote for a money transfer
  """
  def get_quote(client, params) do
    path = "/v2/money-transfers/quote"

    with {:ok, response} <- make_request(client, :post, path, params) do
      case response.status do
        200 -> {:ok, response.body}
        _ -> {:error, {:api_error, response.status, response.body}}
      end
    end
  end

  @doc """
  Create a money transfer
  """
  def create_transfer(client, params) do
    path = "/v2/money-transfers"

    with {:ok, response} <- make_request(client, :post, path, params) do
      case response.status do
        201 -> {:ok, response.body}
        _ -> {:error, {:api_error, response.status, response.body}}
      end
    end
  end

  @doc """
  Get transfer status
  """
  def get_transfer_status(client, transfer_id) do
    path = "/v2/money-transfers/#{transfer_id}"

    with {:ok, response} <- make_request(client, :get, path) do
      case response.status do
        200 -> {:ok, response.body}
        404 -> {:error, :transfer_not_found}
        _ -> {:error, {:api_error, response.status, response.body}}
      end
    end
  end

  @doc """
  Get list of available countries
  """
  def get_countries(client) do
    path = "/v2/countries"

    with {:ok, response} <- make_request(client, :get, path) do
      case response.status do
        200 -> {:ok, response.body}
        _ -> {:error, {:api_error, response.status, response.body}}
      end
    end
  end

  # Private functions

  defp make_request(client, method, path, body \\ nil) do
    url = client.base_url <> path
    headers = build_headers(client, method, path, body)

    request_start = System.monotonic_time()

    result =
      case method do
        :get -> Req.get(url, headers: headers, receive_timeout: client.timeout)
        :post -> Req.post(url, headers: headers, json: body, receive_timeout: client.timeout)
        :put -> Req.put(url, headers: headers, json: body, receive_timeout: client.timeout)
        :delete -> Req.delete(url, headers: headers, receive_timeout: client.timeout)
      end

    duration = System.monotonic_time() - request_start

    case result do
      {:ok, response} ->
        log_api_request(method, url, headers, body, response, duration)
        {:ok, response}

      {:error, reason} ->
        log_api_error(method, url, headers, body, reason, duration)
        {:error, reason}
    end
  end

  defp build_headers(client, method, path, body) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:second) |> to_string()
    nonce = generate_nonce()

    # Build signature according to Thunes API docs
    signature_data =
      "#{method |> to_string() |> String.upcase()}#{path}#{client.api_key}#{nonce}#{timestamp}"

    signature_data = if body, do: signature_data <> Jason.encode!(body), else: signature_data

    signature =
      :crypto.mac(:hmac, :sha256, client.api_secret, signature_data)
      |> Base.encode64()

    [
      {"Content-Type", "application/json"},
      {"X-API-Key", client.api_key},
      {"X-Signature", signature},
      {"X-Nonce", nonce},
      {"X-Timestamp", timestamp}
    ]
  end

  defp generate_nonce do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end

  defp log_api_request(method, url, headers, body, response, duration) do
    Task.start(fn ->
      attrs = %{
        method: method |> to_string() |> String.upcase(),
        url: url,
        request_headers: headers |> Enum.into(%{}),
        request_body: body,
        response_status: response.status,
        response_headers: response.headers |> Enum.into(%{}),
        response_body: response.body,
        duration_ms: System.convert_time_unit(duration, :native, :millisecond),
        success: response.status in 200..299,
        inserted_at: DateTime.utc_now()
      }

      ThunesService.ApiLogs.create_api_log(attrs)

      Logger.info("Thunes API Request",
        method: attrs.method,
        url: attrs.url,
        status: attrs.response_status,
        duration: "#{attrs.duration_ms}ms"
      )
    end)
  end
  end

  defp log_api_error(method, url, headers, body, error, duration) do
    Task.start(fn ->
      attrs = %{
        method: method |> to_string() |> String.upcase(),
        url: url,
        request_headers: headers |> Enum.into(%{}),
        request_body: body,
        response_status: nil,
        response_headers: %{},
        response_body: %{"error" => inspect(error)},
        duration_ms: System.convert_time_unit(duration, :native, :millisecond),
        success: false,
        error_type: inspect(error),
        inserted_at: DateTime.utc_now()
      }

      ThunesService.ApiLogs.create_api_log(attrs)

      Logger.error("Thunes API Error",
        method: attrs.method,
        url: attrs.url,
        error: inspect(error),
        duration: "#{attrs.duration_ms}ms"
      )
    end)
  end
  end

  defp get_config(key) do
    Application.get_env(:thunes_service, :thunes_api)[key]
  end
end
