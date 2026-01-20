defmodule FieldHub.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :number, :string, null: false
      add :status, :string, default: "draft"
      add :issue_date, :date
      add :due_date, :date
      add :paid_at, :utc_datetime

      # Financial breakdown
      add :labor_amount, :decimal, precision: 12, scale: 2, default: 0
      add :parts_amount, :decimal, precision: 12, scale: 2, default: 0
      add :materials_amount, :decimal, precision: 12, scale: 2, default: 0
      add :tax_rate, :decimal, precision: 5, scale: 2, default: 8.25
      add :tax_amount, :decimal, precision: 12, scale: 2, default: 0
      add :discount_amount, :decimal, precision: 12, scale: 2, default: 0
      add :total_amount, :decimal, precision: 12, scale: 2, default: 0

      # Labor details
      add :labor_hours, :decimal, precision: 8, scale: 2
      add :labor_rate, :decimal, precision: 10, scale: 2

      # Notes and terms
      add :notes, :text
      add :terms, :text
      add :payment_instructions, :text

      # Associations (all use bigint IDs)
      add :job_id, references(:jobs, on_delete: :nilify_all)
      add :customer_id, references(:customers, on_delete: :nilify_all), null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:invoices, [:organization_id])
    create index(:invoices, [:customer_id])
    create index(:invoices, [:job_id])
    create index(:invoices, [:status])
    create unique_index(:invoices, [:number, :organization_id])

    create table(:invoice_line_items) do
      add :description, :string, null: false
      add :type, :string, default: "service"
      add :quantity, :decimal, precision: 10, scale: 2, default: 1
      add :unit_price, :decimal, precision: 12, scale: 2, default: 0
      add :amount, :decimal, precision: 12, scale: 2, default: 0

      add :invoice_id, references(:invoices, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:invoice_line_items, [:invoice_id])
  end
end
