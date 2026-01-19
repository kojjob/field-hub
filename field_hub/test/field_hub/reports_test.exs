defmodule FieldHub.ReportsTest do
  use FieldHub.DataCase

  alias FieldHub.Reports
  alias FieldHub.Jobs

  import FieldHub.AccountsFixtures
  import FieldHub.DispatchFixtures
  import FieldHub.CRMFixtures

  alias FieldHub.Accounts.Scope

  describe "reports" do
    setup do
      org = organization_fixture()
      user = user_fixture(organization_id: org.id)
      current_scope = Scope.for_user(user)
      tech = technician_fixture(org.id)

      # Helper to create completed jobs
      # Note: completed_at and started_at must be set via direct update since
      # the main changeset doesn't allow them (they're set via workflow changesets)
      create_completed_job = fn attrs ->
        # Extract timestamp fields that need direct update
        # Truncate to seconds for :utc_datetime field compatibility
        completed_at =
          Map.get(attrs, :completed_at, DateTime.utc_now()) |> DateTime.truncate(:second)

        started_at =
          case Map.get(attrs, :started_at) do
            nil -> nil
            dt -> DateTime.truncate(dt, :second)
          end

        # Remove timestamp fields from attrs for initial creation
        create_attrs =
          attrs
          |> Map.delete(:completed_at)
          |> Map.delete(:started_at)

        {:ok, job} =
          Jobs.create_job(
            org.id,
            Map.merge(
              %{
                technician_id: tech.id,
                title: "Test Job",
                description: "Fixing things",
                status: "completed",
                actual_amount: Decimal.new("100.00")
              },
              create_attrs
            )
          )

        # Update with timestamp fields directly
        timestamp_updates = %{completed_at: completed_at}

        timestamp_updates =
          if started_at,
            do: Map.put(timestamp_updates, :started_at, started_at),
            else: timestamp_updates

        job
        |> Ecto.Changeset.change(timestamp_updates)
        |> FieldHub.Repo.update!()
      end

      %{
        org: org,
        tech: tech,
        current_scope: current_scope,
        create_completed_job: create_completed_job
      }
    end

    test "get_kpis/2 calculates summary metrics", %{
      current_scope: current_scope,
      create_completed_job: create_job
    } do
      # Job 1: Completed today, 1 hour duration, $150
      start_time = DateTime.utc_now() |> DateTime.add(-3600, :second)
      end_time = DateTime.utc_now()

      create_job.(%{
        started_at: start_time,
        completed_at: end_time,
        actual_amount: Decimal.new("150.00")
      })

      # Job 2: Completed yesterday, 2 hours duration, $250
      yesterday_start = DateTime.utc_now() |> DateTime.add(-86400 - 7200, :second)
      yesterday_end = DateTime.utc_now() |> DateTime.add(-86400, :second)

      create_job.(%{
        started_at: yesterday_start,
        completed_at: yesterday_end,
        actual_amount: Decimal.new("250.00")
      })

      # Job 3: Completed 60 days ago (outside range), $500
      old_date = DateTime.utc_now() |> DateTime.add(-60 * 86400, :second)

      create_job.(%{
        started_at: old_date |> DateTime.add(-3600, :second),
        completed_at: old_date,
        actual_amount: Decimal.new("500.00")
      })

      # Fetch KPIs for last 30 days
      range = {Date.utc_today() |> Date.add(-30), Date.utc_today()}
      kpis = Reports.get_kpis(current_scope, range)

      # Revenue: 150 + 250 = 400 (Job 3 excluded)
      assert kpis.total_revenue == Decimal.new("400.00")

      # Duration: (60 + 120) / 2 = 90 mins
      assert kpis.avg_job_duration_minutes == 90

      # Completed Jobs count
      assert kpis.completed_jobs_count == 2
    end

    test "get_technician_performance/2 returns stats per tech", %{
      current_scope: current_scope,
      tech: tech,
      create_completed_job: create_job
    } do
      create_job.(%{actual_amount: Decimal.new("100.00")})
      create_job.(%{actual_amount: Decimal.new("200.00")})

      range = {Date.utc_today() |> Date.add(-30), Date.utc_today()}
      stats = Reports.get_technician_performance(current_scope, range)

      assert length(stats) == 1
      tech_stat = List.first(stats)
      assert tech_stat.technician_id == tech.id
      assert tech_stat.name == tech.name
      assert tech_stat.jobs_completed == 2
      assert tech_stat.total_revenue == Decimal.new("300.00")
    end

    test "get_job_completion_trend/2 returns weekly counts", %{
      current_scope: current_scope,
      create_completed_job: create_job
    } do
      # Create job completed today
      create_job.(%{})

      range = {Date.utc_today() |> Date.add(-30), Date.utc_today()}
      trend = Reports.get_job_completion_trend(current_scope, range)

      # Should return a list of periods (e.g., weeks or days)
      # For simplicity, let's assume it returns a map or list of buckets
      assert is_list(trend)
      # Basic check that we have data points
      assert Enum.any?(trend, fn point -> point.count > 0 end)
    end

    test "get_recent_completed_jobs/2 returns latest jobs", %{
      current_scope: current_scope,
      create_completed_job: create_job
    } do
      job1 = create_job.(%{completed_at: DateTime.utc_now()})
      _job2 = create_job.(%{completed_at: DateTime.utc_now() |> DateTime.add(-100, :second)})

      jobs = Reports.get_recent_completed_jobs(current_scope, 5)

      assert length(jobs) == 2
      assert List.first(jobs).id == job1.id
    end

    test "completed_jobs_csv/2 exports completed jobs as CSV", %{
      org: org,
      tech: tech,
      current_scope: current_scope,
      create_completed_job: create_job
    } do
      customer = customer_fixture(org.id)

      job =
        create_job.(%{
          title: "HVAC, Repair",
          customer_id: customer.id,
          actual_amount: Decimal.new("123.45")
        })

      range = {Date.utc_today() |> Date.add(-30), Date.utc_today()}
      csv = Reports.completed_jobs_csv(current_scope, range)

      assert csv =~ "Job Number,Title,Customer,Technician,Completed At,Amount"
      assert csv =~ job.number
      assert csv =~ "\"HVAC, Repair\""
      assert csv =~ customer.name
      assert csv =~ tech.name
      assert csv =~ "123.45"
    end
  end
end
