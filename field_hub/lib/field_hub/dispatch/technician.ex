defmodule FieldHub.Dispatch.Technician do
  @moduledoc """
  Technician schema representing a field service worker.

  Technicians are assigned to jobs and tracked in real-time
  with GPS location, status updates, and skill matching.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(available on_job traveling en_route on_site busy break off_duty)
  @hex_color_regex ~r/^#[0-9A-Fa-f]{6}$/

  @derive {Phoenix.Param, key: :slug}
  schema "technicians" do
    field :name, :string
    field :slug, :string
    field :email, :string
    field :phone, :string
    field :status, :string, default: "off_duty"
    field :color, :string, default: "#3B82F6"
    field :avatar_url, :string

    # Skills and certifications
    field :skills, {:array, :string}, default: []
    field :certifications, {:array, :string}, default: []
    field :hourly_rate, :decimal

    # Real-time location
    field :current_lat, :float
    field :current_lng, :float
    field :location_updated_at, :utc_datetime

    # Push notification tokens
    field :fcm_token, :string
    field :apns_token, :string

    # Soft delete
    field :archived_at, :utc_datetime
    field :custom_fields, :map, default: %{}

    # Associations
    belongs_to :organization, FieldHub.Accounts.Organization
    belongs_to :user, FieldHub.Accounts.User
    has_many :jobs, FieldHub.Jobs.Job

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for technician creation/update.
  """
  def changeset(technician, attrs) do
    technician
    |> cast(attrs, [
      :organization_id,
      :user_id,
      :name,
      :slug,
      :email,
      :phone,
      :status,
      :color,
      :avatar_url,
      :skills,
      :certifications,
      :hourly_rate,
      :fcm_token,
      :apns_token,
      :archived_at,
      :custom_fields
    ])
    |> validate_required([:organization_id, :name])
    |> put_slug()
    |> validate_inclusion(:status, @statuses)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "has invalid format")
    |> validate_format(:color, @hex_color_regex, message: "must be a valid hex color code")
    |> validate_number(:hourly_rate, greater_than: 0)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:email, name: :technicians_organization_id_email_index)
    |> unique_constraint([:organization_id, :slug])
  end

  defp put_slug(changeset) do
    name = get_field(changeset, :name)
    slug = get_field(changeset, :slug)

    if name && (is_nil(slug) || slug == "") do
      put_change(changeset, :slug, generate_slug(name))
    else
      case get_change(changeset, :name) do
        nil ->
          changeset

        name ->
          put_change(changeset, :slug, generate_slug(name))
      end
    end
  end

  defp generate_slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  @doc """
  Changeset for updating technician location from GPS.
  """
  def location_changeset(technician, attrs) do
    technician
    |> cast(attrs, [:current_lat, :current_lng])
    |> validate_number(:current_lat,
      greater_than_or_equal_to: -90,
      less_than_or_equal_to: 90,
      message: "must be between -90 and 90"
    )
    |> validate_number(:current_lng,
      greater_than_or_equal_to: -180,
      less_than_or_equal_to: 180,
      message: "must be between -180 and 180"
    )
    |> put_change(:location_updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for updating technician status.
  """
  def status_changeset(technician, new_status) when new_status in @statuses do
    technician
    |> change(status: new_status)
  end

  def status_changeset(_technician, _invalid_status) do
    %Ecto.Changeset{valid?: false, errors: [status: {"is invalid", []}]}
  end

  @doc """
  Returns list of valid statuses.
  """
  def statuses, do: @statuses
end
