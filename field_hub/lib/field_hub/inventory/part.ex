defmodule FieldHub.Inventory.Part do
  @moduledoc """
  Part schema for inventory tracking.

  Parts represent materials, equipment, and supplies
  that can be used on jobs and billed to customers.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @categories ~w(material equipment tool supply consumable)

  schema "parts" do
    field :name, :string
    field :sku, :string
    field :description, :string
    field :unit_price, :decimal
    field :quantity_on_hand, :integer, default: 0
    field :reorder_point, :integer, default: 5
    field :category, :string, default: "material"

    belongs_to :organization, FieldHub.Accounts.Organization

    has_many :job_parts, FieldHub.Inventory.JobPart

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for part creation/update.
  """
  def changeset(part, attrs) do
    part
    |> cast(attrs, [
      :organization_id,
      :name,
      :sku,
      :description,
      :unit_price,
      :quantity_on_hand,
      :reorder_point,
      :category
    ])
    |> validate_required([:organization_id, :name, :unit_price])
    |> validate_inclusion(:category, @categories)
    |> validate_number(:unit_price, greater_than_or_equal_to: 0)
    |> validate_number(:quantity_on_hand, greater_than_or_equal_to: 0)
    |> validate_number(:reorder_point, greater_than_or_equal_to: 0)
    |> unique_constraint([:organization_id, :sku])
    |> foreign_key_constraint(:organization_id)
  end

  @doc """
  Returns the list of valid categories.
  """
  def categories, do: @categories

  @doc """
  Checks if a part is low on stock.
  """
  def low_stock?(%__MODULE__{quantity_on_hand: qty, reorder_point: reorder}) do
    qty <= reorder
  end
end
