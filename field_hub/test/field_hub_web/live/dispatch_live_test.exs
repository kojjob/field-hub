defmodule FieldHubWeb.DispatchLiveTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.CRMFixtures
  import FieldHub.DispatchFixtures

  setup %{conn: conn} do
    unique_id = System.unique_integer([:positive])
    {:ok, org} = FieldHub.Accounts.create_organization(%{name: "Test Org #{unique_id}", slug: "test-org-#{unique_id}"})
    user = FieldHub.AccountsFixtures.user_fixture(%{organization_id: org.id})

    conn =
      conn
      |> log_in_user(user)
      |> assign(:current_organization, org)

    {:ok, conn: conn, user: user, org: org}
  end

  describe "Dispatch Board" do
    test "renders day view by default", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/dispatch")

      # Should show the dispatch board with day view
      assert html =~ "Dispatch Board"
      assert html =~ "Day"
    end

    test "shows jobs in correct time slots", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)
      technician = technician_fixture(org.id)

      # Create a job scheduled for 9am today
      today = Date.utc_today()
      {:ok, _job} = FieldHub.Jobs.create_job(org.id, %{
        title: "Morning Service Call",
        description: "Test job",
        job_type: "service_call",
        priority: "normal",
        customer_id: customer.id,
        technician_id: technician.id,
        created_by_id: user.id,
        scheduled_date: today,
        scheduled_start: ~T[09:00:00],
        scheduled_end: ~T[10:00:00]
      })

      {:ok, _live, html} = live(conn, ~p"/dispatch")

      # Job should appear on the board
      assert html =~ "Morning Service Call"
    end

    test "groups jobs by technician", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)
      tech1 = technician_fixture(org.id, %{name: "Alice Smith", color: "#FF5733"})
      tech2 = technician_fixture(org.id, %{name: "Bob Jones", color: "#33FF57"})

      today = Date.utc_today()

      {:ok, _job1} = FieldHub.Jobs.create_job(org.id, %{
        title: "Alice's Job",
        description: "Test",
        job_type: "service_call",
        priority: "normal",
        customer_id: customer.id,
        technician_id: tech1.id,
        created_by_id: user.id,
        scheduled_date: today,
        scheduled_start: ~T[09:00:00]
      })

      {:ok, _job2} = FieldHub.Jobs.create_job(org.id, %{
        title: "Bob's Job",
        description: "Test",
        job_type: "service_call",
        priority: "normal",
        customer_id: customer.id,
        technician_id: tech2.id,
        created_by_id: user.id,
        scheduled_date: today,
        scheduled_start: ~T[10:00:00]
      })

      {:ok, _live, html} = live(conn, ~p"/dispatch")

      # Both technicians should appear
      assert html =~ "Alice Smith"
      assert html =~ "Bob Jones"
    end

    test "date navigation works", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Navigate to next day
      html = live |> element("button", "Next") |> render_click()

      tomorrow = Date.add(Date.utc_today(), 1)
      assert html =~ Calendar.strftime(tomorrow, "%B %d, %Y")
    end

    test "shows unassigned jobs sidebar", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)

      {:ok, _unassigned_job} = FieldHub.Jobs.create_job(org.id, %{
        title: "Unassigned Service",
        description: "Needs assignment",
        job_type: "service_call",
        priority: "urgent",
        customer_id: customer.id,
        created_by_id: user.id
      })

      {:ok, _live, html} = live(conn, ~p"/dispatch")

      # Unassigned job should appear in sidebar
      assert html =~ "Unassigned"
      assert html =~ "Unassigned Service"
    end
  end
end
