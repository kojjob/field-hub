defmodule FieldHub.Jobs.JobEvent do
  @moduledoc """
  JobEvent schema for immutable job audit trail.

  Every action on a job creates an event, providing a complete
  history of what happened, when, and by whom.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias FieldHub.Repo

  @event_types ~w(
    created updated status_changed assigned unassigned
    scheduled rescheduled note_added photo_added
    signature_captured payment_collected
  )

  schema "job_events" do
    field :event_type, :string
    field :old_value, :map
    field :new_value, :map
    field :metadata, :map, default: %{}

    belongs_to :job, FieldHub.Jobs.Job
    belongs_to :actor, FieldHub.Accounts.User
    belongs_to :technician, FieldHub.Dispatch.Technician

    # Immutable - only inserted_at, no updated_at
    field :inserted_at, :utc_datetime
  end

  @doc """
  Creates a changeset for job event creation.
  """
  def changeset(job_event, attrs) do
    job_event
    |> cast(attrs, [
      :job_id,
      :actor_id,
      :technician_id,
      :event_type,
      :old_value,
      :new_value,
      :metadata
    ])
    |> validate_required([:job_id, :event_type])
    |> validate_inclusion(:event_type, @event_types)
    |> put_timestamp()
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:actor_id)
    |> foreign_key_constraint(:technician_id)
  end

  @doc """
  Creates a new job event and inserts it into the database.
  """
  def create_event(job, event_type, attrs \\ %{}) do
    metadata = Map.get(attrs, :metadata, %{}) |> stringify_keys()

    %__MODULE__{}
    |> changeset(
      Map.merge(attrs, %{
        job_id: job.id,
        event_type: event_type,
        old_value: Map.get(attrs, :old_value),
        new_value: Map.get(attrs, :new_value),
        metadata: metadata
      })
    )
    |> Repo.insert()
  end

  # Convert atom keys to strings for consistent access
  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  @doc """
  Returns a query for all events for a given job, ordered chronologically.
  """
  def for_job(job_id) do
    from e in __MODULE__,
      where: e.job_id == ^job_id,
      order_by: [asc: e.inserted_at, asc: e.id]
  end

  @doc """
  Returns list of valid event types.
  """
  def event_types, do: @event_types

  # Private functions

  defp put_timestamp(changeset) do
    put_change(changeset, :inserted_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
