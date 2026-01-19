defmodule FieldHubWeb.TechnicianLiveTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.DispatchFixtures
  alias FieldHub.Accounts
  alias FieldHub.Dispatch

  @create_attrs %{
    name: "New Tech",
    email: "newtech@example.com",
    phone: "555-0000",
    hourly_rate: "45.00",
    color: "#aabbcc"
  }
  @invalid_attrs %{name: nil, email: nil}

  setup %{conn: conn} do
    {:ok, org} =
      Accounts.create_organization(%{
        name: "Test Org",
        slug: "test-org-#{System.unique_integer([:positive])}"
      })

    user = FieldHub.AccountsFixtures.user_fixture(%{organization_id: org.id})
    conn = log_in_user(conn, user)

    %{conn: conn, org: org, user: user}
  end

  describe "Index" do
    test "lists all technicians", %{conn: conn, org: org} do
      tech = technician_fixture(org.id)
      {:ok, _index_live, html} = live(conn, ~p"/technicians")

      assert html =~ "Technicians"
      assert html =~ tech.name
    end

    test "saves new technician", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/technicians")

      assert index_live |> element("a", "Add Technician") |> render_click() =~
               "New Technician"

      assert_patch(index_live, ~p"/technicians/new")

      assert index_live
             |> form("#technician-form", technician: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#technician-form",
               technician: Map.put(@create_attrs, :skills_input, "HVAC, Plumbing")
             )
             |> render_submit()

      assert_patch(index_live, ~p"/technicians")

      html = render(index_live)
      assert html =~ "New Tech"
      assert html =~ "background-color: #aabbcc"
      assert html =~ "HVAC"
      assert html =~ "Plumbing"
    end

    test "updates technician in listing", %{conn: conn, org: org} do
      tech = technician_fixture(org.id)
      {:ok, index_live, _html} = live(conn, ~p"/technicians")

      assert index_live |> element("a[href*='/edit']") |> render_click() =~
               "Edit Technician"

      assert has_element?(index_live, "h2", "Edit Technician")

      assert index_live
             |> form("#technician-form", technician: %{name: "Updated Name"})
             |> render_submit()

      assert_patch(index_live, ~p"/technicians")

      html = render(index_live)
      assert html =~ "Updated Name"
    end

    test "deletes technician in listing", %{conn: conn, org: org} do
      tech = technician_fixture(org.id)
      {:ok, index_live, _html} = live(conn, ~p"/technicians")

      assert index_live |> element("a[phx-click*='delete']") |> render_click()
      refute has_element?(index_live, "#technicians-#{tech.id}")
    end

    test "updates in real-time", %{conn: conn, org: org} do
      {:ok, index_live, _html} = live(conn, ~p"/technicians")

      # Test Create
      {:ok, tech} =
        Dispatch.create_technician(org.id, %{
          name: "Real-time Tech",
          email: "realtime@example.com",
          phone: "555-RT01"
        })

      assert render(index_live) =~ "Real-time Tech"

      # Test Update
      {:ok, _tech} = Dispatch.update_technician(tech, %{name: "Updated Real-time Tech"})

      assert render(index_live) =~ "Updated Real-time Tech"

      # Test Archive (Delete)
      {:ok, _tech} = Dispatch.archive_technician(tech)

      refute has_element?(index_live, "#technicians-#{tech.id}")
    end
  end
end
