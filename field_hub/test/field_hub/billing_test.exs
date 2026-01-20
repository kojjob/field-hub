defmodule FieldHub.BillingTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Billing
  alias FieldHub.Billing.{Invoice, InvoiceLineItem}

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.JobsFixtures
  import FieldHub.BillingFixtures

  describe "list_invoices/2" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      {:ok, org: org, customer: customer, job: job}
    end

    test "returns all invoices for an organization", %{org: org, job: job} do
      invoice = invoice_fixture(job)
      invoices = Billing.list_invoices(org.id)

      assert length(invoices) == 1
      assert hd(invoices).id == invoice.id
    end

    test "returns empty list when no invoices exist", %{org: org} do
      assert Billing.list_invoices(org.id) == []
    end

    test "filters by status", %{org: org, job: job} do
      invoice = invoice_fixture(job)
      Billing.send_invoice(invoice)

      assert length(Billing.list_invoices(org.id, status: "sent")) == 1
      assert Billing.list_invoices(org.id, status: "paid") == []
    end

    test "filters by customer_id", %{org: org, customer: customer, job: job} do
      invoice_fixture(job)

      # Create another customer with a job
      other_customer = customer_fixture(org.id)
      other_job = job_fixture(org.id, %{customer_id: other_customer.id})
      invoice_fixture(other_job)

      assert length(Billing.list_invoices(org.id, customer_id: customer.id)) == 1
      assert length(Billing.list_invoices(org.id, customer_id: other_customer.id)) == 1
      assert length(Billing.list_invoices(org.id)) == 2
    end

    test "applies limit option", %{org: org, customer: customer} do
      job1 = job_fixture(org.id, %{customer_id: customer.id})
      job2 = job_fixture(org.id, %{customer_id: customer.id})
      invoice_fixture(job1)
      invoice_fixture(job2)

      assert length(Billing.list_invoices(org.id, limit: 1)) == 1
    end
  end

  describe "get_invoice!/2" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      {:ok, org: org, customer: customer, job: job}
    end

    test "returns the invoice with preloaded associations", %{org: org, job: job} do
      invoice = invoice_fixture(job)
      fetched = Billing.get_invoice!(org.id, invoice.id)

      assert fetched.id == invoice.id
      assert fetched.job != nil
      assert fetched.customer != nil
      assert fetched.line_items != nil
    end

    test "raises when invoice doesn't exist", %{org: org} do
      assert_raise Ecto.NoResultsError, fn ->
        Billing.get_invoice!(org.id, -1)
      end
    end

    test "raises when invoice belongs to different organization", %{job: job} do
      invoice = invoice_fixture(job)
      other_org = organization_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Billing.get_invoice!(other_org.id, invoice.id)
      end
    end
  end

  describe "get_invoice_for_job/1" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      {:ok, org: org, customer: customer, job: job}
    end

    test "returns invoice for job", %{job: job} do
      invoice = invoice_fixture(job)
      fetched = Billing.get_invoice_for_job(job.id)

      assert fetched.id == invoice.id
    end

    test "returns nil when job has no invoice", %{job: job} do
      assert Billing.get_invoice_for_job(job.id) == nil
    end
  end

  describe "generate_invoice_from_job/2" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      {:ok, org: org, customer: customer, job: job}
    end

    test "creates invoice with calculated amounts from job", %{job: job} do
      {:ok, invoice} = Billing.generate_invoice_from_job(job.id)

      assert invoice.job_id == job.id
      assert invoice.customer_id == job.customer_id
      assert invoice.organization_id == job.organization_id
      assert invoice.status == "draft"
      assert invoice.number =~ ~r/^INV-/
      assert invoice.issue_date == Date.utc_today()
      assert Date.diff(invoice.due_date, Date.utc_today()) == 30
    end

    test "calculates labor from started_at and completed_at timestamps", %{
      org: org,
      customer: customer
    } do
      # Create a job and manually set timestamps for 2 hours of work
      job = job_fixture(org.id, %{customer_id: customer.id})

      # Update timestamps directly (bypassing changeset since these are lifecycle fields)
      started = ~U[2026-01-20 10:00:00Z]
      completed = ~U[2026-01-20 12:00:00Z]

      job
      |> Ecto.Changeset.change(%{started_at: started, completed_at: completed})
      |> FieldHub.Repo.update!()

      {:ok, invoice} = Billing.generate_invoice_from_job(job.id)

      assert Decimal.eq?(invoice.labor_hours, Decimal.new(2))
    end

    test "calculates labor from estimated_duration_minutes when no actual", %{
      org: org,
      customer: customer
    } do
      job = job_fixture(org.id, %{customer_id: customer.id, estimated_duration_minutes: 90})
      {:ok, invoice} = Billing.generate_invoice_from_job(job.id)

      assert Decimal.eq?(invoice.labor_hours, Decimal.new("1.5"))
    end

    test "defaults to 1 hour when no duration data", %{job: job} do
      {:ok, invoice} = Billing.generate_invoice_from_job(job.id)

      assert Decimal.eq?(invoice.labor_hours, Decimal.new(1))
    end

    test "allows overriding attributes", %{job: job} do
      {:ok, invoice} =
        Billing.generate_invoice_from_job(job.id, %{
          notes: "Custom notes",
          tax_rate: Decimal.new("10.00")
        })

      assert invoice.notes =~ "Custom notes"
      assert Decimal.eq?(invoice.tax_rate, Decimal.new("10.00"))
    end

    test "calculates tax and total correctly", %{job: job} do
      {:ok, invoice} =
        Billing.generate_invoice_from_job(job.id, %{
          labor_amount: Decimal.new("100.00"),
          parts_amount: Decimal.new("50.00"),
          tax_rate: Decimal.new("10.00")
        })

      # Subtotal: 150, Tax: 15, Total: 165
      assert Decimal.eq?(invoice.tax_amount, Decimal.new("15.00"))
      assert Decimal.eq?(invoice.total_amount, Decimal.new("165.00"))
    end
  end

  describe "update_invoice/2" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, invoice: invoice}
    end

    test "updates invoice attributes", %{invoice: invoice} do
      {:ok, updated} = Billing.update_invoice(invoice, %{notes: "Updated notes"})
      assert updated.notes == "Updated notes"
    end

    test "recalculates totals on amount changes", %{invoice: invoice} do
      {:ok, updated} =
        Billing.update_invoice(invoice, %{
          labor_amount: Decimal.new("200.00"),
          parts_amount: Decimal.new("100.00"),
          tax_rate: Decimal.new("10.00")
        })

      # Subtotal: 300, Tax: 30, Total: 330
      assert Decimal.eq?(updated.tax_amount, Decimal.new("30.00"))
      assert Decimal.eq?(updated.total_amount, Decimal.new("330.00"))
    end

    test "validates status", %{invoice: invoice} do
      {:error, changeset} = Billing.update_invoice(invoice, %{status: "invalid"})
      assert "is invalid" in errors_on(changeset).status
    end
  end

  describe "delete_invoice/1" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, org: org, invoice: invoice}
    end

    test "deletes the invoice", %{org: org, invoice: invoice} do
      {:ok, _} = Billing.delete_invoice(invoice)
      assert Billing.list_invoices(org.id) == []
    end
  end

  describe "send_invoice/1" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, invoice: invoice}
    end

    test "updates status to sent", %{invoice: invoice} do
      {:ok, updated} = Billing.send_invoice(invoice)
      assert updated.status == "sent"
    end
  end

  describe "mark_invoice_paid/1" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, invoice: invoice}
    end

    test "updates status to paid and sets paid_at", %{invoice: invoice} do
      {:ok, updated} = Billing.mark_invoice_paid(invoice)

      assert updated.status == "paid"
      assert updated.paid_at != nil
    end
  end

  describe "line items" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, invoice: invoice}
    end

    test "add_line_item/2 creates a line item with calculated amount", %{invoice: invoice} do
      {:ok, line_item} =
        Billing.add_line_item(invoice.id, %{
          description: "Labor",
          type: "labor",
          quantity: Decimal.new("2.0"),
          unit_price: Decimal.new("75.00")
        })

      assert line_item.invoice_id == invoice.id
      assert line_item.description == "Labor"
      assert line_item.type == "labor"
      assert Decimal.eq?(line_item.amount, Decimal.new("150.00"))
    end

    test "add_line_item/2 validates required fields", %{invoice: invoice} do
      {:error, changeset} = Billing.add_line_item(invoice.id, %{})

      assert "can't be blank" in errors_on(changeset).description
    end

    test "add_line_item/2 validates type", %{invoice: invoice} do
      {:error, changeset} =
        Billing.add_line_item(invoice.id, %{
          description: "Test",
          type: "invalid_type",
          quantity: Decimal.new("1"),
          unit_price: Decimal.new("10")
        })

      assert "is invalid" in errors_on(changeset).type
    end

    test "remove_line_item/1 deletes the line item", %{invoice: invoice} do
      {:ok, line_item} =
        Billing.add_line_item(invoice.id, %{
          description: "Test",
          type: "service",
          quantity: Decimal.new("1"),
          unit_price: Decimal.new("10")
        })

      {:ok, _} = Billing.remove_line_item(line_item.id)

      assert_raise Ecto.NoResultsError, fn ->
        FieldHub.Repo.get!(InvoiceLineItem, line_item.id)
      end
    end
  end

  describe "get_invoice_stats/1" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      {:ok, org: org, customer: customer}
    end

    test "returns correct statistics", %{org: org, customer: customer} do
      # Create and pay one invoice
      job1 = job_fixture(org.id, %{customer_id: customer.id})

      invoice1 =
        invoice_fixture(job1, %{
          labor_amount: Decimal.new("100.00"),
          parts_amount: Decimal.new("0"),
          tax_rate: Decimal.new("0")
        })

      Billing.send_invoice(invoice1)
      Billing.mark_invoice_paid(invoice1)

      # Create unpaid invoice
      job2 = job_fixture(org.id, %{customer_id: customer.id})

      invoice2 =
        invoice_fixture(job2, %{
          labor_amount: Decimal.new("200.00"),
          parts_amount: Decimal.new("0"),
          tax_rate: Decimal.new("0")
        })

      Billing.send_invoice(invoice2)

      stats = Billing.get_invoice_stats(org.id)

      assert stats.invoice_count == 2
      assert Decimal.eq?(stats.total_invoiced, Decimal.new("300.00"))
      assert Decimal.eq?(stats.total_paid, Decimal.new("100.00"))
      assert Decimal.eq?(stats.outstanding, Decimal.new("200.00"))
    end

    test "returns zero values when no invoices", %{org: org} do
      stats = Billing.get_invoice_stats(org.id)

      assert stats.invoice_count == 0
      assert Decimal.eq?(stats.total_invoiced, Decimal.new(0))
      assert Decimal.eq?(stats.total_paid, Decimal.new(0))
      assert Decimal.eq?(stats.outstanding, Decimal.new(0))
    end
  end

  describe "Invoice schema" do
    test "generates unique invoice numbers" do
      numbers =
        for _ <- 1..10 do
          changeset =
            Invoice.changeset(%Invoice{}, %{
              organization_id: 1,
              customer_id: 1,
              job_id: 1
            })

          Ecto.Changeset.get_field(changeset, :number)
        end

      assert length(Enum.uniq(numbers)) == 10
    end

    test "invoice number starts with INV-" do
      changeset =
        Invoice.changeset(%Invoice{}, %{
          organization_id: 1,
          customer_id: 1,
          job_id: 1
        })

      number = Ecto.Changeset.get_field(changeset, :number)
      assert String.starts_with?(number, "INV-")
    end
  end

  describe "Invoice queries" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, org: org, customer: customer, job: job, invoice: invoice}
    end

    test "for_organization/2 filters by org", %{org: org, invoice: invoice} do
      result =
        Invoice
        |> Invoice.for_organization(org.id)
        |> FieldHub.Repo.all()

      assert length(result) == 1
      assert hd(result).id == invoice.id
    end

    test "for_customer/2 filters by customer", %{customer: customer, invoice: invoice} do
      result =
        Invoice
        |> Invoice.for_customer(customer.id)
        |> FieldHub.Repo.all()

      assert length(result) == 1
      assert hd(result).id == invoice.id
    end

    test "for_job/2 filters by job", %{job: job, invoice: invoice} do
      result =
        Invoice
        |> Invoice.for_job(job.id)
        |> FieldHub.Repo.all()

      assert length(result) == 1
      assert hd(result).id == invoice.id
    end

    test "with_status/2 filters by status", %{invoice: invoice} do
      result =
        Invoice
        |> Invoice.with_status("draft")
        |> FieldHub.Repo.all()

      assert length(result) == 1
      assert hd(result).id == invoice.id

      result =
        Invoice
        |> Invoice.with_status("paid")
        |> FieldHub.Repo.all()

      assert result == []
    end

    test "recent/2 orders and limits results", %{org: org, customer: customer} do
      # Create more jobs and invoices
      for _ <- 1..5 do
        job = job_fixture(org.id, %{customer_id: customer.id})
        invoice_fixture(job)
      end

      result =
        Invoice
        |> Invoice.for_organization(org.id)
        |> Invoice.recent(3)
        |> FieldHub.Repo.all()

      assert length(result) == 3
    end
  end
end
