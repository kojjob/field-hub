defmodule FieldHubWeb.ReportLiveTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.DispatchFixtures

  alias FieldHub.Accounts
  alias FieldHub.Jobs

  setup %{conn: conn} do
    {:ok, org} =
      Accounts.create_organization(%{
        name: "Test Org",
        slug: "test-org-#{System.unique_integer([:positive])}"
      })

    user = FieldHub.AccountsFixtures.user_fixture(%{organization_id: org.id})
    conn = log_in_user(conn, user)

    tech = technician_fixture(org.id)

    %{conn: conn, org: org, tech: tech}
  end

  test "renders reports page with key sections", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/reports")

    assert has_element?(view, "#reports-page")
    assert has_element?(view, "#reports-range-btn")
    assert has_element?(view, "#reports-export-btn")
    assert has_element?(view, "#reports-trend-chart")
    assert has_element?(view, "#reports-recent-jobs-table")
  end

  test "shows recent completed jobs", %{conn: conn, org: org, tech: tech} do
    job = create_completed_job(org.id, tech.id, %{title: "Test Report Job"})

    {:ok, view, _html} = live(conn, ~p"/reports")

    assert has_element?(view, "#reports-recent-jobs-table")
    assert render(view) =~ job.title
  end

  test "exports CSV", %{conn: conn, org: org, tech: tech} do
    _job = create_completed_job(org.id, tech.id, %{title: "Export Job"})

    conn = get(conn, ~p"/reports/export")

    assert conn.status == 200

    [content_type | _] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type =~ "text/csv"

    assert conn.resp_body =~ "Job Number,Title,Customer,Technician,Completed At,Amount"
  end

  defp create_completed_job(org_id, tech_id, attrs) do
    completed_at = DateTime.utc_now() |> DateTime.truncate(:second)
    started_at = DateTime.add(completed_at, -3600, :second)

    {:ok, job} =
      Jobs.create_job(
        org_id,
        Map.merge(
          %{
            technician_id: tech_id,
            title: "Test Job",
            description: "Fixing things",
            status: "completed",
            actual_amount: Decimal.new("100.00")
          },
          attrs
        )
      )

    job
    |> Ecto.Changeset.change(%{started_at: started_at, completed_at: completed_at})
    |> FieldHub.Repo.update!()
  end
end
