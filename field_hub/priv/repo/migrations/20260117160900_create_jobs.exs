defmodule FieldHub.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :customer_id, references(:customers, on_delete: :nilify_all)
      add :technician_id, references(:technicians, on_delete: :nilify_all)
      add :created_by_id, references(:users, on_delete: :nilify_all)

      # Job identification
      add :number, :string, null: false
      add :title, :string, null: false
      add :description, :text

      # Classification
      add :job_type, :string, default: "service_call"
      add :priority, :string, default: "normal"
      add :status, :string, default: "unscheduled"

      # Scheduling
      add :scheduled_date, :date
      add :scheduled_start, :time
      add :scheduled_end, :time
      add :estimated_duration_minutes, :integer, default: 60
      add :arrival_window_start, :time
      add :arrival_window_end, :time

      # Actual times
      add :travel_started_at, :utc_datetime
      add :arrived_at, :utc_datetime
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime

      # Service location (can differ from customer primary address)
      add :service_address, :string
      add :service_city, :string
      add :service_state, :string
      add :service_zip, :string
      add :service_lat, :float
      add :service_lng, :float

      # Work details
      add :work_performed, :text
      add :technician_notes, :text
      add :internal_notes, :text
      add :equipment_used, {:array, :string}, default: []

      # Financial
      add :quoted_amount, :decimal
      add :actual_amount, :decimal
      add :payment_status, :string, default: "pending"
      add :payment_method, :string
      add :payment_collected_at, :utc_datetime
      add :invoice_id, :string

      # Completion
      add :customer_signature, :text  # Base64 encoded
      add :photos, {:array, :string}, default: []
      add :completed_by_id, references(:technicians, on_delete: :nilify_all)

      # Recurring job reference
      add :recurring_job_id, :integer
      add :recurrence_rule, :string  # iCal RRULE format

      # Metadata
      add :tags, {:array, :string}, default: []
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    # Primary indexes for dashboard queries
    create index(:jobs, [:organization_id, :scheduled_date, :status])
    create index(:jobs, [:organization_id, :status])
    create index(:jobs, [:technician_id, :scheduled_date])
    create index(:jobs, [:customer_id])
    create index(:jobs, [:created_by_id])
    create unique_index(:jobs, [:organization_id, :number])

    # Job number sequence per organization
    execute """
    CREATE SEQUENCE IF NOT EXISTS job_number_seq START 1000;
    """, """
    DROP SEQUENCE IF EXISTS job_number_seq;
    """
  end
end
