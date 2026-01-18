defmodule FieldHub.Jobs.Job do
  @moduledoc """
  Job schema representing a work order.

  Jobs are the core unit of work, tracking the full lifecycle
  from creation through scheduling, dispatch, and completion.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @job_types ~w(service_call installation maintenance emergency estimate)
  @priorities ~w(low normal high urgent)
  @statuses ~w(unscheduled scheduled dispatched en_route on_site in_progress completed cancelled on_hold)
  @payment_statuses ~w(pending invoiced paid refunded)

  schema "jobs" do
    field :number, :string
    field :title, :string
    field :description, :string

    # Classification
    field :job_type, :string, default: "service_call"
    field :priority, :string, default: "normal"
    field :status, :string, default: "unscheduled"

    # Scheduling
    field :scheduled_date, :date
    field :scheduled_start, :time
    field :scheduled_end, :time
    field :estimated_duration_minutes, :integer, default: 60
    field :arrival_window_start, :time
    field :arrival_window_end, :time

    # Actual times
    field :travel_started_at, :utc_datetime
    field :arrived_at, :utc_datetime
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    # Service location
    field :service_address, :string
    field :service_city, :string
    field :service_state, :string
    field :service_zip, :string
    field :service_lat, :float
    field :service_lng, :float

    # Work details
    field :work_performed, :string
    field :technician_notes, :string
    field :internal_notes, :string
    field :equipment_used, {:array, :string}, default: []

    # Financial
    field :quoted_amount, :decimal
    field :actual_amount, :decimal
    field :payment_status, :string, default: "pending"
    field :payment_method, :string
    field :payment_collected_at, :utc_datetime
    field :invoice_id, :string

    # Completion
    field :customer_signature, :string
    field :photos, {:array, :string}, default: []

    # Recurring
    field :recurring_job_id, :integer
    field :recurrence_rule, :string

    # Metadata
    field :tags, {:array, :string}, default: []
    field :metadata, :map, default: %{}
    field :custom_fields, :map, default: %{}

    # Associations
    belongs_to :organization, FieldHub.Accounts.Organization
    belongs_to :customer, FieldHub.CRM.Customer
    belongs_to :technician, FieldHub.Dispatch.Technician
    belongs_to :created_by, FieldHub.Accounts.User
    belongs_to :completed_by, FieldHub.Dispatch.Technician

    has_many :job_events, FieldHub.Jobs.JobEvent

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for job creation/update.
  """
  def changeset(job, attrs) do
    job
    |> cast(attrs, [
      :organization_id,
      :customer_id,
      :technician_id,
      :created_by_id,
      :number,
      :title,
      :description,
      :job_type,
      :priority,
      :status,
      :scheduled_date,
      :scheduled_start,
      :scheduled_end,
      :estimated_duration_minutes,
      :arrival_window_start,
      :arrival_window_end,
      :service_address,
      :service_city,
      :service_state,
      :service_zip,
      :service_lat,
      :service_lng,
      :work_performed,
      :technician_notes,
      :internal_notes,
      :equipment_used,
      :quoted_amount,
      :actual_amount,
      :payment_status,
      :payment_method,
      :invoice_id,
      :customer_signature,
      :photos,
      :recurring_job_id,
      :recurrence_rule,
      :tags,
      :metadata,
      :custom_fields
    ])
    |> validate_required([:organization_id, :title, :number])
    |> validate_inclusion(:job_type, @job_types)
    |> validate_inclusion(:priority, @priorities)
    |> validate_status()
    |> validate_inclusion(:payment_status, @payment_statuses)
    |> validate_number(:estimated_duration_minutes, greater_than: 0)
    |> validate_number(:quoted_amount, greater_than_or_equal_to: 0)
    |> validate_number(:actual_amount, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:technician_id)
    |> unique_constraint([:organization_id, :number])
  end

  @doc """
  Changeset for scheduling a job.
  """
  def schedule_changeset(job, attrs) do
    job
    |> cast(attrs, [:scheduled_date, :scheduled_start, :scheduled_end])
    |> validate_required([:scheduled_date])
    |> validate_end_after_start()
    |> maybe_update_status("scheduled")
  end

  @doc """
  Changeset for assigning a technician to a job.
  """
  def assign_changeset(job, technician_id) do
    job
    |> change(technician_id: technician_id)
    |> maybe_update_status("dispatched")
  end

  @doc """
  Changeset for technician starting travel.
  """
  def start_travel_changeset(job) do
    job
    |> change(
      status: "en_route",
      travel_started_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  @doc """
  Changeset for technician arriving on site.
  """
  def arrive_changeset(job) do
    job
    |> change(
      status: "on_site",
      arrived_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  @doc """
  Changeset for technician starting work.
  """
  def start_work_changeset(job) do
    job
    |> change(
      status: "in_progress",
      started_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  @doc """
  Changeset for completing a job.
  """
  def complete_changeset(job, attrs) do
    job
    |> cast(attrs, [
      :work_performed,
      :actual_amount,
      :completed_by_id,
      :customer_signature,
      :photos
    ])
    |> validate_required([:work_performed])
    |> change(
      status: "completed",
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  @doc """
  Changeset for cancelling a job.
  """
  def cancel_changeset(job, reason \\ nil) do
    job
    |> change(status: "cancelled")
    |> put_change(:internal_notes, build_cancel_notes(job.internal_notes, reason))
  end

  @doc """
  Generates a unique job number for an organization.

  Format: JOB-YYYY-XXXXX where XXXXX is a sequential number.
  """
  def generate_job_number(_org_id) do
    year = Date.utc_today().year

    # TODO: Use database sequence for uniqueness per organization
    # In production, this should query a sequence like:
    # Repo.query!("SELECT nextval('job_number_seq_#{org_id}')")
    random_suffix = :rand.uniform(99999) |> Integer.to_string() |> String.pad_leading(5, "0")

    "JOB-#{year}-#{random_suffix}"
  end

  @doc """
  Returns list of valid statuses.
  For backward compatibility, returns default statuses.
  Use statuses/1 with an organization for dynamic statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns list of valid statuses for an organization.
  Includes both default and custom statuses configured for the org.
  """
  def statuses(nil), do: @statuses

  def statuses(org) do
    custom_keys =
      org
      |> FieldHub.Config.Workflows.get_statuses()
      |> Enum.map(fn status -> Map.get(status, :key) || Map.get(status, "key") end)

    Enum.uniq(@statuses ++ custom_keys)
  end

  # Validates status - accepts both default and custom statuses
  defp validate_status(changeset) do
    status = get_field(changeset, :status)
    org_id = get_field(changeset, :organization_id)

    # Build list of valid statuses
    valid_statuses =
      if org_id do
        # Try to get org and its custom statuses
        case FieldHub.Accounts.get_organization(org_id) do
          {:ok, org} -> statuses(org)
          _ -> @statuses
        end
      else
        @statuses
      end

    if status && status not in valid_statuses do
      add_error(changeset, :status, "is invalid")
    else
      changeset
    end
  end

  @doc """
  Returns list of valid job types.
  """
  def job_types, do: @job_types

  @doc """
  Returns list of valid priorities.
  """
  def priorities, do: @priorities

  # Private functions

  defp validate_end_after_start(changeset) do
    start_time = get_field(changeset, :scheduled_start)
    end_time = get_field(changeset, :scheduled_end)

    if start_time && end_time && Time.compare(end_time, start_time) != :gt do
      add_error(changeset, :scheduled_end, "must be after start time")
    else
      changeset
    end
  end

  defp maybe_update_status(changeset, new_status) do
    current_status = get_field(changeset, :status)

    if current_status in ["unscheduled", "scheduled"] do
      put_change(changeset, :status, new_status)
    else
      changeset
    end
  end

  defp build_cancel_notes(existing_notes, nil), do: existing_notes
  defp build_cancel_notes(nil, reason), do: "Cancelled: #{reason}"
  defp build_cancel_notes(existing, reason), do: "#{existing}\n\nCancelled: #{reason}"
end
