defmodule FieldHubWeb.UserLive.RegistrationTest do
  use FieldHubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import FieldHub.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Create Your Account"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      user = user_fixture()

      result =
        conn
        |> log_in_user(user)
        |> live(~p"/users/register")
        |> follow_redirect(conn, "/onboarding")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces"})

      assert result =~ "Create Your Account"
      assert result =~ "Please enter a valid email"
    end
  end

  describe "register user" do
    test "creates account and logs in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()

      form =
        form(lv, "#registration_form",
          user: valid_user_attributes(email: email) |> Map.put(:terms_accepted, "true")
        )

      {:ok, confirmation_lv, _html} =
        render_submit(form)
        |> follow_redirect(conn)

      conn =
        form(confirmation_lv, "#confirmation_form")
        |> follow_trigger_action(conn)

      assert redirected_to(conn) == "/onboarding"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "has a login link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      # Verify the login link is present
      assert html =~ "Log in"
      assert html =~ ~s(href="/users/log-in")
    end
  end
end
