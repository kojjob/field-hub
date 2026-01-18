defmodule FieldHubWeb.CustomerLiveTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.CRMFixtures
  alias FieldHub.Accounts

  @create_attrs %{
    name: "New Customer",
    email: "newcustomer@example.com",
    phone: "555-0000",
    address_line1: "123 Main St",
    city: "New York",
    state: "NY",
    zip: "10001"
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
    test "lists all customers", %{conn: conn, org: org} do
      customer = customer_fixture(org.id)
      {:ok, _index_live, html} = live(conn, ~p"/customers")

      assert html =~ "Customers"
      assert html =~ customer.name
    end

    test "saves new customer", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/customers")

      assert index_live |> element("a", "New Customer") |> render_click() =~
               "New Customer"

      assert_patch(index_live, ~p"/customers/new")

      assert index_live
             |> form("#customer-form", customer: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#customer-form", customer: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/customers")

      html = render(index_live)
      assert html =~ "New Customer"
    end

    test "updates customer in listing", %{conn: conn, org: org} do
      customer = customer_fixture(org.id)
      {:ok, index_live, _html} = live(conn, ~p"/customers")

      assert index_live |> element("#customers-#{customer.id} a", "Edit") |> render_click() =~
               "Edit Customer"

      assert_patch(index_live, ~p"/customers/#{customer}/edit")

      assert index_live
             |> form("#customer-form", customer: %{name: "Updated Name"})
             |> render_submit()

      assert_patch(index_live, ~p"/customers")

      html = render(index_live)
      assert html =~ "Updated Name"
    end

    test "deletes customer in listing", %{conn: conn, org: org} do
      customer = customer_fixture(org.id)
      {:ok, index_live, _html} = live(conn, ~p"/customers")

      assert index_live |> element("#customers-#{customer.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#customers-#{customer.id}")
    end

    test "search filters customers", %{conn: conn, org: org} do
      c1 = customer_fixture(org.id, %{name: "Alice Johnson", email: "alice@example.com"})
      c2 = customer_fixture(org.id, %{name: "Bob Smith", email: "bob@example.com"})

      {:ok, index_live, _html} = live(conn, ~p"/customers")

      assert has_element?(index_live, "#customers-#{c1.id}")
      assert has_element?(index_live, "#customers-#{c2.id}")

      index_live
      |> p_form("#search-form", %{search: "Alice"})
      |> render_change()

      assert has_element?(index_live, "#customers-#{c1.id}")
      refute has_element?(index_live, "#customers-#{c2.id}")
    end
  end

  # Helper to construct a form specifically for change events
  # since we might want simply `phx-change` on a form input
  defp p_form(view, selector, params) do
    form(view, selector, params)
  end
end
