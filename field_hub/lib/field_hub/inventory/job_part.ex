defmodule FieldHub.Inventory.JobPart do
  @moduledoc """
  JobPart schema for tracking parts used on jobs.

  This is a join table between Jobs and Parts, storing
  the quantity used and the price at time of use.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "job_parts" do
    field :quantity_used, :integer, default: 1
    field :unit_price_at_time, :decimal
    field :notes, :string

    belongs_to :job, FieldHub.Jobs.Job
    belongs_to :part, FieldHub.Inventory.Part

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for job part creation/update.
  """
  def changeset(job_part, attrs) do
    job_part
    |> cast(attrs, [:job_id, :part_id, :quantity_used, :unit_price_at_time, :notes])
    |> validate_required([:job_id, :part_id, :quantity_used, :unit_price_at_time])
    |> validate_number(:quantity_used, greater_than: 0)
    |> validate_number(:unit_price_at_time, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:part_id)
  end

  @doc """
  Calculates the line total for this job part.
  """
  def line_total(%__MODULE__{quantity_used: qty, unit_price_at_time: price}) do
    Decimal.mult(Decimal.new(qty), price)
  end
end
