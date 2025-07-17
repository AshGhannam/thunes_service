defmodule ThunesServiceWeb.ApiLogsLive do
  use ThunesServiceWeb, :live_view

  alias ThunesService.ApiLogs

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to real-time updates for API logs
      Phoenix.PubSub.subscribe(ThunesService.PubSub, "api_logs")
    end

    socket =
      socket
      |> assign(:page_title, "API Logs & Audit Trail")
      |> assign(:current_scope, socket.assigns[:current_scope])
      |> assign(:api_logs, list_api_logs())
      |> assign(:filters, %{method: "", success: nil, date_from: nil, date_to: nil})
      |> assign(:stats, get_api_stats())

    {:ok, socket}
  end

  @impl true
  def handle_info({:api_log_created, _log}, socket) do
    # Update logs when new ones come in
    {:noreply,
     socket
     |> assign(:api_logs, list_api_logs())
     |> assign(:stats, get_api_stats())}
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    filters = %{
      method: filter_params["method"] || "",
      success: parse_success_filter(filter_params["success"]),
      date_from: parse_date(filter_params["date_from"]),
      date_to: parse_date(filter_params["date_to"])
    }

    api_logs = ApiLogs.list_api_logs(filters)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:api_logs, api_logs)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = %{method: "", success: nil, date_from: nil, date_to: nil}

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:api_logs, list_api_logs())}
  end

  defp list_api_logs(filters \\ %{}) do
    ApiLogs.list_api_logs(filters)
    # Limit to recent 100 logs
    |> Enum.take(100)
  end

  defp get_api_stats do
    ApiLogs.get_api_stats()
  end

  defp parse_success_filter("true"), do: true
  defp parse_success_filter("false"), do: false
  defp parse_success_filter(_), do: nil

  defp parse_date(""), do: nil
  defp parse_date(nil), do: nil

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> DateTime.new!(date, ~T[00:00:00])
      _ -> nil
    end
  end

  defp format_timestamp(timestamp) do
    timestamp
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
  end

  defp format_duration(duration_ms) when is_integer(duration_ms) do
    "#{duration_ms}ms"
  end

  defp format_duration(_), do: "N/A"

  defp status_badge_class(true), do: "bg-green-500/20 text-green-300 border-green-400/30"
  defp status_badge_class(false), do: "bg-red-500/20 text-red-300 border-red-400/30"

  defp status_text(true), do: "Success"
  defp status_text(false), do: "Failed"

  defp method_badge_class("GET"), do: "bg-blue-500/20 text-blue-300 border-blue-400/30"
  defp method_badge_class("POST"), do: "bg-green-500/20 text-green-300 border-green-400/30"
  defp method_badge_class("PUT"), do: "bg-yellow-500/20 text-yellow-300 border-yellow-400/30"
  defp method_badge_class("DELETE"), do: "bg-red-500/20 text-red-300 border-red-400/30"
  defp method_badge_class(_), do: "bg-gray-500/20 text-gray-300 border-gray-400/30"

  defp truncate_url(url, length \\ 50) do
    if String.length(url) > length do
      String.slice(url, 0, length) <> "..."
    else
      url
    end
  end
end
