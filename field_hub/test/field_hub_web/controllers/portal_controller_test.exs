defmodule FieldHubWeb.PortalControllerTest do
  use FieldHubWeb.ConnCase, async: true

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.JobsFixtures

  test "shows active jobs and service history", %{conn: conn} do
    org = organization_fixture()
    customer = customer_fixture(org.id)

    tech =
      %FieldHub.Dispatch.Technician{
        organization_id: org.id,
        name: "Portal Tech",
        status: "available",
        email: "portal-tech-#{System.unique_integer([:positive])}@example.com"
      }
      |> FieldHub.Repo.insert!()

    _active_job =
      job_fixture(org.id, %{
        customer_id: customer.id,
        technician_id: tech.id,
        status: "en_route",
        title: "Fix Sink",
        scheduled_date: Date.utc_today(),
        scheduled_start: ~T[09:00:00]
      })

    completed_job =
      job_fixture(org.id, %{
        customer_id: customer.id,
        technician_id: tech.id,
        status: "completed",
        title: "Replace Filter"
      })

    _ =
      completed_job
      |> Ecto.Changeset.change(%{completed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      |> FieldHub.Repo.update!()

    conn =
      conn
      |> init_test_session(%{portal_customer_id: customer.id})
      |> get(~p"/portal")

    html = html_response(conn, 200)

    assert html =~ "Welcome"
    assert html =~ customer.name

    assert html =~ "Active Jobs"
    assert html =~ "Fix Sink"
    assert html =~ "en route"

    assert html =~ "Service History"
    assert html =~ "Replace Filter"
  end
end
