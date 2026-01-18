defmodule FieldHub.Jobs.JobEventTest do
  use FieldHub.DataCase, async: true

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
end
