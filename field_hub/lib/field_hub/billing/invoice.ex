defmodule FieldHub.Billing.Invoice do
  @moduledoc """
  Invoice schema for generating and tracking customer invoices.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @statuses ~w(draft sent viewed paid overdue cancelled)

  schema "invoices" do
    field :number, :string
    field :status, :string, default: "draft"
    field :issue_date, :date
    field :due_date, :date
    field :paid_at, :utc_datetime

    # Financial breakdown
    field :labor_amount, :decimal, default: Decimal.new(0)
    field :parts_amount, :decimal, default: Decimal.new(0)
    field :materials_amount, :decimal, default: Decimal.new(0)
    field :tax_rate, :decimal, default: Decimal.new("8.25")
    field :tax_amount, :decimal, default: Decimal.new(0)
    field :discount_amount, :decimal, default: Decimal.new(0)
    field :total_amount, :decimal, default: Decimal.new(0)

    # Labor details
    field :labor_hours, :decimal
    field :labor_rate, :decimal

    # Notes and terms
    field :notes, :string
    field :terms, :string
    field :payment_instructions, :string

    # Stripe payment tracking
    field :stripe_checkout_session_id, :string
    field :stripe_payment_intent_id, :string

    # Associations
    belongs_to :job, FieldHub.Jobs.Job
    belongs_to :customer, FieldHub.CRM.Customer
    belongs_to :organization, FieldHub.Accounts.Organization

    has_many :line_items, FieldHub.Billing.InvoiceLineItem, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(job_id customer_id organization_id)a
  @optional_fields ~w(
    number status issue_date due_date paid_at
    labor_amount parts_amount materials_amount
    tax_rate tax_amount discount_amount total_amount
    labor_hours labor_rate notes terms payment_instructions
    stripe_checkout_session_id stripe_payment_intent_id
  )a

  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, @statuses)
    |> generate_number()
    |> calculate_totals()
  end

  defp generate_number(changeset) do
    if get_field(changeset, :number) do
      changeset
    else
      put_change(changeset, :number, "INV-#{generate_invoice_number()}")
    end
  end

  defp generate_invoice_number do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")
    "#{timestamp |> rem(100_000_000)}#{random}"
  end

  defp calculate_totals(changeset) do
    labor = get_field(changeset, :labor_amount) || Decimal.new(0)
    parts = get_field(changeset, :parts_amount) || Decimal.new(0)
    materials = get_field(changeset, :materials_amount) || Decimal.new(0)
    discount = get_field(changeset, :discount_amount) || Decimal.new(0)
    tax_rate = get_field(changeset, :tax_rate) || Decimal.new("8.25")

    subtotal = Decimal.add(labor, parts) |> Decimal.add(materials)
    taxable = Decimal.sub(subtotal, discount)
    tax = Decimal.mult(taxable, Decimal.div(tax_rate, Decimal.new(100)))
    total = Decimal.add(taxable, tax)

    changeset
    |> put_change(:tax_amount, Decimal.round(tax, 2))
    |> put_change(:total_amount, Decimal.round(total, 2))
  end

  # Queries
  def for_organization(query \\ __MODULE__, org_id) do
    from(i in query, where: i.organization_id == ^org_id)
  end

  def for_customer(query \\ __MODULE__, customer_id) do
    from(i in query, where: i.customer_id == ^customer_id)
  end

  def for_job(query \\ __MODULE__, job_id) do
    from(i in query, where: i.job_id == ^job_id)
  end

  def with_status(query \\ __MODULE__, status) do
    from(i in query, where: i.status == ^status)
  end

  def recent(query \\ __MODULE__, limit \\ 10) do
    from(i in query, order_by: [desc: i.inserted_at], limit: ^limit)
  end
end
