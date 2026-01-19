defmodule FieldHubWeb.JobLiveTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.JobsFixtures
  import FieldHub.CRMFixtures

  @create_attrs %{
    title: "Fix HVAC System",
    description: "System is making a loud noise",
    job_type: "service_call",
    priority: "urgent"
  }

  @update_attrs %{
    title: "Fix HVAC System (Updated)",
    description: "Noise has stopped but not cooling",
    priority: "normal"
  }

  @invalid_attrs %{title: nil, description: nil}

  defp create_job(user) do
    customer = customer_fixture(user.organization_id)
    job = job_fixture(user.organization_id, %{customer_id: customer.id, created_by_id: user.id})
    %{job: job, customer: customer}
  end

  defp create_customer(user) do
    customer_fixture(user.organization_id)
  end

  setup %{conn: conn} do
    unique_id = System.unique_integer([:positive])

    {:ok, org} =
      FieldHub.Accounts.create_organization(%{
        name: "Test Org #{unique_id}",
        slug: "test-org-#{unique_id}"
      })

    user = FieldHub.AccountsFixtures.user_fixture(%{organization_id: org.id})

    conn =
      conn
      |> log_in_user(user)
      |> assign(:current_organization, org)

    {:ok, conn: conn, user: user, org: org}
  end

  describe "Index" do
    test "lists all jobs", %{conn: conn, user: user} do
      %{job: job} = create_job(user)
      {:ok, _index_live, html} = live(conn, ~p"/jobs")

      assert html =~ "Job Directory"
      assert html =~ job.title
    end

    test "saves new job", %{conn: conn, user: user} do
      customer = create_customer(user)
      {:ok, index_live, _html} = live(conn, ~p"/jobs")

      assert index_live |> element("a", "Create New Job") |> render_click() =~
               "New Job"

      assert_patch(index_live, ~p"/jobs/new")

      assert index_live
             |> form("#job-form", job: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      index_live
      |> form("#job-form", job: Map.put(@create_attrs, :customer_id, customer.id))
      |> render_submit()

      assert_patch(index_live, ~p"/jobs")

      html = render(index_live)
      # Job title should be in the listing, proving the job was created
      assert html =~ "Fix HVAC System"
    end

    test "updates job in listing", %{conn: conn, user: user} do
      %{job: job} = create_job(user)
      {:ok, index_live, _html} = live(conn, ~p"/jobs")

      assert index_live |> element("a[href*='/edit']") |> render_click() =~
               "Edit Job"

      assert_patch(index_live, ~p"/jobs/#{job.number}/edit")

      assert index_live
             |> form("#job-form", job: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      index_live
      |> form("#job-form", job: @update_attrs)
      |> render_submit()

      assert_patch(index_live, ~p"/jobs")

      html = render(index_live)
      # Updated job title should be in the listing
      assert html =~ "Fix HVAC System (Updated)"
    end

    test "deletes job in listing", %{conn: conn, user: user} do
      %{job: job} = create_job(user)
      {:ok, index_live, _html} = live(conn, ~p"/jobs")

      assert index_live |> element("a[phx-click*='delete']") |> render_click()
      refute has_element?(index_live, "#jobs-#{job.id}")
    end
  end
end
