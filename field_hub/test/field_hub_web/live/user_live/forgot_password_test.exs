defmodule FieldHubWeb.UserLive.ForgotPasswordTest do
  use FieldHubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import FieldHub.AccountsFixtures

  describe "Forgot password page" do
    test "renders forgot password page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/forgot-password")

      assert html =~ "Reset your password"
      assert html =~ "Enter your email"
      assert html =~ "Send Reset Link"
      assert html =~ "Back to login"
    end

    test "shows success message when email is submitted", %{conn: conn} do
      # Create a user to test with
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      # Submit the form with a valid email
      result =
        lv
        |> form("#forgot_password_form", user: %{email: user.email})
        |> render_submit()

      # Should show success message
      assert result =~ "Check your inbox"
      assert result =~ user.email
      assert result =~ "Try a different email"
    end

    test "shows success message even for non-existent email (prevents enumeration)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      # Submit with a non-existent email
      result =
        lv
        |> form("#forgot_password_form", user: %{email: "nonexistent@example.com"})
        |> render_submit()

      # Should still show success message to prevent email enumeration
      assert result =~ "Check your inbox"
      assert result =~ "nonexistent@example.com"
    end

    test "reset form button works after success", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      # Submit the form
      lv
      |> form("#forgot_password_form", user: %{email: "test@example.com"})
      |> render_submit()

      # Click reset button
      result = lv |> element("button", "Try a different email") |> render_click()

      # Should show the form again
      assert result =~ "Send Reset Link"
      refute result =~ "Check your inbox"
    end
  end
end
