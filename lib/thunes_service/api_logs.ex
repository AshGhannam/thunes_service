defmodule ThunesService.ApiLogs do
  @moduledoc """
  The ApiLogs context for managing API request/response audit trails.
  """

  import Ecto.Query, warn: false
  alias ThunesService.Repo
  alias ThunesService.ApiLogs.ApiLog

  @doc """
  Returns the list of api_logs with optional filtering.
  """
  def list_api_logs(filters \\ %{}) do
    query = from l in ApiLog, order_by: [desc: l.inserted_at]

    query =
      Enum.reduce(filters, query, fn
        {:method, method}, query when method != "" ->
          from l in query, where: l.method == ^method

        {:success, success}, query when is_boolean(success) ->
          from l in query, where: l.success == ^success

        {:date_from, date}, query when not is_nil(date) ->
          from l in query, where: l.inserted_at >= ^date

        {:date_to, date}, query when not is_nil(date) ->
          from l in query, where: l.inserted_at <= ^date

        _, query ->
          query
      end)

    Repo.all(query)
  end

  @doc """
  Gets a single api_log.
  """
  def get_api_log!(id), do: Repo.get!(ApiLog, id)

  @doc """
  Creates an api_log.
  """
  def create_api_log(attrs \\ %{}) do
    %ApiLog{}
    |> ApiLog.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, log} ->
        # Broadcast to subscribers for real-time updates
        Phoenix.PubSub.broadcast(
          ThunesService.PubSub,
          "api_logs",
          {:api_log_created, log}
        )

        {:ok, log}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Gets API statistics for monitoring.
  """
  def get_api_stats do
    query =
      from l in ApiLog,
        select: %{
          total_requests: count(l.id),
          successful_requests: count(l.id, :distinct) |> filter(l.success == true),
          failed_requests: count(l.id, :distinct) |> filter(l.success == false),
          avg_response_time: avg(l.duration_ms)
        }

    Repo.one(query) ||
      %{
        total_requests: 0,
        successful_requests: 0,
        failed_requests: 0,
        avg_response_time: 0
      }
  end
end
