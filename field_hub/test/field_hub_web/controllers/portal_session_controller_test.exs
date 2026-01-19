defmodule FieldHubWeb.PortalSessionControllerTest do
  use FieldHubWeb.ConnCase, async: true

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures

  describe "GET /portal/login/:token" do
    test "logs customer into portal and redirects", %{conn: conn} do
      org = organization_fixture()
      customer = customer_fixture(org.id)

      conn = get(conn, ~p"/portal/login/#{customer.portal_token}")

      assert get_session(conn, :portal_customer_id) == customer.id
      assert redirected_to(conn) == ~p"/portal"
    end

    test "rejects invalid token", %{conn: conn} do
      conn = get(conn, ~p"/portal/login/invalid")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "invalid"
    end
  end

  describe "GET /portal" do
    test "requires portal session", %{conn: conn} do
      conn = get(conn, ~p"/portal")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "portal"
    end

    test "renders portal home when logged in", %{conn: conn} do
      org = organization_fixture()
      customer = customer_fixture(org.id)

      conn =
        conn
        |> init_test_session(%{portal_customer_id: customer.id})
        |> get(~p"/portal")

      assert html_response(conn, 200) =~ customer.name
    end
  end
end
