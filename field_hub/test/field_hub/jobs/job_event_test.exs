defmodule FieldHub.Jobs.JobEventTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Jobs
  alias FieldHub.Jobs.{Job, JobEvent}
  alias FieldHub.Accounts.Organization

  setup do
    {:ok, org} =
      %Organization{}
      |> Organization.changeset(%{name: "Test Org", slug: "test-org"})
      |> Repo.insert()

    {:ok, job} =
      %Job{}
      |> Job.changeset(%{
        organization_id: org.id,
        title: "Test Job",
        number: "JOB-001"
      })
      |> Repo.insert()

    %{organization: org, job: job}
  end

  describe "changeset/2" do
    test "valid attributes create a valid changeset", %{job: job} do
      attrs = %{
        job_id: job.id,
        event_type: "status_changed",
        old_value: %{status: "unscheduled"},
        new_value: %{status: "scheduled"},
        metadata: %{ip: "192.168.1.1"}
      }

      changeset = JobEvent.changeset(%JobEvent{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :event_type) == "status_changed"
    end

    test "requires job_id" do
      changeset = JobEvent.changeset(%JobEvent{}, %{event_type: "created"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).job_id
    end

    test "requires event_type" do
      changeset = JobEvent.changeset(%JobEvent{}, %{job_id: 1})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).event_type
    end

    test "validates event_type values" do
      valid_types = [
        "created",
        "updated",
        "status_changed",
        "assigned",
        "unassigned",
        "scheduled",
        "rescheduled",
        "note_added",
        "photo_added",
        "signature_captured",
        "payment_collected"
      ]

      for type <- valid_types do
        attrs = %{job_id: 1, event_type: type}
        changeset = JobEvent.changeset(%JobEvent{}, attrs)
        refute Map.has_key?(errors_on(changeset), :event_type), "Expected #{type} to be valid"
      end
    end
  end

  describe "create_event/3" do
    test "creates a job event with timestamp", %{job: job} do
      {:ok, event} = JobEvent.create_event(job, "created", %{})

      assert event.job_id == job.id
      assert event.event_type == "created"
      assert event.inserted_at
    end

    test "creates status change event with old and new values", %{job: job} do
      {:ok, event} =
        JobEvent.create_event(job, "status_changed", %{
          old_value: %{status: "unscheduled"},
          new_value: %{status: "scheduled"}
        })

      assert event.old_value == %{status: "unscheduled"}
      assert event.new_value == %{status: "scheduled"}
    end

    test "includes metadata when provided", %{job: job} do
      metadata = %{
        user_agent: "Mozilla/5.0",
        ip_address: "192.168.1.1",
        lat: 40.7128,
        lng: -74.0060
      }

      {:ok, event} = JobEvent.create_event(job, "status_changed", %{metadata: metadata})

      assert event.metadata["user_agent"] == "Mozilla/5.0"
      assert event.metadata["lat"] == 40.7128
    end
  end

  describe "for_job/1" do
    test "returns events in chronological order", %{job: job} do
      {:ok, _event1} = JobEvent.create_event(job, "created", %{})
      # Ensure different timestamps
      Process.sleep(10)
      {:ok, _event2} = JobEvent.create_event(job, "scheduled", %{})
      Process.sleep(10)
      {:ok, _event3} = JobEvent.create_event(job, "assigned", %{})

      events = JobEvent.for_job(job.id) |> Repo.all()

      assert length(events) == 3
      assert Enum.map(events, & &1.event_type) == ["created", "scheduled", "assigned"]
    end
  end

  describe "integration with FieldHub.Jobs context" do
    alias FieldHub.Dispatch.Technician

    test "create_job/2 creates 'created' event", %{organization: org} do
      {:ok, job} = Jobs.create_job(org.id, %{title: "New Job"})

      assert [event] = Repo.all(JobEvent.for_job(job.id))
      assert event.event_type == "created"
      assert event.new_value["title"] == "New Job"
    end

    test "update_job/2 creates 'updated' event", %{job: job} do
      {:ok, updated_job} = Jobs.update_job(job, %{title: "Updated Title"})

      assert [event] = Repo.all(JobEvent.for_job(updated_job.id))
      assert event.event_type == "updated"
      # Old value captured from job struct which has title "Test Job" (from setup)
      # Sanitize job now includes title
      assert event.old_value["title"] == "Test Job"
      assert event.new_value["title"] == "Updated Title"
    end

    test "assign_job/2 creates 'assigned' event", %{job: job, organization: org} do
      {:ok, tech} =
        %Technician{}
        |> Technician.changeset(%{
          organization_id: org.id,
          name: "Tech 1",
          email: "tech@test.com",
          status: "available"
        })
        |> Repo.insert()

      {:ok, updated_job} = Jobs.assign_job(job, tech.id)

      assert [event] = Repo.all(JobEvent.for_job(updated_job.id))
      assert event.event_type == "assigned"
      assert event.technician_id == tech.id
      assert event.new_value["status"] == "dispatched"
    end

    test "schedule_job/2 creates 'scheduled' event", %{job: job} do
      attrs = %{
        scheduled_date: Date.utc_today(),
        scheduled_start: ~T[10:00:00],
        scheduled_end: ~T[11:00:00]
      }

      {:ok, updated_job} = Jobs.schedule_job(job, attrs)

      assert [event] = Repo.all(JobEvent.for_job(updated_job.id))
      assert event.event_type == "scheduled"
      assert event.new_value["scheduled_date"]
    end

    test "start_travel/1 creates 'travel_started' event", %{job: job} do
      {:ok, updated_job} = Jobs.start_travel(job)

      assert [event] = Repo.all(JobEvent.for_job(updated_job.id))
      assert event.event_type == "travel_started"
      assert event.new_value["status"] == "en_route"
    end

    test "arrive_on_site/1 creates 'arrived' event", %{job: job} do
      {:ok, updated_job} = Jobs.arrive_on_site(job)

      assert [event] = Repo.all(JobEvent.for_job(updated_job.id))
      assert event.event_type == "arrived"
      assert event.new_value["status"] == "on_site"
    end

    test "start_work/1 creates 'work_started' event", %{job: job} do
      {:ok, updated_job} = Jobs.start_work(job)

      assert [event] = Repo.all(JobEvent.for_job(updated_job.id))
      assert event.event_type == "work_started"
      assert event.new_value["status"] == "in_progress"
    end

    test "complete_job/2 creates 'completed' event", %{job: job} do
      attrs = %{
        work_performed: "Fixed the leak",
        actual_amount: 150.00
      }

      {:ok, updated_job} = Jobs.complete_job(job, attrs)

      assert [event] = Repo.all(JobEvent.for_job(updated_job.id))
      assert event.event_type == "completed"
      assert event.new_value["status"] == "completed"
    end

    test "cancel_job/2 creates 'cancelled' event coverage", %{job: job} do
      {:ok, updated_job} = Jobs.cancel_job(job, "Customer cancelled")

      assert [event] = Repo.all(JobEvent.for_job(updated_job.id))
      assert event.event_type == "cancelled"
      assert event.new_value["status"] == "cancelled"
      assert event.metadata["reason"] == "Customer cancelled"
    end
  end
end
