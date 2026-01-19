defmodule FieldHubWeb.ReportControllerTest do
  use FieldHubWeb.ConnCase, async: true

  import FieldHub.DispatchFixtures
  import FieldHub.CRMFixtures

  alias FieldHub.Jobs

  describe "GET /reports/export" do
    setup :register_and_log_in_user

    setup %{user: user} do
      org = FieldHub.Accounts.get_organization!(user.organization_id)
      tech = technician_fixture(org.id)
      customer = customer_fixture(org.id)

      # Create a completed job for the report
      {:ok, job} =
        Jobs.create_job(org.id, %{
          title: "Completed Test Job",
          description: "Test description",
          technician_id: tech.id,
          customer_id: customer.id,
          status: "completed",
          actual_amount: Decimal.new("250.00")
        })

      # Set completed_at timestamp directly since changeset doesn't allow it
      completed_job =
        job
        |> Ecto.Changeset.change(%{completed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> FieldHub.Repo.update!()

      %{org: org, tech: tech, customer: customer, completed_job: completed_job}
    end

    test "exports completed jobs as CSV with explicit date range", %{
      conn: conn,
      completed_job: job,
      customer: customer,
      tech: tech
    } do
      start_date = Date.utc_today() |> Date.add(-30) |> Date.to_iso8601()
      end_date = Date.utc_today() |> Date.to_iso8601()

      conn = get(conn, ~p"/reports/export?start=#{start_date}&end=#{end_date}")

      assert response = response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["text/csv"]
      assert get_resp_header(conn, "content-disposition") |> hd() =~ "attachment"
      assert get_resp_header(conn, "content-disposition") |> hd() =~ ".csv"

      # Verify CSV content
      assert response =~ "Job Number,Title,Customer,Technician,Completed At,Amount"
      assert response =~ job.number
      assert response =~ "Completed Test Job"
      assert response =~ customer.name
      assert response =~ tech.name
      assert response =~ "250.00"
    end

    test "uses default date range when no params provided", %{conn: conn, completed_job: job} do
      conn = get(conn, ~p"/reports/export")

      assert response = response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["text/csv"]

      # Should include the job since it's within the last 30 days
      assert response =~ job.number
    end

    test "handles invalid date format gracefully", %{conn: conn, completed_job: job} do
      conn = get(conn, ~p"/reports/export?start=invalid&end=also-invalid")

      # Should fallback to default range and still work
      assert response = response(conn, 200)
      assert response =~ "Job Number"
      assert response =~ job.number
    end

    test "excludes jobs outside the date range", %{conn: conn, org: org, tech: tech} do
      # Create an old job (60 days ago)
      {:ok, old_job} =
        Jobs.create_job(org.id, %{
          title: "Old Job",
          description: "Old job description",
          technician_id: tech.id,
          status: "completed",
          actual_amount: Decimal.new("100.00")
        })

      old_date = DateTime.utc_now() |> DateTime.add(-60 * 24 * 60 * 60, :second) |> DateTime.truncate(:second)

      old_job
      |> Ecto.Changeset.change(%{completed_at: old_date})
      |> FieldHub.Repo.update!()

      # Request with a narrow recent range
      start_date = Date.utc_today() |> Date.add(-7) |> Date.to_iso8601()
      end_date = Date.utc_today() |> Date.to_iso8601()

      conn = get(conn, ~p"/reports/export?start=#{start_date}&end=#{end_date}")

      assert response = response(conn, 200)
      # Old job should not be in the export
      refute response =~ "Old Job"
    end

    test "returns empty CSV when no completed jobs exist in range", %{conn: conn} do
      # Request a date range in the future where no jobs exist
      start_date = Date.utc_today() |> Date.add(100) |> Date.to_iso8601()
      end_date = Date.utc_today() |> Date.add(130) |> Date.to_iso8601()

      conn = get(conn, ~p"/reports/export?start=#{start_date}&end=#{end_date}")

      assert response = response(conn, 200)
      # Should have header but no data rows
      assert response =~ "Job Number,Title,Customer,Technician,Completed At,Amount"
      # Only header line plus final newline
      lines = String.split(response, "\n", trim: true)
      assert length(lines) == 1
    end
  end

  describe "GET /reports/export - unauthenticated" do
    test "redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/reports/export")

      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end
end
