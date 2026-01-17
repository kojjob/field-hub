defmodule FieldHub.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :phone, :string
      add :email, :string
      add :timezone, :string, default: "America/New_York"

      # Address
      add :address_line1, :string
      add :address_line2, :string
      add :city, :string
      add :state, :string
      add :zip, :string
      add :country, :string, default: "US"

      # Subscription
      add :subscription_tier, :string, default: "trial"
      add :subscription_status, :string, default: "trial"
      add :trial_ends_at, :utc_datetime
      add :stripe_customer_id, :string

      # Settings
      add :settings, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:slug])
    create index(:organizations, [:stripe_customer_id])

    # Add organization_id to users table
    alter table(:users) do
      add :organization_id, references(:organizations, on_delete: :delete_all)
      add :name, :string
      add :phone, :string
      add :role, :string, default: "viewer"
      add :avatar_url, :string
    end

    create index(:users, [:organization_id])
  end
end
