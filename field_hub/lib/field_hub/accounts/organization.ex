defmodule FieldHub.Accounts.Organization do
  @moduledoc """
  Organization schema representing a contractor business.

  Organizations are the multi-tenant container for all data.
  Each contractor company has one organization with their own
  users, technicians, customers, and jobs.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @subscription_tiers ~w(trial starter growth pro)
  @subscription_statuses ~w(trial active past_due cancelled)

  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :phone, :string
    field :email, :string
    field :timezone, :string, default: "America/New_York"

    # Address
    field :address_line1, :string
    field :address_line2, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :country, :string, default: "US"

    # Subscription
    field :subscription_tier, :string, default: "trial"
    field :subscription_status, :string, default: "trial"
    field :trial_ends_at, :utc_datetime
    field :stripe_customer_id, :string

    # Settings
    field :settings, :map, default: %{}

    # Industry-Agnostic Terminology
    field :terminology, :map, default: %{
      "worker_label" => "Technician",
      "worker_label_plural" => "Technicians",
      "client_label" => "Customer",
      "client_label_plural" => "Customers",
      "task_label" => "Job",
      "task_label_plural" => "Jobs",
      "dispatch_label" => "Dispatch"
    }

    # White-Label Branding
    field :brand_name, :string
    field :logo_url, :string
    field :primary_color, :string, default: "#3B82F6"
    field :secondary_color, :string, default: "#1E40AF"

    # Associations
    has_many :users, FieldHub.Accounts.User
    has_many :technicians, FieldHub.Dispatch.Technician
    has_many :customers, FieldHub.CRM.Customer
    has_many :jobs, FieldHub.Jobs.Job

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for organization creation/update.
  """
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [
      :name,
      :slug,
      :phone,
      :email,
      :timezone,
      :address_line1,
      :address_line2,
      :city,
      :state,
      :zip,
      :country,
      :subscription_tier,
      :subscription_status,
      :trial_ends_at,
      :stripe_customer_id,
      :settings,
      :terminology,
      :brand_name,
      :logo_url,
      :primary_color,
      :secondary_color
    ])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase alphanumeric with hyphens"
    )
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "has invalid format")
    |> validate_inclusion(:subscription_tier, @subscription_tiers)
    |> validate_inclusion(:subscription_status, @subscription_statuses)
    |> unique_constraint(:slug)
  end

  @doc """
  Generates a URL-safe slug from an organization name.

  ## Examples

      iex> Organization.generate_slug("Ace HVAC Services")
      "ace-hvac-services"

      iex> Organization.generate_slug("Bob's Plumbing & Heating")
      "bobs-plumbing-heating"
  """
  def generate_slug(name) when is_binary(name) do
    name
    |> String.downcase()
    # Remove special chars except spaces and hyphens
    |> String.replace(~r/[^\w\s-]/, "")
    # Replace spaces with hyphens
    |> String.replace(~r/\s+/, "-")
    # Collapse multiple hyphens
    |> String.replace(~r/-+/, "-")
    # Remove leading/trailing hyphens
    |> String.trim("-")
  end

  def generate_slug(_), do: ""
end
