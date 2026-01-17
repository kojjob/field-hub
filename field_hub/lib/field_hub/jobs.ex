defmodule FieldHub.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false
  alias FieldHub.Repo

  alias FieldHub.Jobs.Job

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
    attrs = Map.put_new(attrs, :number, Job.generate_job_number(org_id))

    %Job{organization_id: org_id}
    |> Job.changeset(attrs)
    |> Repo.insert()
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
    job
    |> Job.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns jobs scheduled for a specific date.

  ## Examples

      iex> list_jobs_for_date(org_id, ~D[2023-01-01])
      [%Job{}, ...]

  """
  def list_jobs_for_date(org_id, date) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], j.scheduled_date == ^date)
    |> order_by([j], asc: j.scheduled_start)
    |> Repo.all()
  end

  @doc """
  Returns all unassigned (unscheduled) jobs.

  ## Examples

      iex> list_unassigned_jobs(org_id)
      [%Job{}, ...]

  """
  def list_unassigned_jobs(org_id) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where([j], j.status == "unscheduled")
    |> order_by([j], desc: j.inserted_at)
    |> Repo.all()
  end

  @doc """
  Assigns a technician to a job.

  Updates the status to "dispatched".

  ## Examples

      iex> assign_job(job, technician_id)
      {:ok, %Job{}}

  """
  def assign_job(%Job{} = job, technician_id) do
    job
    |> Job.assign_changeset(technician_id)
    |> Repo.update()
  end

  @doc """
  Schedules a job.

  Updates status to "scheduled" if valid.
  """
  def schedule_job(%Job{} = job, attrs) do
    job
    |> Job.schedule_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates job status to "en_route" and sets travel start time.
  """
  def start_travel(%Job{} = job) do
    job
    |> Job.start_travel_changeset()
    |> Repo.update()
  end

  @doc """
  Updates job status to "on_site" and sets arrival time.
  """
  def arrive_on_site(%Job{} = job) do
    job
    |> Job.arrive_changeset()
    |> Repo.update()
  end

  @doc """
  Updates job status to "in_progress" and sets start time.
  """
  def start_work(%Job{} = job) do
    job
    |> Job.start_work_changeset()
    |> Repo.update()
  end

  @doc """
  Completes a job with required details.
  """
  def complete_job(%Job{} = job, attrs) do
    job
    |> Job.complete_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Cancels a job with a reason.
  """
  def cancel_job(%Job{} = job, reason) do
    job
    |> Job.cancel_changeset(reason)
    |> Repo.update()
  end
end
