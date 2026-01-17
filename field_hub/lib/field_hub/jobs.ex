defmodule FieldHub.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false
  alias FieldHub.Repo

  alias FieldHub.Jobs.Job
  alias FieldHub.Jobs.JobEvent
  alias FieldHub.Dispatch.Broadcaster
  alias Ecto.Multi

  @doc """
  Returns the list of jobs for an organization.

  ## Examples

      iex> list_jobs(org_id)
      [%Job{}, ...]

  """
  def list_jobs(org_id) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> order_by([j], desc: j.inserted_at)
    |> Repo.all()
    |> Repo.preload([:customer, :technician])
  end

  @doc """
  Returns the list of jobs scheduled for a specific date.

  ## Examples

      iex> list_jobs_for_date(org_id, ~D[2026-01-17])
      [%Job{}, ...]

  """
  def list_jobs_for_date(org_id, date) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], j.scheduled_date == ^date)
    |> where([j], not is_nil(j.technician_id))
    |> order_by([j], asc: j.scheduled_start)
    |> Repo.all()
    |> Repo.preload([:customer, :technician])
  end

  @doc """
  Returns the list of unassigned jobs (no technician or no scheduled date).

  ## Examples

      iex> list_unassigned_jobs(org_id)
      [%Job{}, ...]

  """
  def list_unassigned_jobs(org_id) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], is_nil(j.technician_id) or is_nil(j.scheduled_date))
    |> where([j], j.status not in ["completed", "cancelled"])
    |> order_by([j], [desc: fragment("CASE WHEN ? = 'urgent' THEN 0 WHEN ? = 'high' THEN 1 ELSE 2 END", j.priority, j.priority), asc: j.inserted_at])
    |> Repo.all()
    |> Repo.preload([:customer, :technician])
  end

  @doc """
  Gets a single job scoped to an organization.

  Raises `Ecto.NoResultsError` if the job does not exist
  or doesn't belong to the organization.

  ## Examples

      iex> get_job!(org_id, 123)
      %Job{}

      iex> get_job!(org_id, 456)
      ** (Ecto.NoResultsError)

  """
  def get_job!(org_id, id) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], j.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a job.

  Automatically generates a job number if not provided.

  ## Examples

      iex> create_job(org_id, %{field: value})
      {:ok, %Job{}}

      iex> create_job(org_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_job(org_id, attrs) do
    # Normalize to string keys to avoid mixed keys error
    attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
    attrs = Map.put_new(attrs, "number", Job.generate_job_number(org_id))
    job_changeset = %Job{organization_id: org_id} |> Job.changeset(attrs)

    Multi.new()
    |> Multi.insert(:job, job_changeset)
    |> Multi.insert(:event, fn %{job: job} ->
      JobEvent.build_event_changeset(job, "created", %{new_value: sanitize_attrs(attrs)})
    end)
    |> run_transaction()
    |> broadcast_job_created()
  end

  @doc """
  Updates a job.

  ## Examples

      iex> update_job(job, %{field: new_value})
      {:ok, %Job{}}

      iex> update_job(job, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_job(%Job{} = job, attrs) do
    Multi.new()
    |> Multi.update(:job, Job.changeset(job, attrs))
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "updated", %{
        old_value: sanitize_job(job),
        new_value: sanitize_job(updated_job)
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end



  @doc """
  Assigns a technician to a job.

  Updates the status to "dispatched".

  ## Examples

      iex> assign_job(job, technician_id)
      {:ok, %Job{}}

  """
  def assign_job(%Job{} = job, technician_id) do
    Multi.new()
    |> Multi.update(:job, Job.assign_changeset(job, technician_id))
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "assigned", %{
        technician_id: technician_id,
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end

  @doc """
  Schedules a job.

  Updates status to "scheduled" if valid.
  """
  def schedule_job(%Job{} = job, attrs) do
    Multi.new()
    |> Multi.update(:job, Job.schedule_changeset(job, attrs))
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "scheduled", %{
        old_value: %{scheduled_date: job.scheduled_date, scheduled_start: job.scheduled_start},
        new_value: %{scheduled_date: updated_job.scheduled_date, scheduled_start: updated_job.scheduled_start}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end

  @doc """
  Updates job status to "en_route" and sets travel start time.
  """
  def start_travel(%Job{} = job) do
    Multi.new()
    |> Multi.update(:job, Job.start_travel_changeset(job))
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "travel_started", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end

  @doc """
  Updates job status to "on_site" and sets arrival time.
  """
  def arrive_on_site(%Job{} = job) do
    Multi.new()
    |> Multi.update(:job, Job.arrive_changeset(job))
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "arrived", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end

  @doc """
  Updates job status to "in_progress" and sets start time.
  """
  def start_work(%Job{} = job) do
    Multi.new()
    |> Multi.update(:job, Job.start_work_changeset(job))
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "work_started", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end

  @doc """
  Completes a job with required details.
  """
  def complete_job(%Job{} = job, attrs) do
    Multi.new()
    |> Multi.update(:job, Job.complete_changeset(job, attrs))
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "completed", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end

  @doc """
  Cancels a job with a reason.
  """
  def cancel_job(%Job{} = job, reason) do
    Multi.new()
    |> Multi.update(:job, Job.cancel_changeset(job, reason))
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "cancelled", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status},
        metadata: %{reason: reason}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end

  @doc """
  Deletes a job.

  ## Examples

      iex> delete_job(job)
      {:ok, %Job{}}

      iex> delete_job(job)
      {:error, %Ecto.Changeset{}}

  """
  def delete_job(%Job{} = job) do
    Repo.delete(job)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job changes.

  ## Examples

      iex> change_job(job)
      %Ecto.Changeset{data: %Job{}}

  """
  def change_job(%Job{} = job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end

  defp run_transaction(multi) do
    case Repo.transaction(multi) do
      {:ok, %{job: job}} -> {:ok, job}
      {:error, :job, changeset, _} -> {:error, changeset}
      {:error, :event, changeset, _} -> {:error, changeset}
      {:error, _, failed_value, _} -> {:error, failed_value}
    end
  end

  defp sanitize_attrs(attrs) when is_map(attrs) do
    # Remove large fields or structs if necessary, for now just pass through
    # Could convert structs to maps to be safe for Ecto casting
    Map.drop(attrs, [:__struct__, :__meta__])
  end

  def sanitize_job(job) do
     # Extract relevant audit fields
     Map.take(job, [:title, :description, :status, :technician_id, :scheduled_date, :scheduled_start, :scheduled_end, :internal_notes])
  end

  defp broadcast_job_created({:ok, job}) do
    Broadcaster.broadcast_job_created(job)
    {:ok, job}
  end
  defp broadcast_job_created(error), do: error

  defp broadcast_job_updated({:ok, job}) do
    Broadcaster.broadcast_job_updated(job)
    {:ok, job}
  end
  defp broadcast_job_updated(error), do: error
end
