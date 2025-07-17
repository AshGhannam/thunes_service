defmodule ThunesServiceWeb.ConfigLive do
  use ThunesServiceWeb, :live_view

  alias ThunesService.Configurations
  alias ThunesService.Configurations.ThunesConfiguration

  @impl true
  def mount(_params, _session, socket) do
    configurations = Configurations.list_thunes_configurations()

    socket =
      socket
      |> assign(:page_title, "Configuration Management")
      |> assign(:current_scope, socket.assigns[:current_scope])
      |> assign(:configurations, configurations)
      |> assign(:show_form, false)
      |> assign(:editing_config, nil)
      |> assign(
        :form,
        to_form(Configurations.change_thunes_configuration(%ThunesConfiguration{}))
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("new_config", _params, socket) do
    changeset = Configurations.change_thunes_configuration(%ThunesConfiguration{})

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing_config, nil)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("edit_config", %{"id" => id}, socket) do
    config = Configurations.get_thunes_configuration!(id)
    changeset = Configurations.change_thunes_configuration(config)

    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing_config, config)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:editing_config, nil)
     |> assign(:form, to_form(Configurations.change_thunes_configuration(%ThunesConfiguration{})))}
  end

  @impl true
  def handle_event("validate", %{"thunes_configuration" => config_params}, socket) do
    config = socket.assigns.editing_config || %ThunesConfiguration{}
    changeset = Configurations.change_thunes_configuration(config, config_params)

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"thunes_configuration" => config_params}, socket) do
    case socket.assigns.editing_config do
      nil ->
        case Configurations.create_thunes_configuration(config_params) do
          {:ok, _config} ->
            {:noreply,
             socket
             |> put_flash(:info, "Configuration created successfully!")
             |> assign(:show_form, false)
             |> assign(:configurations, Configurations.list_thunes_configurations())
             |> assign(
               :form,
               to_form(Configurations.change_thunes_configuration(%ThunesConfiguration{}))
             )}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end

      config ->
        case Configurations.update_thunes_configuration(config, config_params) do
          {:ok, _config} ->
            {:noreply,
             socket
             |> put_flash(:info, "Configuration updated successfully!")
             |> assign(:show_form, false)
             |> assign(:editing_config, nil)
             |> assign(:configurations, Configurations.list_thunes_configurations())
             |> assign(
               :form,
               to_form(Configurations.change_thunes_configuration(%ThunesConfiguration{}))
             )}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
    end
  end

  @impl true
  def handle_event("activate_config", %{"id" => id}, socket) do
    case Configurations.activate_configuration(id) do
      {:ok, _config} ->
        {:noreply,
         socket
         |> put_flash(:info, "Configuration activated successfully!")
         |> assign(:configurations, Configurations.list_thunes_configurations())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to activate configuration")}
    end
  end

  @impl true
  def handle_event("delete_config", %{"id" => id}, socket) do
    config = Configurations.get_thunes_configuration!(id)

    case Configurations.delete_thunes_configuration(config) do
      {:ok, _config} ->
        {:noreply,
         socket
         |> put_flash(:info, "Configuration deleted successfully!")
         |> assign(:configurations, Configurations.list_thunes_configurations())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete configuration")}
    end
  end

  defp config_status_badge(true), do: "bg-green-500/20 text-green-300 border-green-400/30"
  defp config_status_badge(false), do: "bg-gray-500/20 text-gray-300 border-gray-400/30"

  defp config_status_text(true), do: "Active"
  defp config_status_text(false), do: "Inactive"

  defp sandbox_badge(true), do: "bg-yellow-500/20 text-yellow-300 border-yellow-400/30"
  defp sandbox_badge(false), do: "bg-blue-500/20 text-blue-300 border-blue-400/30"

  defp sandbox_text(true), do: "Sandbox"
  defp sandbox_text(false), do: "Production"
end
