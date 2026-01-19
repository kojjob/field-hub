defmodule FieldHub.ReportsTest do
  use FieldHub.DataCase

  alias FieldHub.Reports
  alias FieldHub.Jobs

  import FieldHub.AccountsFixtures
  import FieldHub.DispatchFixtures

  alias FieldHub.Accounts.Scope

  describe "reports" do
    setup do
      org = organization_fixture()
      user = user_fixture(organization_id: org.id)
      scope = Scope.for_user(user)
      tech = technician_fixture(org.id)

      # Helper to create completed jobs
      create_completed_job = fn attrs ->
        # First create the job with basic info
        {:ok, job} =
          Jobs.create_job(user, %{
            organization_id: org.id,
            technician_id: tech.id,
            title: "Test Job #{System.unique_integer([:positive])}",
            description: "Fixing things"
          })

        # Then update it to completed status with additional fields
        job
        |> Ecto.Changeset.change(Map.merge(%{
          status: "completed",
          completed_at: DateTime.utc_now() |> DateTime.truncate(:second),
          started_at: DateTime.utc_now() |> DateTime.add(-3600, :second) |> DateTime.truncate(:second),
          actual_amount: Decimal.new("100.00")
        }, attrs))
        |> FieldHub.Repo.update!()
      end

      %{scope: scope, org: org, tech: tech, create_completed_job: create_completed_job}
    end

    test "get_kpis/2 calculates summary metrics", %{scope: scope, create_completed_job: create_job} do
      # Job 1: Completed today, 1 hour duration, $150
      start_time = DateTime.utc_now() |> DateTime.add(-3600, :second) |> DateTime.truncate(:second)
      end_time = DateTime.utc_now() |> DateTime.truncate(:second)
      create_job.(%{
        started_at: start_time,
        completed_at: end_time,
        actual_amount: Decimal.new("150.00")
      })

      # Job 2: Completed yesterday, 2 hours duration, $250
      yesterday_start = DateTime.utc_now() |> DateTime.add(-86400 - 7200, :second) |> DateTime.truncate(:second)
      yesterday_end = DateTime.utc_now() |> DateTime.add(-86400, :second) |> DateTime.truncate(:second)
      create_job.(%{
        started_at: yesterday_start,
        completed_at: yesterday_end,
        actual_amount: Decimal.new("250.00")
      })

      # Job 3: Completed 60 days ago (outside range), $500
      old_date = DateTime.utc_now() |> DateTime.add(-60 * 86400, :second) |> DateTime.truncate(:second)
      create_job.(%{
        completed_at: old_date,
        started_at: old_date |> DateTime.add(-3600, :second),
        actual_amount: Decimal.new("500.00")
      })

      # Fetch KPIs for last 30 days
      range = {Date.utc_today() |> Date.add(-30), Date.utc_today()}
      kpis = Reports.get_kpis(scope, range)

      # Revenue: 150 + 250 = 400 (Job 3 excluded)
      assert kpis.total_revenue == Decimal.new("400.00")

      # Duration: (60 + 120) / 2 = 90 mins
      assert kpis.avg_job_duration_minutes == 90

      # Completed Jobs count
      assert kpis.completed_jobs_count == 2
    end

    test "get_technician_performance/2 returns stats per tech", %{scope: scope, tech: tech, create_completed_job: create_job} do
      create_job.(%{actual_amount: Decimal.new("100.00")})
      create_job.(%{actual_amount: Decimal.new("200.00")})

      range = {Date.utc_today() |> Date.add(-30), Date.utc_today()}
      stats = Reports.get_technician_performance(scope, range)

      assert length(stats) == 1
      tech_stat = List.first(stats)
      assert tech_stat.technician_id == tech.id
      assert tech_stat.name == tech.name
      assert tech_stat.jobs_completed == 2
      assert tech_stat.total_revenue == Decimal.new("300.00")
    end

    test "get_job_completion_trend/2 returns weekly counts", %{scope: scope, create_completed_job: create_job} do
      # Create job completed today
      create_job.(%{})

      range = {Date.utc_today() |> Date.add(-30), Date.utc_today()}
      trend = Reports.get_job_completion_trend(scope, range)

      # Should return a list of periods (e.g., weeks or days)
      assert is_list(trend)
      # Basic check that we have data points
      assert Enum.any?(trend, fn point -> point.count > 0 end)
    end

    test "get_recent_completed_jobs/2 returns latest jobs", %{scope: scope, create_completed_job: create_job} do
      job1 = create_job.(%{completed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      _job2 = create_job.(%{completed_at: DateTime.utc_now() |> DateTime.add(-100, :second) |> DateTime.truncate(:second)})

      jobs = Reports.get_recent_completed_jobs(scope, 5)

      assert length(jobs) == 2
      assert List.first(jobs).id == job1.id
    end
  end
end
