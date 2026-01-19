defmodule FieldHub.CRM.Customer do
  @moduledoc """
  Customer schema representing a homeowner or business receiving service.

  Customers have service addresses, contact preferences, and can
  access their job status through a customer portal.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :slug}
  @contact_methods ~w(phone email sms)
  @state_code_regex ~r/^[A-Z]{2}$/
  @zip_code_regex ~r/^\d{5}(-\d{4})?$/

  schema "customers" do
    field :name, :string
    field :slug, :string
    field :email, :string
    field :phone, :string
    field :secondary_phone, :string
    field :notes, :string

    # Primary service address
    field :address_line1, :string
    field :address_line2, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :country, :string, default: "US"

    # Geolocation
    field :lat, :float
    field :lng, :float

    # Customer portal
    field :portal_token, :string
    field :portal_enabled, :boolean, default: true

    # Preferences
    field :preferred_contact, :string, default: "phone"
    field :gate_code, :string
    field :special_instructions, :string

    # Source tracking
    field :source, :string
    field :referred_by, :string

    # Soft delete
    field :archived_at, :utc_datetime

    field :custom_fields, :map, default: %{}

    # Associations
    belongs_to :organization, FieldHub.Accounts.Organization
    has_many :jobs, FieldHub.Jobs.Job

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for customer creation/update.
  """
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [
      :organization_id,
      :name,
      :slug,
      :email,
      :phone,
      :secondary_phone,
      :notes,
      :address_line1,
      :address_line2,
      :city,
      :state,
      :zip,
      :country,
      :lat,
      :lng,
      :portal_enabled,
      :preferred_contact,
      :gate_code,
      :special_instructions,
      :source,
      :referred_by,
      :archived_at,
      :custom_fields
    ])
    |> validate_required([:organization_id, :name])
    |> put_slug()
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "has invalid format")
    |> validate_inclusion(:preferred_contact, @contact_methods)
    |> validate_format(:state, @state_code_regex, message: "must be a 2-letter state code")
    |> validate_format(:zip, @zip_code_regex, message: "must be a valid ZIP code")
    |> foreign_key_constraint(:organization_id)
    |> unique_constraint([:portal_token])
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
  Generates a unique portal access token for the customer.
  """
  def generate_portal_token(customer) do
    token = :crypto.strong_rand_bytes(24) |> Base.url_encode64()
    change(customer, portal_token: token)
  end

  @doc """
  Returns a formatted full address string.

  ## Examples

      iex> Customer.full_address(%Customer{address_line1: "123 Main St", city: "NYC", state: "NY", zip: "10001"})
      "123 Main St, NYC, NY 10001"
  """
  def full_address(%__MODULE__{} = customer) do
    [
      customer.address_line1,
      customer.address_line2,
      customer.city,
      "#{customer.state} #{customer.zip}"
    ]
    |> Enum.filter(&(&1 && &1 != "" && &1 != " "))
    |> Enum.join(", ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
