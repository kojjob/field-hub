defmodule FieldHubWeb.TechSyncControllerTest do
  @moduledoc """
  Tests for the offline sync API used by technicians.

  This controller processes queued job updates that were made while
  the technician was offline. When they come back online, the PWA
  syncs all pending updates via this endpoint.

  Test cases cover:
  - Authentication requirements
  - All action types (start_travel, arrive, start_work, complete)
  - Error handling for invalid jobs/technicians
  - Proper status transitions
  """

  use FieldHubWeb.ConnCase

  import FieldHub.AccountsFixtures
  import FieldHub.DispatchFixtures
  import FieldHub.JobsFixtures
  import FieldHub.CRMFixtures

  alias FieldHub.Jobs

  setup %{conn: conn} do
    org = organization_fixture()
    user = user_fixture(%{organization_id: org.id})
    technician = technician_fixture(org.id, %{user_id: user.id})
    customer = customer_fixture(org.id)

    # Create a job assigned to this technician
    job =
      job_fixture(org.id, %{
        customer_id: customer.id,
        technician_id: technician.id,
        status: "dispatched",
        scheduled_date: Date.utc_today(),
        scheduled_start: ~T[10:00:00]
      })

    {:ok, conn: conn, org: org, user: user, technician: technician, customer: customer, job: job}
  end

  describe "POST /api/tech/sync - authentication" do
    test "returns 401 when not authenticated", %{conn: conn, job: job} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{action: "start_travel", job_id: job.id})

      assert json_response(conn, 401)["error"] == "Unauthorized"
    end

    test "returns 403 when user is not a technician", %{conn: conn, org: org, job: job} do
      # Create a user without an associated technician
      non_tech_user = user_fixture(%{organization_id: org.id})

      conn =
        conn
        |> log_in_user(non_tech_user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{action: "start_travel", job_id: job.id})

      assert json_response(conn, 403)["error"] == "Not a technician"
    end
  end

  describe "POST /api/tech/sync - start_travel action" do
    test "successfully starts travel for assigned job", %{conn: conn, user: user, job: job} do
      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "start_travel",
          job_id: job.id,
          offline_timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        })

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["status"] == "en_route"
      assert response["synced_action"] == "start_travel"

      # Verify job was actually updated
      updated_job = Jobs.get_job!(job.organization_id, job.id)
      assert updated_job.status == "en_route"
      assert updated_job.travel_started_at != nil
    end

    test "includes offline_timestamp in response", %{conn: conn, user: user, job: job} do
      timestamp = "2026-01-20T10:30:00Z"

      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "start_travel",
          job_id: job.id,
          offline_timestamp: timestamp
        })

      response = json_response(conn, 200)
      assert response["offline_timestamp"] == timestamp
    end
  end

  describe "POST /api/tech/sync - arrive action" do
    test "successfully marks arrival for en_route job", %{conn: conn, user: user, job: job} do
      # First start travel
      {:ok, job} = Jobs.start_travel(job)

      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "arrive",
          job_id: job.id
        })

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["status"] == "on_site"

      # Verify job was updated
      updated_job = Jobs.get_job!(job.organization_id, job.id)
      assert updated_job.status == "on_site"
      assert updated_job.arrived_at != nil
    end
  end

  describe "POST /api/tech/sync - start_work action" do
    test "successfully starts work for on_site job", %{conn: conn, user: user, job: job} do
      # Progress job to on_site
      {:ok, job} = Jobs.start_travel(job)
      {:ok, job} = Jobs.arrive_on_site(job)

      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "start_work",
          job_id: job.id
        })

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["status"] == "in_progress"

      # Verify job was updated
      updated_job = Jobs.get_job!(job.organization_id, job.id)
      assert updated_job.status == "in_progress"
      assert updated_job.started_at != nil
    end
  end

  describe "POST /api/tech/sync - complete action" do
    test "successfully completes an in_progress job", %{conn: conn, user: user, job: job} do
      # Progress job to in_progress
      {:ok, job} = Jobs.start_travel(job)
      {:ok, job} = Jobs.arrive_on_site(job)
      {:ok, job} = Jobs.start_work(job)

      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "complete",
          job_id: job.id,
          data: %{
            work_performed: "Fixed the issue and tested",
            amount_charged: "150.00"
          }
        })

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["status"] == "completed"

      # Verify job was updated with completion details
      updated_job = Jobs.get_job!(job.organization_id, job.id)
      assert updated_job.status == "completed"
      assert updated_job.work_performed == "Fixed the issue and tested"
      assert updated_job.completed_at != nil
    end

    test "handles completion without amount", %{conn: conn, user: user, job: job} do
      {:ok, job} = Jobs.start_travel(job)
      {:ok, job} = Jobs.arrive_on_site(job)
      {:ok, job} = Jobs.start_work(job)

      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "complete",
          job_id: job.id,
          data: %{
            work_performed: "Completed without charge"
          }
        })

      response = json_response(conn, 200)
      assert response["success"] == true
    end
  end

  describe "POST /api/tech/sync - error handling" do
    test "returns 404 for non-existent job", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "start_travel",
          job_id: 999_999_999
        })

      assert json_response(conn, 404)["error"] == "Job not found"
    end

    test "returns 403 for job not assigned to technician", %{conn: conn, org: org, user: user} do
      # Create another technician's job
      other_tech = technician_fixture(org.id)
      customer = customer_fixture(org.id)

      other_job =
        job_fixture(org.id, %{
          customer_id: customer.id,
          technician_id: other_tech.id,
          status: "dispatched"
        })

      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "start_travel",
          job_id: other_job.id
        })

      assert json_response(conn, 403)["error"] == "Job not assigned to you"
    end

    test "returns 400 for missing required fields", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{})

      assert json_response(conn, 400)["error"] =~ "Missing required fields"
    end

    test "returns error for unknown action", %{conn: conn, user: user, job: job} do
      conn =
        conn
        |> log_in_user(user)
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tech/sync", %{
          action: "invalid_action",
          job_id: job.id
        })

      assert json_response(conn, 422)["error"] =~ "Unknown action"
    end
  end

  describe "POST /api/tech/sync - full offline sync simulation" do
    @tag :integration
    test "simulates complete offline sync workflow", %{conn: _conn, user: user, job: job} do
      # This test simulates what happens when a technician:
      # 1. Goes offline
      # 2. Performs multiple status changes
      # 3. Comes back online
      # 4. Syncs all changes in order

      # Simulate queued offline updates (in order they were made)
      offline_updates = [
        %{
          action: "start_travel",
          job_id: job.id,
          offline_timestamp: "2026-01-20T10:00:00Z"
        },
        %{
          action: "arrive",
          job_id: job.id,
          offline_timestamp: "2026-01-20T10:15:00Z"
        },
        %{
          action: "start_work",
          job_id: job.id,
          offline_timestamp: "2026-01-20T10:20:00Z"
        },
        %{
          action: "complete",
          job_id: job.id,
          data: %{work_performed: "Completed while offline"},
          offline_timestamp: "2026-01-20T11:30:00Z"
        }
      ]

      # Process each update as if coming back online
      results =
        Enum.map(offline_updates, fn update ->
          conn =
            build_conn()
            |> log_in_user(user)
            |> put_req_header("content-type", "application/json")
            |> post(~p"/api/tech/sync", update)

          json_response(conn, 200)
        end)

      # Verify all synced successfully
      assert Enum.all?(results, & &1["success"])

      # Verify final job state
      final_job = Jobs.get_job!(job.organization_id, job.id)
      assert final_job.status == "completed"
      assert final_job.travel_started_at != nil
      assert final_job.arrived_at != nil
      assert final_job.started_at != nil
      assert final_job.completed_at != nil
      assert final_job.work_performed == "Completed while offline"
    end
  end
end
