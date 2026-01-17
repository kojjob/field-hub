defmodule FieldHub.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      add :name, :string, null: false
      add :email, :string
      add :phone, :string
      add :secondary_phone, :string
      add :notes, :text

      # Primary service address
      add :address_line1, :string
      add :address_line2, :string
      add :city, :string
      add :state, :string
      add :zip, :string
      add :country, :string, default: "US"

      # Geolocation (set via geocoding)
      add :lat, :float
      add :lng, :float

      # Customer portal access
      add :portal_token, :string
      add :portal_enabled, :boolean, default: true

      # Preferences
      add :preferred_contact, :string, default: "phone"
      add :gate_code, :string
      add :special_instructions, :text

      # Source tracking
      # "referral", "google", "phone", etc.
      add :source, :string
      add :referred_by, :string

      # Soft delete
      add :archived_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:customers, [:organization_id])
    create index(:customers, [:organization_id, :email])
    create index(:customers, [:organization_id, :phone])
    create unique_index(:customers, [:portal_token], where: "portal_token IS NOT NULL")
  end
end
