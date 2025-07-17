defmodule ThunesServiceWeb.DashboardLive do
  use ThunesServiceWeb, :live_view

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
  def handle_info({:transaction_updated, transaction}, socket) do
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
    # Mock data for now - we'll implement real queries later
    %{
      total_amount: "24,589",
      successful_count: 156,
      pending_count: 8,
      failed_count: 3
    }
  end

  defp get_recent_transactions do
    # Mock data for now - we'll implement real queries later
    [
      %{
        id: "TXN-001",
        amount: "$1,250.00",
        status: "completed",
        inserted_at: "2 min ago"
      },
      %{
        id: "TXN-002",
        amount: "$850.50",
        status: "pending",
        inserted_at: "5 min ago"
      },
      %{
        id: "TXN-003",
        amount: "$2,100.00",
        status: "completed",
        inserted_at: "12 min ago"
      }
    ]
  end

  defp get_api_status do
    # Mock data for now - we'll implement real API health checks later
    %{
      status: "healthy",
      response_time: "245ms",
      last_check: "30s ago"
    }
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
