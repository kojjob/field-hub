defmodule FieldHub.JobsTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Jobs
  alias FieldHub.Jobs.Job
  alias FieldHub.Accounts
  alias FieldHub.CRM
  alias FieldHub.Dispatch

  setup do
    {:ok, org} = Accounts.create_organization(%{name: "Job Test Org", slug: "job-test-org"})

    {:ok, customer} =
      CRM.create_customer(org.id, %{name: "Test Customer", email: "c@example.com"})

    %{org: org, customer: customer}
  end

  describe "list_jobs/1" do
    test "returns all jobs for the organization", %{org: org, customer: customer} do
      job1 = job_fixture(org.id, customer.id, %{title: "Job 1"})
      job2 = job_fixture(org.id, customer.id, %{title: "Job 2"})

      jobs = Jobs.list_jobs(org.id)

      assert length(jobs) == 2
      assert Enum.any?(jobs, &(&1.id == job1.id))
      assert Enum.any?(jobs, &(&1.id == job2.id))
    end

    test "does not return jobs from other organizations", %{org: org, customer: customer} do
      {:ok, other_org} =
        Accounts.create_organization(%{name: "Other Org", slug: "other-org-jobs"})

      {:ok, other_cust} = CRM.create_customer(other_org.id, %{name: "Other C"})
      _other_job = job_fixture(other_org.id, other_cust.id, %{title: "Other Job"})
      my_job = job_fixture(org.id, customer.id, %{title: "My Job"})

      jobs = Jobs.list_jobs(org.id)

      assert length(jobs) == 1
      assert hd(jobs).id == my_job.id
    end
  end

  describe "get_job!/2" do
    test "returns the job with given id", %{org: org, customer: customer} do
      job = job_fixture(org.id, customer.id)
      assert Jobs.get_job!(org.id, job.id).id == job.id
    end

    test "raises if job belongs to different organization", %{org: org, customer: _customer} do
      {:ok, other_org} = Accounts.create_organization(%{name: "Other Org", slug: "other-2"})
      {:ok, other_cust} = CRM.create_customer(other_org.id, %{name: "C2"})
      other_job = job_fixture(other_org.id, other_cust.id)

      assert_raise Ecto.NoResultsError, fn ->
        Jobs.get_job!(org.id, other_job.id)
      end
    end
  end

  describe "create_job/2" do
    test "creates job with valid data and auto-generated number", %{org: org, customer: customer} do
      valid_attrs = %{
        title: "Fix AC",
        description: "Not cooling",
        customer_id: customer.id,
        status: "unscheduled"
      }

      assert {:ok, %Job{} = job} = Jobs.create_job(org.id, valid_attrs)
      assert job.title == "Fix AC"
      assert job.organization_id == org.id
      assert job.customer_id == customer.id
      # Starts with JOB-
      assert job.number =~ "JOB-"
    end

    test "returns error with invalid data", %{org: org} do
      assert {:error, %Ecto.Changeset{}} = Jobs.create_job(org.id, %{})
    end
  end

  describe "update_job/2" do
    test "updates job with valid data", %{org: org, customer: customer} do
      job = job_fixture(org.id, customer.id)
      update_attrs = %{title: "Updated Title", description: "Updated Desc"}

      assert {:ok, updated} = Jobs.update_job(job, update_attrs)
      assert updated.title == "Updated Title"
      assert updated.description == "Updated Desc"
    end
  end

  describe "list_jobs_for_date/2" do
    test "returns jobs scheduled for specific date", %{org: org, customer: customer} do
      today = Date.utc_today()
      tomorrow = Date.add(today, 1)

      # Create a technician for scheduled jobs
      {:ok, tech} =
        Dispatch.create_technician(org.id, %{name: "Tech Date", email: "td@example.com"})

      job_today =
        job_fixture(org.id, customer.id, %{scheduled_date: today, technician_id: tech.id})

      _job_tomorrow =
        job_fixture(org.id, customer.id, %{scheduled_date: tomorrow, technician_id: tech.id})

      _job_unscheduled = job_fixture(org.id, customer.id, %{scheduled_date: nil})

      jobs = Jobs.list_jobs_for_date(org.id, today)

      assert length(jobs) == 1
      assert hd(jobs).id == job_today.id
    end
  end

  describe "list_unassigned_jobs/1" do
    test "returns jobs without technician or without scheduled date", %{
      org: org,
      customer: customer
    } do
      # Job without technician (unscheduled by default)
      unassigned = job_fixture(org.id, customer.id, %{status: "unscheduled"})

      # Job with technician and scheduled date should NOT appear
      {:ok, tech} = Dispatch.create_technician(org.id, %{name: "Tech 1", email: "t1@example.com"})

      _assigned =
        job_fixture(org.id, customer.id, %{
          status: "scheduled",
          scheduled_date: Date.utc_today(),
          technician_id: tech.id
        })

      # Completed job should NOT appear
      _completed = job_fixture(org.id, customer.id, %{status: "completed"})

      jobs = Jobs.list_unassigned_jobs(org.id)

      assert length(jobs) == 1
      assert hd(jobs).id == unassigned.id
    end
  end

  describe "assign_job/3" do
    test "assigns technician to job and updates status", %{org: org, customer: customer} do
      job = job_fixture(org.id, customer.id, %{status: "scheduled"})
      {:ok, tech} = Dispatch.create_technician(org.id, %{name: "Tech 1", email: "t1@example.com"})

      assert {:ok, updated} = Jobs.assign_job(job, tech.id)
      assert updated.technician_id == tech.id
      assert updated.status == "dispatched"
    end
  end

  describe "job workflow" do
    test "full lifecycle", %{org: org, customer: customer} do
      job = job_fixture(org.id, customer.id, %{status: "unscheduled"})

      # Schedule
      tomorrow = Date.add(Date.utc_today(), 1)

      assert {:ok, scheduled} =
               Jobs.schedule_job(job, %{
                 scheduled_date: tomorrow,
                 scheduled_start: ~T[09:00:00],
                 scheduled_end: ~T[11:00:00]
               })

      assert scheduled.status == "scheduled"
      assert scheduled.scheduled_date == tomorrow

      # Assign
      {:ok, tech} =
        Dispatch.create_technician(org.id, %{name: "Tech Flow", email: "flow@example.com"})

      assert {:ok, dispatched} = Jobs.assign_job(scheduled, tech.id)
      assert dispatched.status == "dispatched"

      # Start Travel
      assert {:ok, en_route} = Jobs.start_travel(dispatched)
      assert en_route.status == "en_route"
      assert en_route.travel_started_at

      # Arrive
      assert {:ok, on_site} = Jobs.arrive_on_site(en_route)
      assert on_site.status == "on_site"
      assert on_site.arrived_at

      # Start Work
      assert {:ok, working} = Jobs.start_work(on_site)
      assert working.status == "in_progress"
      assert working.started_at

      # Complete
      assert {:ok, completed} =
               Jobs.complete_job(working, %{
                 work_performed: "Fixed it",
                 customer_signature: "Sig",
                 actual_amount: 150
               })

      assert completed.status == "completed"
      assert completed.completed_at
    end

    test "cancelling a job", %{org: org, customer: customer} do
      job = job_fixture(org.id, customer.id)
      assert {:ok, cancelled} = Jobs.cancel_job(job, "Customer request")
      assert cancelled.status == "cancelled"
      assert cancelled.internal_notes =~ "Cancelled: Customer request"
    end
  end

  defp job_fixture(org_id, customer_id, attrs \\ %{}) do
    defaults = %{
      title: "Test Job",
      description: "Test Description",
      customer_id: customer_id
    }

    {:ok, job} =
      defaults
      |> Map.merge(attrs)
      |> then(&Jobs.create_job(org_id, &1))

    job
  end
end
