defmodule FieldHub.Repo.Migrations.CreateTechnicians do
  use Ecto.Migration

  def change do
    create table(:technicians) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      add :name, :string, null: false
      add :email, :string
      add :phone, :string
      add :status, :string, default: "off_duty"
      add :color, :string, default: "#3B82F6"  # Blue
      add :avatar_url, :string

      # Skills and certifications
      add :skills, {:array, :string}, default: []
      add :certifications, {:array, :string}, default: []
      add :hourly_rate, :decimal

      # Real-time location (updated by mobile app)
      add :current_lat, :float
      add :current_lng, :float
      add :location_updated_at, :utc_datetime

      # Push notification tokens
      add :fcm_token, :string
      add :apns_token, :string

      # Auth (optional - technician can have their own login)
      add :user_id, references(:users, on_delete: :nilify_all)

      # Soft delete
      add :archived_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:technicians, [:organization_id])
    create index(:technicians, [:organization_id, :status])
    create index(:technicians, [:user_id])
    create unique_index(:technicians, [:organization_id, :email], where: "archived_at IS NULL")
  end
end
