defmodule FieldHubWeb.PortalLive.InvoicesTest do
  use FieldHubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias FieldHub.Billing

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.JobsFixtures
  import FieldHub.BillingFixtures

  describe "Portal Invoices List" do
    setup %{conn: conn} do
      org = organization_fixture()
      customer = customer_fixture(org.id, %{email: "portal-test@example.com"})

      # Set up portal session
      conn = init_test_session(conn, %{portal_customer_id: customer.id})

      {:ok, conn: conn, org: org, customer: customer}
    end

    test "renders invoice list page with no invoices", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/portal/invoices")

      assert html =~ "My Invoices"
      assert html =~ "No invoices yet"
    end

    test "lists customer invoices", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)

      {:ok, _view, html} = live(conn, ~p"/portal/invoices")

      assert html =~ invoice.number
      assert html =~ "draft"
    end

    test "shows sent invoices with correct status", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, invoice} = Billing.send_invoice(invoice)

      {:ok, _view, html} = live(conn, ~p"/portal/invoices")

      assert html =~ invoice.number
      assert html =~ "sent"
    end

    test "navigates to invoice detail", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      Billing.send_invoice(invoice)

      {:ok, view, _html} = live(conn, ~p"/portal/invoices")

      {:ok, _detail_view, html} =
        view
        |> element("a[href='/portal/invoices/#{invoice.id}']")
        |> render_click()
        |> follow_redirect(conn, ~p"/portal/invoices/#{invoice.id}")

      assert html =~ invoice.number
      assert html =~ "INVOICE"
    end
  end

  describe "Portal Invoice Detail" do
    setup %{conn: conn} do
      org = organization_fixture()
      customer = customer_fixture(org.id, %{email: "portal-test@example.com"})

      # Set up portal session
      conn = init_test_session(conn, %{portal_customer_id: customer.id})

      {:ok, conn: conn, org: org, customer: customer}
    end

    test "renders invoice detail page", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})

      invoice =
        invoice_fixture(job, %{
          labor_hours: Decimal.new("2.0"),
          labor_rate: Decimal.new("75.00"),
          labor_amount: Decimal.new("150.00")
        })

      Billing.send_invoice(invoice)

      {:ok, _view, html} = live(conn, ~p"/portal/invoices/#{invoice.id}")

      assert html =~ invoice.number
      assert html =~ org.name
      assert html =~ customer.name
      assert html =~ "INVOICE"
      assert html =~ "Labor"
      assert html =~ "150.00"
    end

    test "marks invoice as viewed when customer views it", %{
      conn: conn,
      org: org,
      customer: customer
    } do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, invoice} = Billing.send_invoice(invoice)
      assert invoice.status == "sent"

      {:ok, _view, html} = live(conn, ~p"/portal/invoices/#{invoice.id}")

      assert html =~ "viewed"

      # Verify in database
      updated_invoice = Billing.get_invoice!(org.id, invoice.id)
      assert updated_invoice.status == "viewed"
    end

    test "shows paid status for paid invoices", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      {:ok, invoice} = Billing.send_invoice(invoice)
      {:ok, _invoice} = Billing.mark_invoice_paid(invoice)

      {:ok, _view, html} = live(conn, ~p"/portal/invoices/#{invoice.id}")

      assert html =~ "paid"
      assert html =~ "Paid in Full"
    end

    test "has print button", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job)
      Billing.send_invoice(invoice)

      {:ok, _view, html} = live(conn, ~p"/portal/invoices/#{invoice.id}")

      assert html =~ "Print"
    end

    test "cannot view invoices from another customer", %{
      conn: _conn,
      org: org,
      customer: _customer
    } do
      # Create another customer and invoice
      other_customer = customer_fixture(org.id, %{email: "other@example.com"})
      job = job_fixture(org.id, %{customer_id: other_customer.id})
      invoice = invoice_fixture(job)

      # Create a different customer for testing
      test_customer = customer_fixture(org.id, %{email: "test@example.com"})
      test_conn = build_conn()

      test_conn =
        init_test_session(test_conn, %{portal_customer_id: test_customer.id})

      # Should redirect with error flash
      assert {:error, {:live_redirect, %{to: "/portal/invoices", flash: %{"error" => "Invoice not found"}}}} =
               live(test_conn, ~p"/portal/invoices/#{invoice.id}")
    end

    test "shows payment instructions when present", %{conn: conn, org: org, customer: customer} do
      job = job_fixture(org.id, %{customer_id: customer.id})
      invoice = invoice_fixture(job, %{payment_instructions: "Pay via check to XYZ Corp"})
      Billing.send_invoice(invoice)

      {:ok, _view, html} = live(conn, ~p"/portal/invoices/#{invoice.id}")

      assert html =~ "Payment Instructions"
      assert html =~ "Pay via check to XYZ Corp"
    end
  end
end
