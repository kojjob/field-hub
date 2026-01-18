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

  describe "Onboarding - Step 1: Template Selection" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "mounts on step 1 with template selection", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/onboarding")

      assert html =~ "Select Your Industry"
      assert has_element?(view, "button[phx-value-template=field_service]")
      assert has_element?(view, "button[phx-value-template=healthcare]")
    end

    test "can select a template", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      html =
        view
        |> element("button[phx-value-template=healthcare]")
        |> render_click()

      assert html =~ "border-blue-600"
    end

    test "can skip template selection", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      html =
        view
        |> element("button", "Skip for now")
        |> render_click()

      assert html =~ "Create Your Organization"
      assert has_element?(view, "input#organization_name")
    end

    test "can continue with selected template", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      view
      |> element("button[phx-value-template=healthcare]")
      |> render_click()

      html =
        view
        |> element("button", "Continue")
        |> render_click()

      assert html =~ "Create Your Organization"
      assert html =~ "Home Healthcare"
    end
  end

  describe "Onboarding - Step 2: Organization Details" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    defp go_to_step_2(view) do
      view
      |> element("button", "Skip for now")
      |> render_click()
    end

    test "validates organization name is required", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")
      go_to_step_2(view)

      result =
        view
        |> form("#onboarding-form", %{organization: %{name: "", email: "test@example.com"}})
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end

    test "validates email format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")
      go_to_step_2(view)

      result =
        view
        |> form("#onboarding-form", %{organization: %{name: "Test Org", email: "invalid-email"}})
        |> render_change()

      assert result =~ "has invalid format"
    end

    test "creates organization and redirects to dashboard", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")
      go_to_step_2(view)

      {:ok, _view, html} =
        view
        |> form("#onboarding-form", %{
          organization: %{
            name: "Ace HVAC Services",
            email: "info@acehvac.com",
            phone: "555-123-4567"
          }
        })
        |> render_submit()
        |> follow_redirect(conn)

      # Should redirect to dashboard with success message
      assert html =~ "Operations Dashboard"

      # Verify user is now owner of the organization
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.role == "owner"
      assert updated_user.organization_id

      # Verify organization was created correctly
      {:ok, org} = Accounts.get_organization(updated_user.organization_id)
      assert org.name == "Ace HVAC Services"
      assert org.email == "info@acehvac.com"
      assert org.subscription_status == "trial"
    end

    test "auto-generates slug from name", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")
      go_to_step_2(view)

      {:ok, _view, _html} =
        view
        |> form("#onboarding-form", %{
          organization: %{name: "Bob's Plumbing & Heating"}
        })
        |> render_submit()
        |> follow_redirect(conn)

      updated_user = Accounts.get_user!(user.id)
      {:ok, org} = Accounts.get_organization(updated_user.organization_id)
      assert org.slug =~ "bobs-plumbing-heating"
    end

    test "shows organization preview as user types", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")
      go_to_step_2(view)

      html =
        view
        |> form("#onboarding-form", %{organization: %{name: "Ace HVAC"}})
        |> render_change()

      assert html =~ "ace-hvac"
    end

    test "can go back to step 1", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")
      go_to_step_2(view)

      html =
        view
        |> element("button", "Back")
        |> render_click()

      assert html =~ "Select Your Industry"
    end
  end

  describe "Onboarding - With Template Applied" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "applies healthcare template terminology", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Select healthcare template
      view
      |> element("button[phx-value-template=healthcare]")
      |> render_click()

      view
      |> element("button", "Continue")
      |> render_click()

      # Create organization
      {:ok, _view, _html} =
        view
        |> form("#onboarding-form", %{
          organization: %{name: "Care Plus Home Health"}
        })
        |> render_submit()
        |> follow_redirect(conn)

      # Verify template was applied
      updated_user = Accounts.get_user!(user.id)
      {:ok, org} = Accounts.get_organization(updated_user.organization_id)

      assert org.terminology["worker_label"] == "Caregiver"
      assert org.terminology["client_label"] == "Patient"
      assert org.primary_color == "#10B981"
    end
  end

  describe "Onboarding - user already has organization" do
    setup %{conn: conn} do
      {:ok, org} = Accounts.create_organization(%{name: "Existing Org", slug: "existing-org"})
      user = user_fixture()

      # Update user to associate with org (register_user doesn't accept organization_id)
      {:ok, user} =
        user
        |> Ecto.Changeset.change(%{organization_id: org.id})
        |> FieldHub.Repo.update()

      %{conn: log_in_user(conn, user), user: user, org: org}
    end

    test "redirects to dashboard if user already has organization", %{conn: conn} do
      result = live(conn, ~p"/onboarding")

      assert {:error, {:live_redirect, %{to: path}}} = result
      assert path == "/dashboard"
    end
  end

  # Fixtures

  defp user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "test#{System.unique_integer([:positive])}@example.com",
        password: "validpassword123"
      })
      |> Accounts.register_user()

    user
  end
end
