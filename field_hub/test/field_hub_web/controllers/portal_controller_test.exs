defmodule FieldHubWeb.PortalControllerTest do
  use FieldHubWeb.ConnCase

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.JobsFixtures
  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    org = organization_fixture()
    customer = customer_fixture(org.id, %{portal_enabled: true})
    # Preload organization for the customer manualy if needed,
    # but CRM.get_customer_for_portal preloads it in the app.
    # We want to match what the layout expects.
    customer = FieldHub.Repo.preload(customer, :organization)
    {:ok, conn: conn, customer: customer, organization: org}
  end

  describe "GET /portal" do
    test "redirects to home if not logged in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/portal")
    end

    test "renders dashboard when logged in", %{conn: conn, customer: customer} do
      conn = conn |> init_test_session(%{portal_customer_id: customer.id})
      {:ok, _view, html} = live(conn, ~p"/portal")

      assert html =~ "Client Portal"
      assert html =~ customer.organization.name
    end
  end

  describe "GET /portal/jobs/:number" do
    test "renders job details", %{conn: conn, customer: customer, organization: organization} do
      job = job_fixture(organization.id, %{customer_id: customer.id, title: "Repair Leak"})
      conn = conn |> init_test_session(%{portal_customer_id: customer.id})

      {:ok, _view, html} = live(conn, ~p"/portal/jobs/#{job.number}")
      assert html =~ "Repair Leak"
      assert html =~ "Job Details"
    end

    test "redirects for job not belonging to customer", %{
      conn: conn,
      customer: customer,
      organization: organization
    } do
      other_customer = customer_fixture(organization.id, %{})
      job = job_fixture(organization.id, %{customer_id: other_customer.id, title: "Other Job"})

      conn = conn |> init_test_session(%{portal_customer_id: customer.id})

      assert {:error, {:live_redirect, %{to: "/portal", flash: %{"error" => "Job not found"}}}} =
               live(conn, ~p"/portal/jobs/#{job.number}")
    end
  end

  describe "GET /portal/history" do
    test "renders service history", %{conn: conn, customer: customer, organization: organization} do
      job_fixture(organization.id, %{
        customer_id: customer.id,
        title: "Old Job",
        status: "completed",
        completed_at: DateTime.utc_now()
      })

      conn = conn |> init_test_session(%{portal_customer_id: customer.id})

      {:ok, _view, html} = live(conn, ~p"/portal/history")
      assert html =~ "Service History"
      assert html =~ "Old Job"
    end
  end
end
