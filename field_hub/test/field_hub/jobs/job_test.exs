defmodule FieldHub.Jobs.JobTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Jobs.Job
  alias FieldHub.Accounts.Organization
  alias FieldHub.CRM.Customer
  alias FieldHub.Dispatch.Technician

  setup do
    {:ok, org} =
      %Organization{}
      |> Organization.changeset(%{name: "Test Org", slug: "test-org"})
      |> Repo.insert()

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{name: "Jane Doe", organization_id: org.id})
      |> Repo.insert()

    {:ok, tech} =
      %Technician{}
      |> Technician.changeset(%{name: "John Smith", organization_id: org.id})
      |> Repo.insert()

    %{organization: org, customer: customer, technician: tech}
  end

  describe "changeset/2" do
    test "valid attributes create a valid changeset", %{organization: org, customer: customer} do
      attrs = %{
        organization_id: org.id,
        customer_id: customer.id,
        number: "JOB-2026-001",
        title: "AC Not Cooling",
        description: "Customer reports AC unit not producing cold air",
        job_type: "service_call",
        priority: "high",
        status: "unscheduled",
        scheduled_date: ~D[2026-01-20],
        estimated_duration_minutes: 90
      }

      changeset = Job.changeset(%Job{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :title) == "AC Not Cooling"
    end

    test "requires organization_id" do
      changeset = Job.changeset(%Job{}, %{title: "Test", number: "JOB-001"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).organization_id
    end

    test "requires title" do
      changeset = Job.changeset(%Job{}, %{organization_id: 1, number: "JOB-001"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
    end

    test "requires number" do
      changeset = Job.changeset(%Job{}, %{organization_id: 1, title: "Test"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).number
    end

    test "validates job_type values" do
      valid_types = ["service_call", "installation", "maintenance", "emergency", "estimate"]

      for type <- valid_types do
        attrs = %{organization_id: 1, title: "Test", number: "JOB-001", job_type: type}
        changeset = Job.changeset(%Job{}, attrs)
        refute Map.has_key?(errors_on(changeset), :job_type), "Expected #{type} to be valid"
      end

      invalid_attrs = %{organization_id: 1, title: "Test", number: "JOB-001", job_type: "invalid"}
      changeset = Job.changeset(%Job{}, invalid_attrs)
      assert Map.has_key?(errors_on(changeset), :job_type)
    end

    test "validates priority values" do
      valid_priorities = ["low", "normal", "high", "urgent"]

      for priority <- valid_priorities do
        attrs = %{organization_id: 1, title: "Test", number: "JOB-001", priority: priority}
        changeset = Job.changeset(%Job{}, attrs)
        refute Map.has_key?(errors_on(changeset), :priority), "Expected #{priority} to be valid"
      end
    end

    test "validates status values" do
      valid_statuses = [
        "unscheduled",
        "scheduled",
        "dispatched",
        "en_route",
        "on_site",
        "in_progress",
        "completed",
        "cancelled",
        "on_hold"
      ]

      for status <- valid_statuses do
        attrs = %{organization_id: 1, title: "Test", number: "JOB-001", status: status}
        changeset = Job.changeset(%Job{}, attrs)
        refute Map.has_key?(errors_on(changeset), :status), "Expected #{status} to be valid"
      end
    end

    test "estimated_duration_minutes must be positive", %{organization: org} do
      valid_attrs = %{
        organization_id: org.id,
        title: "Test",
        number: "JOB-001",
        estimated_duration_minutes: 60
      }

      changeset = Job.changeset(%Job{}, valid_attrs)
      assert changeset.valid?

      invalid_attrs = %{valid_attrs | estimated_duration_minutes: -30}
      changeset = Job.changeset(%Job{}, invalid_attrs)
      assert "must be greater than 0" in errors_on(changeset).estimated_duration_minutes
    end

    test "quoted_amount must be non-negative when provided", %{organization: org} do
      valid_attrs = %{
        organization_id: org.id,
        title: "Test",
        number: "JOB-001",
        quoted_amount: Decimal.new("150.00")
      }

      changeset = Job.changeset(%Job{}, valid_attrs)
      assert changeset.valid?

      invalid_attrs = %{valid_attrs | quoted_amount: Decimal.new("-50.00")}
      changeset = Job.changeset(%Job{}, invalid_attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).quoted_amount
    end
  end

  describe "schedule_changeset/2" do
    test "sets scheduling fields and updates status", %{organization: org} do
      {:ok, job} =
        %Job{}
        |> Job.changeset(%{
          organization_id: org.id,
          title: "Test Job",
          number: "JOB-001",
          status: "unscheduled"
        })
        |> Repo.insert()

      changeset =
        Job.schedule_changeset(job, %{
          scheduled_date: ~D[2026-01-20],
          scheduled_start: ~T[09:00:00],
          scheduled_end: ~T[11:00:00]
        })

      assert changeset.valid?
      assert get_change(changeset, :scheduled_date) == ~D[2026-01-20]
      assert get_change(changeset, :status) == "scheduled"
    end

    test "validates scheduled_end is after scheduled_start" do
      changeset =
        Job.schedule_changeset(%Job{}, %{
          scheduled_date: ~D[2026-01-20],
          scheduled_start: ~T[11:00:00],
          # Before start time
          scheduled_end: ~T[09:00:00]
        })

      assert "must be after start time" in errors_on(changeset).scheduled_end
    end
  end

  describe "assign_changeset/2" do
    test "assigns technician and updates status", %{organization: org, technician: tech} do
      {:ok, job} =
        %Job{}
        |> Job.changeset(%{
          organization_id: org.id,
          title: "Test Job",
          number: "JOB-001",
          status: "scheduled",
          scheduled_date: ~D[2026-01-20]
        })
        |> Repo.insert()

      changeset = Job.assign_changeset(job, tech.id)

      assert changeset.valid?
      assert get_change(changeset, :technician_id) == tech.id
      assert get_change(changeset, :status) == "dispatched"
    end
  end

  describe "status transitions" do
    test "start_travel_changeset/1 transitions from dispatched to en_route", %{organization: org} do
      {:ok, job} =
        %Job{}
        |> Job.changeset(%{
          organization_id: org.id,
          title: "Test",
          number: "JOB-001",
          status: "dispatched"
        })
        |> Repo.insert()

      changeset = Job.start_travel_changeset(job)

      assert changeset.valid?
      assert get_change(changeset, :status) == "en_route"
      assert get_change(changeset, :travel_started_at)
    end

    test "arrive_changeset/1 transitions from en_route to on_site", %{organization: org} do
      {:ok, job} =
        %Job{}
        |> Job.changeset(%{
          organization_id: org.id,
          title: "Test",
          number: "JOB-001",
          status: "en_route"
        })
        |> Repo.insert()

      changeset = Job.arrive_changeset(job)

      assert changeset.valid?
      assert get_change(changeset, :status) == "on_site"
      assert get_change(changeset, :arrived_at)
    end

    test "start_work_changeset/1 transitions from on_site to in_progress", %{organization: org} do
      {:ok, job} =
        %Job{}
        |> Job.changeset(%{
          organization_id: org.id,
          title: "Test",
          number: "JOB-001",
          status: "on_site"
        })
        |> Repo.insert()

      changeset = Job.start_work_changeset(job)

      assert changeset.valid?
      assert get_change(changeset, :status) == "in_progress"
      assert get_change(changeset, :started_at)
    end

    test "complete_changeset/2 transitions from in_progress to completed", %{
      organization: org,
      technician: tech
    } do
      {:ok, job} =
        %Job{}
        |> Job.changeset(%{
          organization_id: org.id,
          title: "Test",
          number: "JOB-001",
          status: "in_progress"
        })
        |> Repo.insert()

      completion_attrs = %{
        work_performed: "Replaced compressor and recharged refrigerant",
        actual_amount: Decimal.new("350.00"),
        completed_by_id: tech.id
      }

      changeset = Job.complete_changeset(job, completion_attrs)

      assert changeset.valid?
      assert get_change(changeset, :status) == "completed"
      assert get_change(changeset, :completed_at)

      assert get_change(changeset, :work_performed) ==
               "Replaced compressor and recharged refrigerant"
    end

    test "cancel_changeset/2 can cancel from any status", %{organization: org} do
      for status <- [
            "unscheduled",
            "scheduled",
            "dispatched",
            "en_route",
            "on_site",
            "in_progress"
          ] do
        {:ok, job} =
          %Job{}
          |> Job.changeset(%{
            organization_id: org.id,
            title: "Test",
            number: "JOB-#{status}",
            status: status
          })
          |> Repo.insert()

        changeset = Job.cancel_changeset(job, "Customer cancelled")

        assert changeset.valid?, "Expected cancellation from #{status} to be valid"
        assert get_change(changeset, :status) == "cancelled"
      end
    end
  end

  describe "generate_job_number/1" do
    test "generates sequential job number for organization", %{organization: org} do
      number1 = Job.generate_job_number(org.id)
      number2 = Job.generate_job_number(org.id)

      assert String.starts_with?(number1, "JOB-")
      assert number1 != number2
    end
  end
end
