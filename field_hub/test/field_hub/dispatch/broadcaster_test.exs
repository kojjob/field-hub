defmodule FieldHub.Dispatch.BroadcasterTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Dispatch.Broadcaster
  alias FieldHub.Jobs.Job
  alias FieldHub.Dispatch.Technician
  alias Phoenix.PubSub

  describe "broadcasts" do
    test "broadcast_job_created/1 broadcasts to org topic" do
      job = %Job{id: 1, organization_id: 123, title: "New Job"}
      topic = "org:123"

      PubSub.subscribe(FieldHub.PubSub, topic)

      assert {:ok, ^job} = Broadcaster.broadcast_job_created(job)

      assert_receive {:job_created, ^job}
    end

    test "broadcast_job_updated/1 broadcasts to org topic" do
      job = %Job{id: 2, organization_id: 123, title: "Updated Job"}
      topic = "org:123"

      PubSub.subscribe(FieldHub.PubSub, topic)

      assert {:ok, ^job} = Broadcaster.broadcast_job_updated(job)

      assert_receive {:job_updated, ^job}
    end

    test "broadcast_job_updated/1 broadcasts to technician topic if assigned" do
      job = %Job{id: 3, organization_id: 123, technician_id: 456, title: "Assigned Job"}
      org_topic = "org:123"
      tech_topic = "tech:456"

      PubSub.subscribe(FieldHub.PubSub, org_topic)
      PubSub.subscribe(FieldHub.PubSub, tech_topic)

      assert {:ok, ^job} = Broadcaster.broadcast_job_updated(job)

      assert_receive {:job_updated, ^job}
      assert_receive {:job_updated, ^job}
    end

    test "broadcast_technician_location/1 broadcasts to org topic" do
      tech = %Technician{id: 789, organization_id: 123, current_lat: 10.0, current_lng: 20.0}
      topic = "org:123"

      PubSub.subscribe(FieldHub.PubSub, topic)

      assert {:ok, ^tech} = Broadcaster.broadcast_technician_location(tech)

      assert_receive {:technician_location_updated, ^tech}
    end

    test "broadcast_technician_status/1 broadcasts to org topic" do
      tech = %Technician{id: 789, organization_id: 123, status: "busy"}
      topic = "org:123"

      PubSub.subscribe(FieldHub.PubSub, topic)

      assert {:ok, ^tech} = Broadcaster.broadcast_technician_status(tech)

      assert_receive {:technician_status_updated, ^tech}
    end
  end
end
