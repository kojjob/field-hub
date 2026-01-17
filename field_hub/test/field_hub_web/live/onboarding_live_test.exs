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

  describe "Onboarding - authenticated user without organization" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "mounts successfully for user without organization", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/onboarding")

      assert html =~ "Create Your Organization"
      # Note: apostrophe gets HTML escaped
      assert html =~ "get your business set up"
      assert has_element?(view, "input#organization_name")
      assert has_element?(view, "input#organization_email")
    end

    test "validates organization name is required", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      result =
        view
        |> form("#onboarding-form", %{organization: %{name: "", email: "test@example.com"}})
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end

    test "validates email format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      result =
        view
        |> form("#onboarding-form", %{organization: %{name: "Test Org", email: "invalid-email"}})
        |> render_change()

      assert result =~ "has invalid format"
    end

    test "creates organization and redirects to dashboard", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

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
      assert html =~ "Welcome to FieldHub!"

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

      html =
        view
        |> form("#onboarding-form", %{organization: %{name: "Ace HVAC"}})
        |> render_change()

      assert html =~ "ace-hvac"
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
