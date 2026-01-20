defmodule FieldHub.BillingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FieldHub.Billing` context.
  """

  alias FieldHub.Billing

  @doc """
  Generate an invoice from a job.
  """
  def invoice_fixture(job, attrs \\ %{}) do
    {:ok, invoice} = Billing.generate_invoice_from_job(job.id, attrs)
    invoice
  end

  @doc """
  Generate an invoice with explicit attributes.
  """
  def invoice_fixture_with_attrs(org_id, customer_id, job_id, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        organization_id: org_id,
        customer_id: customer_id,
        job_id: job_id,
        issue_date: Date.utc_today(),
        due_date: Date.add(Date.utc_today(), 30),
        labor_hours: Decimal.new("2.0"),
        labor_rate: Decimal.new("75.00"),
        labor_amount: Decimal.new("150.00"),
        parts_amount: Decimal.new("50.00"),
        tax_rate: Decimal.new("8.25")
      })

    %Billing.Invoice{}
    |> Billing.Invoice.changeset(attrs)
    |> FieldHub.Repo.insert!()
    |> FieldHub.Repo.preload([:job, :customer])
  end

  @doc """
  Generate an invoice line item.
  """
  def line_item_fixture(invoice_id, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "Test Line Item #{System.unique_integer([:positive])}",
        type: "service",
        quantity: Decimal.new("1.0"),
        unit_price: Decimal.new("50.00")
      })

    {:ok, line_item} = Billing.add_line_item(invoice_id, attrs)
    line_item
  end
end
