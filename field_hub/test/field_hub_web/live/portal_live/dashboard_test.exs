defmodule FieldHubWeb.PortalLive.DashboardTest do
  use FieldHubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias FieldHub.CRM
  alias FieldHub.Accounts

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.JobsFixtures

  describe "Portal Dashboard" do
    setup %{conn: conn} do
      org = organization_fixture()
      customer = customer_fixture(org.id, %{email: "portal-test@example.com", sms_notifications_enabled: true})

      # Set up portal session
      conn = init_test_session(conn, %{portal_customer_id: customer.id})

      {:ok, conn: conn, org: org, customer: customer}
    end

    test "renders intelligent narrative grid and KPIs", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/portal")

      assert html =~ "reliability"
      assert html =~ "Active Trust"
      assert html =~ "Total Service Visits"
      assert html =~ "Lifetime Service Value"
      assert html =~ "System Live"
    end

    test "updates sms preference via hook", %{conn: conn, customer: customer} do
      {:ok, view, _html} = live(conn, ~p"/portal")

      # Toggle off via hook pushEvent
      render_hook(view, "update_sms_preference", %{enabled: false})

      # Verify persistence in DB
      updated_customer = CRM.get_customer_for_portal(customer.id)
      assert updated_customer.sms_notifications_enabled == false

      # Verify flash message
      assert render(view) =~ "SMS notifications disabled"
    end

    test "uses dynamic terminology for job labels", %{conn: conn, org: org, customer: customer} do
      # Create a job to show in dashboard
      job_fixture(org.id, %{customer_id: customer.id, status: "scheduled"})

      {:ok, _view, html} = live(conn, ~p"/portal")

      # Default terminology has "Job"
      assert html =~ "Job"

      # Update organization terminology to use "Service Visit"
      {:ok, _org} = Accounts.update_organization(org, %{terminology: %{
        "task_label" => "Service Visit",
        "task_label_plural" => "Service Visits"
      }})

      # Reload dashboard to see changes
      {:ok, _view, html} = live(conn, ~p"/portal")
      assert html =~ "Service Visit"
    end
  end
end
