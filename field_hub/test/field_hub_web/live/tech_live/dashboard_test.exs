defmodule FieldHubWeb.TechLive.DashboardTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.JobsFixtures
  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures

  describe "Technician Dashboard" do
    setup %{conn: conn} do
      org = organization_fixture()
      user = user_fixture(organization_id: org.id)

      technician =
        %FieldHub.Dispatch.Technician{
          organization_id: org.id,
          user_id: user.id,
          name: "Test Tech",
          status: "available",
          # Use unique email to avoid collision
          email: "tech-#{System.unique_integer()}@example.com"
        }
        |> FieldHub.Repo.insert!()

      %{conn: log_in_user(conn, user), user: user, technician: technician, org: org}
    end

    test "disconnected and connected render", %{conn: conn, user: user} do
      IO.inspect(user.id, label: "Test User ID passed to live")
      {:ok, page_live, disconnected_html} = live(conn, "/tech/dashboard")
      assert disconnected_html =~ "Today&#39;s Jobs"
      assert render(page_live) =~ "Today&#39;s Jobs"
    end

    test "lists assigned jobs", %{conn: conn, technician: technician, org: org} do
      customer = customer_fixture(org.id)
      # Create a job assigned to this technician
      _job =
        job_fixture(org.id, %{
          customer_id: customer.id,
          technician_id: technician.id,
          title: "Fix AC Unit",
          scheduled_date: Date.utc_today(),
          scheduled_start:
            DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second),
          scheduled_end:
            DateTime.utc_now() |> DateTime.add(7200, :second) |> DateTime.truncate(:second)
        })

      {:ok, page_live, _html} = live(conn, "/tech/dashboard")

      assert render(page_live) =~ "Fix AC Unit"
    end
  end
end
