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
  Searches jobs by number, title, or status.
  """
  def search_jobs(org_id, search_term) do
    search = "%#{search_term}%"

    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], ilike(j.number, ^search) or ilike(j.title, ^search) or ilike(j.status, ^search))
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
  Returns the list of jobs assigned to a technician for a specific date.
  """
  def list_jobs_for_technician(technician_id, date) do
    Job
    |> where([j], j.technician_id == ^technician_id)
    |> where([j], j.scheduled_date == ^date)
    |> order_by([j], asc: j.scheduled_start)
    |> Repo.all()
    |> Repo.preload([:customer])
  end

  @doc """
  Returns the list of jobs for a customer, ordered by newest first.
  """
  def list_jobs_for_customer(org_id, customer_id) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], j.customer_id == ^customer_id)
    |> order_by([j], desc: j.inserted_at)
    |> Repo.all()
    |> Repo.preload([:technician])
  end

  @doc """
  Returns active (non-completed, non-cancelled) jobs for a customer.
  Used by the customer portal.
  """
  def list_active_jobs_for_customer(customer_id) do
    Job
    |> where([j], j.customer_id == ^customer_id)
    |> where([j], j.status not in ["completed", "cancelled"])
    |> order_by([j], asc: j.scheduled_date)
    |> Repo.all()
    |> Repo.preload([:technician, :customer])
  end

  @doc """
  Counts jobs by status for an organization.
  """
  def count_jobs_by_status(org_id, statuses) when is_list(statuses) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], j.status in ^statuses)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Counts active jobs for an organization.
  """
  def count_active_jobs(org_id) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], j.status not in ["completed", "cancelled"])
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns completed jobs for a customer with an optional limit.
  Used by the customer portal.
  """
  def list_completed_jobs_for_customer(customer_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    Job
    |> where([j], j.customer_id == ^customer_id)
    |> where([j], j.status == "completed")
    |> order_by([j], desc: j.completed_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:technician, :customer])
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
    |> order_by([j],
      desc:
        fragment(
          "CASE WHEN ? = 'urgent' THEN 0 WHEN ? = 'high' THEN 1 ELSE 2 END",
          j.priority,
          j.priority
        ),
      asc: j.inserted_at
    )
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
  Gets a single job by its number scoped to an organization.
  """
  def get_job_by_number!(org_id, number) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], j.number == ^number)
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

    # Geocode address if lat/lng not provided
    attrs = FieldHub.Geo.maybe_geocode_job_attrs(attrs)

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
    # Normalize to string keys
    attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}

    # Re-geocode if address changed
    attrs = maybe_regeocode_on_update(job, attrs)

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

  # Only geocode if address fields changed
  defp maybe_regeocode_on_update(job, attrs) do
    address_changed? =
      Enum.any?(~w(service_address service_city service_state service_zip), fn key ->
        new_val = Map.get(attrs, key)
        old_val = Map.get(job, String.to_existing_atom(key))
        new_val != nil and new_val != old_val
      end)

    if address_changed? do
      FieldHub.Geo.maybe_geocode_job_attrs(attrs)
    else
      attrs
    end
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
    |> notify_job_dispatched()
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
        new_value: %{
          scheduled_date: updated_job.scheduled_date,
          scheduled_start: updated_job.scheduled_start
        }
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
    |> notify_job_scheduled()
  end

  @doc """
  Updates job status to "en_route" and sets travel start time.
  """
  def start_travel(%Job{} = job) do
    Multi.new()
    |> Multi.update(:job, Job.start_travel_changeset(job))
    |> Multi.run(:tech_status, fn repo, %{job: updated_job} ->
      update_tech_status(repo, updated_job, "en_route")
    end)
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "travel_started", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
    |> notify_job_dispatched()
    |> notify_technician_en_route()
  end

  @doc """
  Updates job status to "on_site" and sets arrival time.
  """
  def arrive_on_site(%Job{} = job) do
    Multi.new()
    |> Multi.update(:job, Job.arrive_changeset(job))
    |> Multi.run(:tech_status, fn repo, %{job: updated_job} ->
      update_tech_status(repo, updated_job, "on_site")
    end)
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "arrived", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
    |> notify_technician_arrived()
  end

  @doc """
  Updates job status to "in_progress" and sets start time.
  """
  def start_work(%Job{} = job) do
    Multi.new()
    |> Multi.update(:job, Job.start_work_changeset(job))
    |> Multi.run(:tech_status, fn repo, %{job: updated_job} ->
      update_tech_status(repo, updated_job, "busy")
    end)
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "work_started", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
  end

  defp update_tech_status(repo, job, status) do
    if job.technician_id do
      case repo.get(FieldHub.Dispatch.Technician, job.technician_id) do
        nil ->
          {:ok, nil}

        tech ->
          tech
          |> FieldHub.Dispatch.Technician.status_changeset(status)
          |> repo.update()
      end
    else
      {:ok, nil}
    end
  end

  @doc """
  Completes a job with required details.
  """
  def complete_job(%Job{} = job, attrs) do
    Multi.new()
    |> Multi.update(:job, Job.complete_changeset(job, attrs))
    |> Multi.run(:tech_status, fn repo, %{job: updated_job} ->
      update_tech_status(repo, updated_job, "available")
    end)
    |> Multi.insert(:event, fn %{job: updated_job} ->
      JobEvent.build_event_changeset(updated_job, "completed", %{
        old_value: %{status: job.status},
        new_value: %{status: updated_job.status}
      })
    end)
    |> run_transaction()
    |> broadcast_job_updated()
    |> notify_job_completed()
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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job completion changes.
  """
  def change_complete_job(%Job{} = job, attrs \\ %{}) do
    Job.complete_changeset(job, attrs)
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
    Map.take(job, [
      :title,
      :description,
      :status,
      :technician_id,
      :scheduled_date,
      :scheduled_start,
      :scheduled_end,
      :internal_notes
    ])
  end

  defp broadcast_job_created({:ok, job}) do
    Broadcaster.broadcast_job_created(job)

    # Send confirmation if it's already scheduled or has a customer
    if job.customer_id do
      FieldHub.Jobs.JobNotifier.deliver_job_confirmation(job)
    end

    {:ok, job}
  end

  defp broadcast_job_created(error), do: error

  defp broadcast_job_updated({:ok, job}) do
    Broadcaster.broadcast_job_updated(job)
    {:ok, job}
  end

  defp broadcast_job_updated(error), do: error

  @doc """
  Broadcasts a job location update (technician location).
  """
  def broadcast_job_location_update(job_id, lat, lng) do
    Broadcaster.broadcast_job_location_update(job_id, lat, lng)
  end

  # Add specific helpers for different update types to trigger notifications
  defp notify_job_scheduled({:ok, job}) do
    if job.customer_id do
      FieldHub.Jobs.JobNotifier.deliver_job_confirmation(job)
    end

    {:ok, job}
  end

  defp notify_job_scheduled(error), do: error

  defp notify_job_dispatched({:ok, job}) do
    if job.customer_id do
      FieldHub.Jobs.JobNotifier.deliver_technician_dispatch(job)
    end

    {:ok, job}
  end

  defp notify_job_dispatched(error), do: error

  defp notify_job_completed({:ok, job}) do
    job_with_preloads = preload_for_notifications(job)

    if job.customer_id do
      # Email notification
      FieldHub.Jobs.JobNotifier.deliver_job_completion(job)
      # SMS notification
      FieldHub.Notifications.SMS.notify_job_completed(job_with_preloads)
    end

    {:ok, job}
  end

  defp notify_job_completed(error), do: error

  @doc """
  Sends SMS notification when technician starts travel.
  Called from start_travel/1.
  """
  def notify_technician_en_route({:ok, job}) do
    job_with_preloads = preload_for_notifications(job)
    FieldHub.Notifications.SMS.notify_technician_en_route(job_with_preloads)
    {:ok, job}
  end

  def notify_technician_en_route(error), do: error

  @doc """
  Sends SMS notification when technician arrives.
  Called from arrive_on_site/1.
  """
  def notify_technician_arrived({:ok, job}) do
    job_with_preloads = preload_for_notifications(job)
    FieldHub.Notifications.SMS.notify_technician_arrived(job_with_preloads)
    {:ok, job}
  end

  def notify_technician_arrived(error), do: error

  # Preload customer and technician for notifications
  defp preload_for_notifications(job) do
    Repo.preload(job, [:customer, :technician])
  end
end
