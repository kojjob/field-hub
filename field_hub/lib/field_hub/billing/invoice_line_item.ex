defmodule FieldHub.Billing.InvoiceLineItem do
  @moduledoc """
  Line item for invoice details (parts, labor entries, etc).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(labor parts materials service other)

  schema "invoice_line_items" do
    field :description, :string
    field :type, :string, default: "service"
    field :quantity, :decimal, default: Decimal.new(1)
    field :unit_price, :decimal, default: Decimal.new(0)
    field :amount, :decimal, default: Decimal.new(0)

    belongs_to :invoice, FieldHub.Billing.Invoice

    timestamps(type: :utc_datetime)
  end

  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:description, :type, :quantity, :unit_price, :invoice_id])
    |> validate_required([:description, :quantity, :unit_price])
    |> validate_inclusion(:type, @types)
    |> calculate_amount()
  end

  defp calculate_amount(changeset) do
    quantity = get_field(changeset, :quantity) || Decimal.new(1)
    unit_price = get_field(changeset, :unit_price) || Decimal.new(0)
    amount = Decimal.mult(quantity, unit_price) |> Decimal.round(2)
    put_change(changeset, :amount, amount)
  end
end
