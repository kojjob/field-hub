defmodule FieldHubWeb.OnboardingLiveTest do
  use FieldHubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias FieldHub.Accounts

  describe "Onboarding - requires authentication" do
    test "redirects if user is not logged in", %{conn: conn} do
      result = live(conn, ~p"/onboarding")

      assert {:error, {:redirect, %{to: path}}} = result
      assert path =~ "/users/log-in"
    end
  end

  describe "Onboarding - user with organization" do
    setup %{conn: conn} do
      # user_fixture creates user with organization
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "redirects users with completed onboarding to dashboard", %{conn: conn, user: user} do
      # Mark onboarding as complete
      org = Accounts.get_organization!(user.organization_id)
      {:ok, _} = Accounts.update_organization(org, %{onboarding_completed_at: DateTime.utc_now()})

      assert {:error, {:live_redirect, %{to: "/dashboard"}}} = live(conn, ~p"/onboarding")
    end

    test "shows step 2 (company details) for users with pending onboarding", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/onboarding")

      # Should start at step 2 since user has organization
      assert html =~ "Tell us about your company"
      assert html =~ "Company Profile"
    end

    test "displays organization form fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      assert has_element?(view, "input[name='organization[name]']")
      assert has_element?(view, "input[name='organization[email]']")
      assert has_element?(view, "input[name='organization[phone]']")
    end

    test "shows international address fields", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/onboarding")

      assert html =~ "Business Address"
      assert html =~ "City / Town"
      assert html =~ "State / Province"
      assert html =~ "Postal / ZIP Code"
      assert html =~ "Country"
      assert has_element?(view, "input[name='organization[country]']")
    end
  end

  describe "Onboarding - Step 2 to Step 3 flow" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "can navigate from step 2 to step 3 (branding)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Submit step 2 form
      html =
        view
        |> form("#onboarding-form", organization: %{name: "Test Org"})
        |> render_submit()

      # Should now be on step 3 (branding)
      assert html =~ "Make it yours"
      assert html =~ "Brand Colors"
    end
  end

  describe "Onboarding - Step 3 (Branding)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "can navigate to branding step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Submit step 2 to get to step 3
      view
      |> form("#onboarding-form", organization: %{name: "Test Org"})
      |> render_submit()

      html = render(view)
      assert html =~ "Make it yours"
      assert html =~ "Primary Color"
      assert html =~ "Secondary Color"
      assert html =~ "Brand Name"
    end

    test "shows branding preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Submit step 2 to get to step 3
      view
      |> form("#onboarding-form", organization: %{name: "Test Org"})
      |> render_submit()

      html = render(view)
      assert html =~ "Live Preview"
    end
  end

  describe "Onboarding - Step 4 (Launch)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "shows launch step after branding", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Go through step 2
      view
      |> form("#onboarding-form", organization: %{name: "Test Org"})
      |> render_submit()

      # Go through step 3
      html =
        view
        |> form("#branding-form", organization: %{brand_name: "My Brand"})
        |> render_submit()

      # Should be on step 4
      assert html =~ "all set"
      assert html =~ "Launch Dashboard"
    end

    test "shows quick action cards on launch step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Navigate to step 4
      view
      |> form("#onboarding-form", organization: %{name: "Test Org"})
      |> render_submit()

      view
      |> form("#branding-form", organization: %{})
      |> render_submit()

      html = render(view)
      assert html =~ "Invite Team"
      assert html =~ "Add Customers"
      assert html =~ "Create Job"
    end
  end

  describe "Onboarding - completion" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "completing onboarding redirects to dashboard", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Navigate through all steps
      view
      |> form("#onboarding-form", organization: %{name: "Test Org"})
      |> render_submit()

      view
      |> form("#branding-form", organization: %{})
      |> render_submit()

      # Click finish
      view
      |> element("button", "Launch Dashboard")
      |> render_click()

      # Should redirect to dashboard
      assert_redirect(view, "/dashboard")
    end
  end

  # Helper fixtures
  defp user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "test#{System.unique_integer([:positive])}@example.com",
        password: "validpassword123",
        terms_accepted: true,
        name: "Test User",
        company_name: "Test Company #{System.unique_integer([:positive])}"
      })
      |> Accounts.register_user()

    user
  end
end
