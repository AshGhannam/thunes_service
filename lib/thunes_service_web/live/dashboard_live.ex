defmodule ThunesServiceWeb.DashboardLive do
  use ThunesServiceWeb, :live_view

  alias ThunesService.Transactions

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to real-time updates for transactions
      Phoenix.PubSub.subscribe(ThunesService.PubSub, "transactions")
      Phoenix.PubSub.subscribe(ThunesService.PubSub, "api_logs")
    end

    socket =
      socket
      |> assign(:page_title, "Money Transfer Dashboard")
      |> assign(:current_scope, socket.assigns[:current_scope])
      |> assign(:stats, get_dashboard_stats())
      |> assign(:recent_transactions, get_recent_transactions())
      |> assign(:api_status, get_api_status())

    {:ok, socket}
  end

  @impl true
  def handle_info({:transaction_created, _transaction}, socket) do
    # Update recent transactions when new ones come in
    {:noreply,
     socket
     |> assign(:recent_transactions, get_recent_transactions())
     |> assign(:stats, get_dashboard_stats())}
  end

  @impl true
  def handle_info({:transaction_updated, _transaction}, socket) do
    # Update recent transactions when new ones come in
    {:noreply,
     socket
     |> assign(:recent_transactions, get_recent_transactions())
     |> assign(:stats, get_dashboard_stats())}
  end

  @impl true
  def handle_info({:api_log_created, _log}, socket) do
    # Update API status when new logs come in
    {:noreply, assign(socket, :api_status, get_api_status())}
  end

  @impl true
  def handle_event("refresh_stats", _params, socket) do
    {:noreply,
     socket
     |> assign(:stats, get_dashboard_stats())
     |> assign(:recent_transactions, get_recent_transactions())
     |> assign(:api_status, get_api_status())}
  end

  defp get_dashboard_stats do
    stats = Transactions.get_transaction_stats()

    %{
      total_amount: format_amount(stats.total_amount),
      successful_count: stats.successful_count,
      pending_count: stats.pending_count,
      failed_count: stats.failed_count
    }
  end

  defp get_recent_transactions do
    Transactions.list_transactions()
    |> Enum.take(10)
    |> Enum.map(fn transaction ->
      %{
        id: transaction.external_id,
        amount: format_currency(transaction.amount, transaction.currency),
        status: transaction.status,
        inserted_at: format_time_ago(transaction.inserted_at)
      }
    end)
  end

  defp get_api_status do
    # Mock data for now - we'll implement real API health checks later
    %{
      status: "healthy",
      response_time: "245ms",
      last_check: "30s ago"
    }
  end

  defp format_amount(nil), do: "$0"

  defp format_amount(amount) when is_struct(amount, Decimal) do
    "$#{Decimal.to_string(amount, :normal)}"
  end

  defp format_amount(amount), do: "$#{amount}"

  defp format_currency(amount, currency) do
    "#{currency} #{Decimal.to_string(amount, :normal)}"
  end

  defp format_time_ago(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end

  defp status_badge_class("completed"), do: "bg-green-500/20 text-green-300 border-green-400/30"
  defp status_badge_class("pending"), do: "bg-yellow-500/20 text-yellow-300 border-yellow-400/30"
  defp status_badge_class("failed"), do: "bg-red-500/20 text-red-300 border-red-400/30"
  defp status_badge_class(_), do: "bg-gray-500/20 text-gray-300 border-gray-400/30"

  defp status_text("completed"), do: "Completed"
  defp status_text("pending"), do: "Pending"
  defp status_text("failed"), do: "Failed"
  defp status_text(status), do: String.capitalize(status)
end
