defmodule ThunesService.Configurations.ThunesConfiguration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "thunes_configurations" do
    field :name, :string
    field :api_key, :string
    field :api_secret, :string
    field :base_url, :string
    field :is_sandbox, :boolean, default: true
    field :is_active, :boolean, default: false
    field :description, :string
    field :timeout_ms, :integer, default: 30000

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(thunes_configuration, attrs) do
    thunes_configuration
    |> cast(attrs, [
      :name,
      :api_key,
      :api_secret,
      :base_url,
      :is_sandbox,
      :is_active,
      :description,
      :timeout_ms
    ])
    |> validate_required([:name, :api_key, :api_secret, :base_url])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:api_key, min: 10)
    |> validate_length(:api_secret, min: 10)
    |> validate_format(:base_url, ~r/^https?:\/\//,
      message: "must be a valid URL starting with http:// or https://"
    )
    |> validate_number(:timeout_ms, greater_than: 1000, less_than: 300_000)
    |> unique_constraint(:name)
    |> validate_only_one_active()
  end

  defp validate_only_one_active(changeset) do
    if get_change(changeset, :is_active) == true do
      # This will be handled at the context level to ensure atomicity
      changeset
    else
      changeset
    end
  end
end
