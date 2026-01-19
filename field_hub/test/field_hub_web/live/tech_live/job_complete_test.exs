defmodule FieldHubWeb.TechLive.JobCompleteTest do
  use FieldHubWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import FieldHub.JobsFixtures
  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.DispatchFixtures

  setup %{conn: conn} do
    org = organization_fixture()
    user = user_fixture(%{organization_id: org.id})
    technician = technician_fixture(org.id, %{user_id: user.id})
    customer = customer_fixture(org.id)

    # Create a job in progress
    job =
      job_fixture(org.id, %{
        customer_id: customer.id,
        technician_id: technician.id,
        status: "in_progress",
        scheduled_date: Date.utc_today()
      })

    conn = log_in_user(conn, user)
    {:ok, conn: conn, org: org, user: user, technician: technician, job: job, customer: customer}
  end

  describe "Job Completion Flow" do
    test "renders completion form", %{conn: conn, job: job, customer: customer} do
      {:ok, _view, html} = live(conn, ~p"/tech/jobs/#{job.number}/complete")

      assert html =~ "Complete Job"
      assert html =~ customer.name
      assert html =~ job.number
      assert html =~ "Work Performed"
    end

    test "validates required fields", %{conn: conn, job: job} do
      {:ok, view, _html} = live(conn, ~p"/tech/jobs/#{job.number}/complete")

      result =
        view
        |> form("#job-completion-form", job: %{work_performed: ""})
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end

    test "completes job successfully", %{conn: conn, job: job, technician: technician} do
      {:ok, view, _html} = live(conn, ~p"/tech/jobs/#{job.number}/complete")

      view
      |> form("#job-completion-form",
        job: %{
          work_performed: "Fixed the AC leak and recharged refrigerant.",
          actual_amount: "150.00",
          customer_signature: "data:image/png;base64,sample"
        }
      )
      |> render_submit()
      |> follow_redirect(conn, ~p"/tech/dashboard")

      # Verify job is completed
      updated_job = FieldHub.Jobs.get_job!(job.organization_id, job.id)
      assert updated_job.status == "completed"
      assert updated_job.work_performed == "Fixed the AC leak and recharged refrigerant."
      assert Decimal.to_string(updated_job.actual_amount) == "150.00"
      assert updated_job.customer_signature == "data:image/png;base64,sample"
      assert updated_job.completed_at != nil

      # Verify technician is available
      updated_tech = FieldHub.Repo.get!(FieldHub.Dispatch.Technician, technician.id)
      assert updated_tech.status == "available"
    end

    test "redirects if job is not in a completion-ready state", %{
      conn: conn,
      org: org,
      customer: customer,
      technician: technician
    } do
      # Job is still scheduled
      job =
        job_fixture(org.id, %{
          customer_id: customer.id,
          technician_id: technician.id,
          status: "scheduled",
          scheduled_date: Date.utc_today()
        })

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/tech/jobs/#{job.number}/complete")

      assert path == ~p"/tech/jobs/#{job.number}"
      assert flash["error"] =~ "must be started"
    end
  end
end
