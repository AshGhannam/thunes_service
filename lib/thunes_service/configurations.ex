defmodule ThunesService.Configurations do
  @moduledoc """
  The Configurations context for managing Thunes API settings.
  """

  import Ecto.Query, warn: false
  alias ThunesService.Repo
  alias ThunesService.Configurations.ThunesConfiguration

  @doc """
  Returns the list of thunes_configurations.
  """
  def list_thunes_configurations do
    Repo.all(ThunesConfiguration)
  end

  @doc """
  Gets a single thunes_configuration.
  """
  def get_thunes_configuration!(id), do: Repo.get!(ThunesConfiguration, id)

  @doc """
  Gets the active configuration.
  """
  def get_active_configuration do
    Repo.one(from c in ThunesConfiguration, where: c.is_active == true, limit: 1)
  end

  @doc """
  Creates a thunes_configuration.
  """
  def create_thunes_configuration(attrs \\ %{}) do
    %ThunesConfiguration{}
    |> ThunesConfiguration.changeset(attrs)
    |> maybe_deactivate_others()
    |> Repo.transaction(fn repo ->
      case repo.insert(changeset) do
        {:ok, config} ->
          if config.is_active do
            deactivate_all_except(config.id)
          end

          config

        {:error, changeset} ->
          repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, config} -> {:ok, config}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Updates a thunes_configuration.
  """
  def update_thunes_configuration(%ThunesConfiguration{} = thunes_configuration, attrs) do
    changeset = ThunesConfiguration.changeset(thunes_configuration, attrs)

    Repo.transaction(fn repo ->
      case repo.update(changeset) do
        {:ok, config} ->
          if config.is_active do
            deactivate_all_except(config.id)
          end

          config

        {:error, changeset} ->
          repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, config} -> {:ok, config}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a thunes_configuration.
  """
  def delete_thunes_configuration(%ThunesConfiguration{} = thunes_configuration) do
    Repo.delete(thunes_configuration)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking thunes_configuration changes.
  """
  def change_thunes_configuration(%ThunesConfiguration{} = thunes_configuration, attrs \\ %{}) do
    ThunesConfiguration.changeset(thunes_configuration, attrs)
  end

  @doc """
  Activates a configuration and deactivates all others.
  """
  def activate_configuration(id) do
    config = get_thunes_configuration!(id)
    update_thunes_configuration(config, %{is_active: true})
  end

  defp deactivate_all_except(id) do
    from(c in ThunesConfiguration, where: c.id != ^id)
    |> Repo.update_all(set: [is_active: false])
  end

  defp maybe_deactivate_others(changeset) do
    if Ecto.Changeset.get_change(changeset, :is_active) == true do
      deactivate_all_except(nil)
    end

    changeset
  end
end
