defmodule FieldHubWeb.InvoiceLiveTest do
  use FieldHubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias FieldHub.Billing

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.JobsFixtures
  import FieldHub.BillingFixtures

  describe "Invoice Index" do
    setup %{conn: conn} do
      org = organization_fixture()
      user = user_fixture(%{organization_id: org.id})
      customer = customer_fixture(org.id)

      conn = log_in_user(conn, user)

      {:ok, conn: conn, org: org, user: user, customer: customer}
    end

    test "renders invoice index page with no invoices", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/invoices")

      assert html =~ "Invoices"
      assert html =~ "No invoices yet"
      assert html =~ "$0"
    end

    test "lists invoices", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)

      {:ok, _view, html} = live(conn, ~p"/invoices")

      assert html =~ invoice.number
      assert html =~ customer.name
      assert html =~ "draft"
    end

    test "displays invoice stats", %{conn: conn, org: org, customer: customer} do
      job1 = job_fixture(org.id, %{customer_id: customer.id})
      invoice1 = invoice_fixture(job1, %{
        labor_amount: Decimal.new("100.00"),
        parts_amount: Decimal.new("50.00"),
        tax_rate: Decimal.new("10.00")
      })
      Billing.send_invoice(invoice1)
      Billing.mark_invoice_paid(invoice1)

      job2 = job_fixture(org.id, %{customer_id: customer.id})
      invoice2 = invoice_fixture(job2, %{
        labor_amount: Decimal.new("200.00"),
        parts_amount: Decimal.new("0"),
        tax_rate: Decimal.new("0")
      })
      Billing.send_invoice(invoice2)

      {:ok, _view, html} = live(conn, ~p"/invoices")

      # Should show stats
      assert html =~ "Total Invoiced"
      assert html =~ "Paid"
      assert html =~ "Outstanding"
      assert html =~ "2" # invoice count
    end

    test "filters invoices by status", %{conn: conn, org: org, customer: customer} do
      # Create draft invoice
      job1 = job_fixture(org.id, %{customer_id: customer.id})
      draft_invoice = invoice_fixture(job1)

      # Create sent invoice
      job2 = job_fixture(org.id, %{customer_id: customer.id})
      sent_invoice = invoice_fixture(job2)
      {:ok, sent_invoice} = Billing.send_invoice(sent_invoice)

      # Create paid invoice
      job3 = job_fixture(org.id, %{customer_id: customer.id})
      paid_invoice = invoice_fixture(job3)
      Billing.send_invoice(paid_invoice)
      {:ok, _} = Billing.mark_invoice_paid(paid_invoice)

      {:ok, view, html} = live(conn, ~p"/invoices")

      # Initially shows all invoices
      assert html =~ draft_invoice.number
      assert html =~ sent_invoice.number
      assert html =~ paid_invoice.number

      # Filter by draft
      html = view |> element("button", "Draft") |> render_click()
      assert html =~ draft_invoice.number
      refute html =~ sent_invoice.number
      refute html =~ paid_invoice.number

      # Filter by sent
      html = view |> element("button", "Sent") |> render_click()
      refute html =~ draft_invoice.number
      assert html =~ sent_invoice.number
      refute html =~ paid_invoice.number

      # Filter by paid
      html = view |> element("button", "Paid") |> render_click()
      refute html =~ draft_invoice.number
      refute html =~ sent_invoice.number
      assert html =~ paid_invoice.number

      # Filter back to all
      html = view |> element("button", "All") |> render_click()
      assert html =~ draft_invoice.number
      assert html =~ sent_invoice.number
      assert html =~ paid_invoice.number
    end

    test "navigates to invoice show page", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)

      {:ok, view, _html} = live(conn, ~p"/invoices")

      {:ok, _show_view, html} =
        view
        |> element("a[href='/invoices/#{invoice.id}']", "View")
        |> render_click()
        |> follow_redirect(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ invoice.number
      assert html =~ "INVOICE"
    end
  end

  describe "Invoice Show" do
    setup %{conn: conn} do
      org = organization_fixture()
      user = user_fixture(%{organization_id: org.id})
      customer = customer_fixture(org.id, %{email: "customer@example.com"})
      job = job_fixture(org.id, %{customer_id: customer.id})

      conn = log_in_user(conn, user)

      {:ok, conn: conn, org: org, user: user, customer: customer, job: job}
    end

    test "renders invoice show page", %{conn: conn, org: org, customer: customer, job: job} do
      invoice = invoice_fixture(job)

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ invoice.number
      assert html =~ org.name
      assert html =~ customer.name
      assert html =~ "INVOICE"
      assert html =~ "Bill To"
      assert html =~ "Charges"
      assert html =~ "Total Due"
    end

    test "shows draft invoice with send button", %{conn: conn, job: job} do
      invoice = invoice_fixture(job)

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "draft"
      assert html =~ "Send Invoice"
      refute html =~ "Mark as Paid"
    end

    test "sends invoice", %{conn: conn, customer: customer, job: job} do
      invoice = invoice_fixture(job)

      {:ok, view, _html} = live(conn, ~p"/invoices/#{invoice.id}")

      html = view |> element("button", "Send Invoice") |> render_click()

      assert html =~ "sent"
      assert html =~ "Invoice sent to #{customer.email}"
      refute html =~ "Send Invoice"
      assert html =~ "Mark as Paid"
    end

    test "shows sent invoice with mark paid button", %{conn: conn, job: job} do
      invoice = invoice_fixture(job)
      {:ok, invoice} = Billing.send_invoice(invoice)

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "sent"
      assert html =~ "Mark as Paid"
      refute html =~ "Send Invoice"
    end

    test "marks invoice as paid", %{conn: conn, job: job} do
      invoice = invoice_fixture(job)
      {:ok, invoice} = Billing.send_invoice(invoice)

      {:ok, view, _html} = live(conn, ~p"/invoices/#{invoice.id}")

      html = view |> element("button", "Mark as Paid") |> render_click()

      assert html =~ "paid"
      assert html =~ "Invoice marked as paid"
      refute html =~ "Mark as Paid"
      refute html =~ "Send Invoice"
    end

    test "shows paid invoice without action buttons", %{conn: conn, job: job} do
      invoice = invoice_fixture(job)
      {:ok, invoice} = Billing.send_invoice(invoice)
      {:ok, _invoice} = Billing.mark_invoice_paid(invoice)

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "paid"
      assert html =~ "Paid on"
      refute html =~ "Send Invoice"
      refute html =~ "Mark as Paid"
    end

    test "displays labor details", %{conn: conn, job: job} do
      invoice = invoice_fixture(job, %{
        labor_hours: Decimal.new("2.5"),
        labor_rate: Decimal.new("75.00"),
        labor_amount: Decimal.new("187.50")
      })

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "Labor"
      assert html =~ "2.5"
      assert html =~ "75"
      assert html =~ "187.50"
    end

    test "displays parts amount", %{conn: conn, job: job} do
      invoice = invoice_fixture(job, %{
        parts_amount: Decimal.new("250.00")
      })

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "Parts"
      assert html =~ "250.00"
    end

    test "displays tax calculation", %{conn: conn, job: job} do
      invoice = invoice_fixture(job, %{
        labor_amount: Decimal.new("100.00"),
        parts_amount: Decimal.new("0"),
        tax_rate: Decimal.new("10.00")
      })

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "Tax"
      assert html =~ "10"
    end

    test "displays invoice notes", %{conn: conn, job: job} do
      invoice = invoice_fixture(job, %{
        notes: "Special instructions for the customer"
      })

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "Notes"
      assert html =~ "Special instructions for the customer"
    end

    test "displays job details", %{conn: conn, job: job} do
      invoice = invoice_fixture(job)

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "Service Details"
      assert html =~ job.title
      assert html =~ job.number
    end

    test "displays line items", %{conn: conn, job: job} do
      invoice = invoice_fixture(job)
      _line_item = line_item_fixture(invoice.id, %{
        description: "Additional Service Fee",
        quantity: Decimal.new("2.0"),
        unit_price: Decimal.new("25.00")
      })

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "Additional Service Fee"
      assert html =~ "2"
      assert html =~ "25.00"
      assert html =~ "50.00"
    end

    test "has download pdf button", %{conn: conn, job: job} do
      invoice = invoice_fixture(job)

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "Download PDF"
    end

    test "returns 404 for invoice from another organization", %{conn: _conn, job: job} do
      invoice = invoice_fixture(job)

      # Create another org and user
      other_org = organization_fixture()
      other_user = user_fixture(%{organization_id: other_org.id})
      other_conn = log_in_user(build_conn(), other_user)

      assert_raise Ecto.NoResultsError, fn ->
        live(other_conn, ~p"/invoices/#{invoice.id}")
      end
    end
  end

  describe "Invoice Show - navigation" do
    setup %{conn: conn} do
      org = organization_fixture()
      user = user_fixture(%{organization_id: org.id})
      customer = customer_fixture(org.id)
      job = job_fixture(org.id, %{customer_id: customer.id})

      conn = log_in_user(conn, user)

      {:ok, conn: conn, job: job}
    end

    test "has back to job link", %{conn: conn, job: job} do
      invoice = invoice_fixture(job)

      {:ok, _view, html} = live(conn, ~p"/invoices/#{invoice.id}")

      assert html =~ "Back to Job"
      assert html =~ ~p"/jobs/#{job.number}"
    end
  end
end
