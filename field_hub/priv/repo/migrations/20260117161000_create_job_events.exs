defmodule FieldHub.Repo.Migrations.CreateJobEvents do
  use Ecto.Migration

  def change do
    create table(:job_events) do
      add :job_id, references(:jobs, on_delete: :delete_all), null: false
      add :actor_id, references(:users, on_delete: :nilify_all)
      add :technician_id, references(:technicians, on_delete: :nilify_all)

      # "status_changed", "assigned", "note_added", etc.
      add :event_type, :string, null: false
      add :old_value, :map
      add :new_value, :map
      # GPS coords, device info, IP, etc.
      add :metadata, :map, default: %{}

      # Immutable - no updated_at
      add :inserted_at, :utc_datetime, null: false, default: fragment("NOW()")
    end

    create index(:job_events, [:job_id])
    create index(:job_events, [:job_id, :event_type])
    create index(:job_events, [:inserted_at])
  end
end
