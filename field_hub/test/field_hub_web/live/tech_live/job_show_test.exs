defmodule FieldHubWeb.TechLive.JobShowTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.JobsFixtures
  import FieldHub.AccountsFixtures

  import FieldHub.CRMFixtures

  describe "Technician Job Detail" do
    setup %{conn: conn} do
      org = organization_fixture()
      user = user_fixture(organization_id: org.id)

      technician =
        %FieldHub.Dispatch.Technician{
          organization_id: org.id,
          user_id: user.id,
          name: "Test Tech",
          status: "available",
          email: "tech-#{System.unique_integer()}@example.com"
        }
        |> FieldHub.Repo.insert!()

      customer = customer_fixture(org.id)

      job =
        job_fixture(
          org.id,
          %{
            customer_id: customer.id,
            technician_id: technician.id,
            title: "Fix HVAC Unit",
            description: "Unit is making a loud noise",
            status: "scheduled",
            scheduled_date: Date.utc_today(),
            scheduled_start: DateTime.utc_now(),
            scheduled_end: DateTime.add(DateTime.utc_now(), 3600, :second)
          }
        )

      %{
        conn: log_in_user(conn, user),
        user: user,
        technician: technician,
        job: job,
        customer: customer,
        org: org
      }
    end

    test "renders job details", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/tech/jobs/#{job.id}")

      assert html =~ job.title
      assert html =~ job.description
      assert html =~ "Job ##{job.number}"
    end

    test "shows customer info with call button", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/tech/jobs/#{job.id}")

      # Assuming job_fixture creates a customer
      customer = FieldHub.Repo.preload(job, :customer).customer
      assert html =~ customer.name
      assert html =~ "tel:#{customer.phone}"
    end

    test "shows navigation button", %{conn: conn, job: job} do
      {:ok, _view, html} = live(conn, ~p"/tech/jobs/#{job.id}")

      assert html =~ "Navigate"
    end

    test "shows service history", %{conn: conn, job: job, customer: customer, org: org} do
      # Create another job for the same customer
      job_fixture(org.id, %{
        customer_id: customer.id,
        title: "Previous Maintenance",
        work_performed: "Cleaned filters",
        inserted_at: DateTime.add(DateTime.utc_now(), -86400, :second)
      })

      {:ok, _view, html} = live(conn, ~p"/tech/jobs/#{job.id}")
      assert html =~ "Service History"
      assert html =~ "Previous Maintenance"
      assert html =~ "Cleaned filters"
    end

    test "handles status action: start_travel", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/tech/jobs/#{job.id}")

      assert render(view) =~ "Start Travel"

      view |> element("button", "Start Travel") |> render_click()
      assert has_element?(view, "#status-confirm-modal")

      view |> element("#status-confirm-modal-confirm") |> render_click()

      assert render(view) =~ "En route"
      assert render(view) =~ "Arrived On Site"
      refute has_element?(view, "#status-confirm-modal")
    end

    test "handles status action sequence: start_travel -> arrive -> start_work", %{
      conn: conn,
      job: job
    } do
      {:ok, view, _html} = live(conn, ~p"/tech/jobs/#{job.id}")

      view |> element("button", "Start Travel") |> render_click()
      view |> element("#status-confirm-modal-confirm") |> render_click()
      assert render(view) =~ "En route"

      view |> element("button", "Arrived On Site") |> render_click()
      view |> element("#status-confirm-modal-confirm") |> render_click()
      assert render(view) =~ "On site"

      view |> element("button", "Start Work") |> render_click()
      view |> element("#status-confirm-modal-confirm") |> render_click()
      assert render(view) =~ "In progress"
      assert render(view) =~ "Complete Job"
    end
  end
end
