defmodule FieldHub.Dispatch do
  @moduledoc """
  The Dispatch context handles technician management.

  Provides functions for managing field technicians including their
  status, location, skills, and availability.
  """

  import Ecto.Query, warn: false
  alias FieldHub.Repo
  alias FieldHub.Dispatch.Technician

  @doc """
  Returns the list of technicians for an organization.

  Excludes archived technicians by default.

  ## Examples

      iex> list_technicians(org_id)
      [%Technician{}, ...]

  """
  def list_technicians(org_id) do
    Technician
    |> where([t], t.organization_id == ^org_id)
    |> where([t], is_nil(t.archived_at))
    |> order_by([t], t.name)
    |> Repo.all()
  end

  @doc """
  Gets a single technician scoped to an organization.

  Raises `Ecto.NoResultsError` if the technician does not exist
  or doesn't belong to the specified organization.

  ## Examples

      iex> get_technician!(org_id, 123)
      %Technician{}

      iex> get_technician!(org_id, 456)
      ** (Ecto.NoResultsError)

  """
  def get_technician!(org_id, id) do
    Technician
    |> where([t], t.organization_id == ^org_id)
    |> where([t], t.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Gets a technician by ID without organization scoping.

  Returns nil if not found.
  """
  def get_technician(id) do
    Repo.get(Technician, id)
  end

  @doc """
  Creates a technician for an organization.

  ## Examples

      iex> create_technician(org_id, %{name: "John Doe"})
      {:ok, %Technician{}}

      iex> create_technician(org_id, %{})
      {:error, %Ecto.Changeset{}}

  """
  def create_technician(org_id, attrs) do
    %Technician{organization_id: org_id}
    |> Technician.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a technician.

  ## Examples

      iex> update_technician(technician, %{name: "Updated Name"})
      {:ok, %Technician{}}

      iex> update_technician(technician, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_technician(%Technician{} = technician, attrs) do
    technician
    |> Technician.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a technician's status.

  Valid statuses: "available", "on_job", "traveling", "break", "off_duty"

  ## Examples

      iex> update_technician_status(technician, "on_job")
      {:ok, %Technician{}}

  """
  def update_technician_status(%Technician{} = technician, status) do
    technician
    |> Technician.status_changeset(status)
    |> Repo.update()
  end

  @doc """
  Updates a technician's current location.

  ## Examples

      iex> update_technician_location(technician, 33.749, -84.388)
      {:ok, %Technician{}}

  """
  def update_technician_location(%Technician{} = technician, lat, lng) do
    technician
    |> Technician.location_changeset(%{current_lat: lat, current_lng: lng})
    |> Repo.update()
  end

  @doc """
  Archives a technician (soft delete).

  Sets archived_at to current timestamp.

  ## Examples

      iex> archive_technician(technician)
      {:ok, %Technician{archived_at: ~U[...]}}

  """
  def archive_technician(%Technician{} = technician) do
    technician
    |> Ecto.Changeset.change(%{archived_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Restores an archived technician.

  Sets archived_at to nil.

  ## Examples

      iex> restore_technician(technician)
      {:ok, %Technician{archived_at: nil}}

  """
  def restore_technician(%Technician{} = technician) do
    technician
    |> Ecto.Changeset.change(%{archived_at: nil})
    |> Repo.update()
  end

  @doc """
  Returns technicians with "available" status.

  ## Examples

      iex> get_available_technicians(org_id)
      [%Technician{status: "available"}, ...]

  """
  def get_available_technicians(org_id) do
    Technician
    |> where([t], t.organization_id == ^org_id)
    |> where([t], t.status == "available")
    |> where([t], is_nil(t.archived_at))
    |> order_by([t], t.name)
    |> Repo.all()
  end

  @doc """
  Returns technicians with a specific skill.

  Uses Postgres array contains operator.

  ## Examples

      iex> get_technicians_with_skill(org_id, "HVAC")
      [%Technician{skills: ["HVAC", ...]}, ...]

  """
  def get_technicians_with_skill(org_id, skill) do
    Technician
    |> where([t], t.organization_id == ^org_id)
    |> where([t], ^skill in t.skills)
    |> where([t], is_nil(t.archived_at))
    |> order_by([t], t.name)
    |> Repo.all()
  end

  @doc """
  Returns the count of active (non-archived) technicians.

  ## Examples

      iex> count_technicians(org_id)
      5

  """
  def count_technicians(org_id) do
    Technician
    |> where([t], t.organization_id == ^org_id)
    |> where([t], is_nil(t.archived_at))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns technicians by their IDs.

  ## Examples

      iex> get_technicians_by_ids(org_id, [1, 2, 3])
      [%Technician{}, %Technician{}, %Technician{}]

  """
  def get_technicians_by_ids(org_id, ids) when is_list(ids) do
    Technician
    |> where([t], t.organization_id == ^org_id)
    |> where([t], t.id in ^ids)
    |> Repo.all()
  end

  @doc """
  Searches technicians by name or email.

  ## Examples

      iex> search_technicians(org_id, "john")
      [%Technician{name: "John Doe", ...}]

  """
  def search_technicians(org_id, search_term) do
    search = "%#{search_term}%"

    Technician
    |> where([t], t.organization_id == ^org_id)
    |> where([t], is_nil(t.archived_at))
    |> where([t], ilike(t.name, ^search) or ilike(t.email, ^search))
    |> order_by([t], t.name)
    |> Repo.all()
  end
end
