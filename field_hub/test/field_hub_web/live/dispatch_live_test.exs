defmodule FieldHubWeb.DispatchLiveTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.CRMFixtures
  import FieldHub.DispatchFixtures

  setup %{conn: conn} do
    unique_id = System.unique_integer([:positive])

    {:ok, org} =
      FieldHub.Accounts.create_organization(%{
        name: "Test Org #{unique_id}",
        slug: "test-org-#{unique_id}"
      })

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

      {:ok, _job} =
        FieldHub.Jobs.create_job(org.id, %{
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

      {:ok, _job1} =
        FieldHub.Jobs.create_job(org.id, %{
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

      {:ok, _job2} =
        FieldHub.Jobs.create_job(org.id, %{
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
      html = live |> element("button[phx-click='next_day']") |> render_click()

      tomorrow = Date.add(Date.utc_today(), 1)
      assert html =~ Calendar.strftime(tomorrow, "%B %d, %Y")
    end

    test "shows unassigned jobs sidebar", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)

      {:ok, _unassigned_job} =
        FieldHub.Jobs.create_job(org.id, %{
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

    test "assign_job event assigns job to technician", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)
      technician = technician_fixture(org.id)

      {:ok, job} =
        FieldHub.Jobs.create_job(org.id, %{
          title: "Test Assignment",
          description: "Test",
          job_type: "service_call",
          priority: "normal",
          customer_id: customer.id,
          created_by_id: user.id
        })

      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Trigger assign_job event
      render_hook(live, "assign_job", %{
        "job_id" => job.id,
        "technician_id" => technician.id,
        "hour" => 9
      })

      # Verify job was assigned
      updated_job = FieldHub.Jobs.get_job!(org.id, job.id)
      assert updated_job.technician_id == technician.id
      assert updated_job.scheduled_date == Date.utc_today()
    end

    test "unassign_job event removes technician assignment", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)
      technician = technician_fixture(org.id)

      {:ok, job} =
        FieldHub.Jobs.create_job(org.id, %{
          title: "Assigned Job",
          description: "Test",
          job_type: "service_call",
          priority: "normal",
          customer_id: customer.id,
          technician_id: technician.id,
          scheduled_date: Date.utc_today(),
          scheduled_start: ~T[10:00:00],
          created_by_id: user.id
        })

      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Trigger unassign_job event
      render_hook(live, "unassign_job", %{"job_id" => job.id})

      # Verify job was unassigned
      updated_job = FieldHub.Jobs.get_job!(org.id, job.id)
      assert is_nil(updated_job.technician_id)
      assert is_nil(updated_job.scheduled_date)
    end
  end

  describe "Quick Actions" do
    test "change_status event updates job status", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)
      technician = technician_fixture(org.id)

      {:ok, job} =
        FieldHub.Jobs.create_job(org.id, %{
          title: "Status Test",
          description: "Test",
          job_type: "service_call",
          priority: "normal",
          status: "scheduled",
          customer_id: customer.id,
          technician_id: technician.id,
          scheduled_date: Date.utc_today(),
          created_by_id: user.id
        })

      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Change status to en_route
      render_hook(live, "change_status", %{
        "job_id" => job.id,
        "status" => "en_route"
      })

      # Verify status changed
      updated_job = FieldHub.Jobs.get_job!(org.id, job.id)
      assert updated_job.status == "en_route"
    end

    test "quick_dispatch assigns job to available technician", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)
      technician = technician_fixture(org.id, %{status: "available"})

      {:ok, job} =
        FieldHub.Jobs.create_job(org.id, %{
          title: "Quick Dispatch Test",
          description: "Test",
          job_type: "service_call",
          priority: "normal",
          customer_id: customer.id,
          created_by_id: user.id
        })

      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Quick dispatch - auto-assign to available tech
      render_hook(live, "quick_dispatch", %{"job_id" => job.id})

      # Verify job was assigned
      updated_job = FieldHub.Jobs.get_job!(org.id, job.id)
      assert updated_job.technician_id == technician.id
      assert updated_job.scheduled_date == Date.utc_today()
    end

    test "show_job_details opens slideout panel", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)
      technician = technician_fixture(org.id)

      {:ok, job} =
        FieldHub.Jobs.create_job(org.id, %{
          title: "Details Test Job",
          description: "View this job for more details",
          job_type: "service_call",
          priority: "normal",
          customer_id: customer.id,
          technician_id: technician.id,
          scheduled_date: Date.utc_today(),
          scheduled_start: ~T[10:00:00],
          created_by_id: user.id
        })

      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Open job details
      html = render_hook(live, "show_job_details", %{"job_id" => job.id})

      # Panel should show job details
      assert html =~ "Details Test Job"
      assert html =~ "View this job for more details"
    end
  end

  describe "Technician Status Sidebar" do
    test "displays technicians with their current status", %{conn: conn, org: org} do
      technician_fixture(org.id, %{name: "John Smith", status: "available"})
      technician_fixture(org.id, %{name: "Jane Doe", status: "on_job"})

      {:ok, _live, html} = live(conn, ~p"/dispatch")

      # Both technicians should appear with status
      assert html =~ "John Smith"
      assert html =~ "Jane Doe"
      assert html =~ "available"
      assert html =~ "on job"
    end

    test "shows current job for technicians on a job", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)
      technician = technician_fixture(org.id, %{name: "Active Tech", status: "on_job"})

      {:ok, _job} =
        FieldHub.Jobs.create_job(org.id, %{
          title: "Current Active Job",
          description: "This job is in progress",
          job_type: "service_call",
          priority: "normal",
          status: "in_progress",
          customer_id: customer.id,
          technician_id: technician.id,
          scheduled_date: Date.utc_today(),
          created_by_id: user.id
        })

      {:ok, _live, html} = live(conn, ~p"/dispatch")

      # Should show the technician and their current job
      assert html =~ "Active Tech"
      assert html =~ "Current Active Job"
    end

    test "update_tech_status changes technician status", %{conn: conn, org: org} do
      technician = technician_fixture(org.id, %{name: "Status Test", status: "available"})

      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Change technician status
      render_hook(live, "update_tech_status", %{
        "technician_id" => technician.id,
        "status" => "on_job"
      })

      # Verify status changed
      updated_tech = FieldHub.Dispatch.get_technician!(org.id, technician.id)
      assert updated_tech.status == "on_job"
    end
  end

  describe "Map View" do
    test "toggles to map view and displays map container", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Initial view should not have map
      refute has_element?(live, "#map-view")

      # Switch to map view
      html = live |> element("button", "Map") |> render_click()

      # Map container should be present
      assert html =~ "id=\"map-view\""
      assert html =~ "phx-hook=\"Map\""
    end

    test "includes technician and job data in map container", %{conn: conn, user: user, org: org} do
      customer = customer_fixture(org.id)

      technician =
        technician_fixture(org.id, %{name: "Map Tech", current_lat: 37.77, current_lng: -122.42})

      {:ok, job} =
        FieldHub.Jobs.create_job(org.id, %{
          title: "Map Job",
          job_type: "service_call",
          customer_id: customer.id,
          technician_id: technician.id,
          scheduled_date: Date.utc_today(),
          service_lat: 37.78,
          service_lng: -122.43,
          created_by_id: user.id
        })

      {:ok, live, _html} = live(conn, ~p"/dispatch")

      # Switch to map view
      html = live |> element("button", "Map") |> render_click()

      # Check for data attributes (checking for JSON strings might be brittle due to encoding, but checking unique values works)
      assert html =~ "Map Tech"
      assert html =~ "Map Job"
      assert html =~ "37.77"
      assert html =~ "37.78"
    end
  end
end
