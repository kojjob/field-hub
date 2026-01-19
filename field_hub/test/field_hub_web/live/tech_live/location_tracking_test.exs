defmodule FieldHubWeb.TechLive.LocationTrackingTest do
  use FieldHubWeb.ConnCase
  import Phoenix.LiveViewTest
  import FieldHub.JobsFixtures
  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures

  setup %{conn: conn} do
    org = organization_fixture()
    user = user_fixture(organization_id: org.id)

    technician =
      %FieldHub.Dispatch.Technician{
        organization_id: org.id,
        user_id: user.id,
        name: "Track Tech",
        status: "available",
        email: "tech-#{System.unique_integer([:positive])}@example.com"
      }
      |> FieldHub.Repo.insert!()

    customer = customer_fixture(org.id)

    job =
      job_fixture(org.id, %{
        customer_id: customer.id,
        technician_id: technician.id,
        scheduled_date: Date.utc_today(),
        scheduled_start: DateTime.utc_now(),
        scheduled_end: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

    %{conn: log_in_user(conn, user), technician: technician, job: job}
  end

  test "TechLive.Dashboard receives location updates", %{conn: conn, technician: technician} do
    {:ok, view, _html} = live(conn, ~p"/tech/dashboard")

    # Push the update_location event
    render_hook(view, "update_location", %{"lat" => 34.0522, "lng" => -118.2437})

    # Verify database update
    updated_tech = FieldHub.Repo.get!(FieldHub.Dispatch.Technician, technician.id)
    assert_in_delta updated_tech.current_lat, 34.0522, 0.0001
    assert_in_delta updated_tech.current_lng, -118.2437, 0.0001
    assert updated_tech.location_updated_at != nil
  end

  test "TechLive.JobShow receives location updates", %{
    conn: conn,
    job: job,
    technician: technician
  } do
    {:ok, view, _html} = live(conn, ~p"/tech/jobs/#{job.number}")

    # Push the update_location event
    render_hook(view, "update_location", %{"lat" => 40.7128, "lng" => -74.0060})

    # Verify database update
    updated_tech = FieldHub.Repo.get!(FieldHub.Dispatch.Technician, technician.id)
    assert_in_delta updated_tech.current_lat, 40.7128, 0.0001
    assert_in_delta updated_tech.current_lng, -74.0060, 0.0001
  end

  test "TechLive.JobComplete receives location updates", %{
    conn: conn,
    job: job,
    technician: technician
  } do
    # Job must be in on_site or in_progress status
    {:ok, job} = FieldHub.Jobs.arrive_on_site(job)

    {:ok, view, _html} = live(conn, ~p"/tech/jobs/#{job.number}/complete")

    # Push the update_location event
    render_hook(view, "update_location", %{"lat" => 51.5074, "lng" => -0.1278})

    # Verify database update
    updated_tech = FieldHub.Repo.get!(FieldHub.Dispatch.Technician, technician.id)
    assert_in_delta updated_tech.current_lat, 51.5074, 0.0001
    assert_in_delta updated_tech.current_lng, -0.1278, 0.0001
  end
end
