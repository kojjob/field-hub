defmodule FieldHub.Inventory do
  @moduledoc """
  The Inventory context for managing parts and materials.
  """

  import Ecto.Query, warn: false
  alias FieldHub.Repo

  alias FieldHub.Inventory.Part
  alias FieldHub.Inventory.JobPart

  # ============================================================================
  # Parts CRUD
  # ============================================================================

  @doc """
  Returns the list of parts for an organization.
  """
  def list_parts(org_id) do
    Part
    |> where([p], p.organization_id == ^org_id)
    |> order_by([p], asc: p.name)
    |> Repo.all()
  end

  @doc """
  Returns parts that are low on stock.
  """
  def list_low_stock_parts(org_id) do
    Part
    |> where([p], p.organization_id == ^org_id)
    |> where([p], p.quantity_on_hand <= p.reorder_point)
    |> order_by([p], asc: p.quantity_on_hand)
    |> Repo.all()
  end

  @doc """
  Searches parts by name, SKU, or category.
  """
  def search_parts(org_id, search_term) do
    search = "%#{search_term}%"

    Part
    |> where([p], p.organization_id == ^org_id)
    |> where(
      [p],
      ilike(p.name, ^search) or ilike(p.sku, ^search) or ilike(p.category, ^search)
    )
    |> order_by([p], asc: p.name)
    |> Repo.all()
  end

  @doc """
  Gets a single part by ID scoped to an organization.
  """
  def get_part!(org_id, id) do
    Part
    |> where([p], p.organization_id == ^org_id)
    |> where([p], p.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a part.
  """
  def create_part(org_id, attrs) do
    %Part{organization_id: org_id}
    |> Part.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a part.
  """
  def update_part(%Part{} = part, attrs) do
    part
    |> Part.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a part.
  """
  def delete_part(%Part{} = part) do
    Repo.delete(part)
  end

  @doc """
  Returns a changeset for tracking part changes.
  """
  def change_part(%Part{} = part, attrs \\ %{}) do
    Part.changeset(part, attrs)
  end

  @doc """
  Adjusts the stock quantity for a part.
  """
  def adjust_stock(%Part{} = part, adjustment) when is_integer(adjustment) do
    new_qty = max(0, part.quantity_on_hand + adjustment)
    update_part(part, %{quantity_on_hand: new_qty})
  end

  # ============================================================================
  # Job Parts
  # ============================================================================

  @doc """
  Lists all parts used on a job.
  """
  def list_job_parts(job_id) do
    JobPart
    |> where([jp], jp.job_id == ^job_id)
    |> Repo.all()
    |> Repo.preload([:part])
  end

  @doc """
  Adds a part to a job.

  Automatically captures the current unit price and deducts from inventory.
  """
  def add_part_to_job(job_id, part_id, quantity \\ 1, notes \\ nil) do
    part = Repo.get!(Part, part_id)

    attrs = %{
      job_id: job_id,
      part_id: part_id,
      quantity_used: quantity,
      unit_price_at_time: part.unit_price,
      notes: notes
    }

    result =
      %JobPart{}
      |> JobPart.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, job_part} ->
        # Deduct from inventory
        adjust_stock(part, -quantity)
        {:ok, job_part}

      error ->
        error
    end
  end

  @doc """
  Removes a part from a job and restores inventory.
  """
  def remove_part_from_job(job_part_id) do
    job_part = Repo.get!(JobPart, job_part_id) |> Repo.preload(:part)

    case Repo.delete(job_part) do
      {:ok, deleted} ->
        # Restore inventory
        adjust_stock(job_part.part, deleted.quantity_used)
        {:ok, deleted}

      error ->
        error
    end
  end

  @doc """
  Calculates the total parts cost for a job.
  """
  def job_parts_total(job_id) do
    query =
      from jp in JobPart,
        where: jp.job_id == ^job_id,
        select: sum(jp.quantity_used * jp.unit_price_at_time)

    Repo.one(query) || Decimal.new(0)
  end

  # ============================================================================
  # Stats
  # ============================================================================

  @doc """
  Returns inventory statistics for an organization.
  """
  def get_inventory_stats(org_id) do
    query = from(p in Part, where: p.organization_id == ^org_id)

    total_parts = Repo.aggregate(query, :count, :id)

    total_value =
      from(p in query, select: sum(p.quantity_on_hand * p.unit_price))
      |> Repo.one()

    low_stock_count =
      from(p in query, where: p.quantity_on_hand <= p.reorder_point)
      |> Repo.aggregate(:count, :id)

    %{
      total_parts: total_parts,
      total_value: total_value || Decimal.new(0),
      low_stock_count: low_stock_count
    }
  end
end
