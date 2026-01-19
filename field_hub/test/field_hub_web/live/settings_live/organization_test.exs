defmodule FieldHubWeb.SettingsLive.OrganizationTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.AccountsFixtures

  describe "Organization Settings" do
    setup do
      {user, org} = register_and_log_in_user_with_org()
      %{conn: log_in_user(build_conn(), user), user: user, org: org}
    end

    test "renders organization settings page", %{conn: conn, org: org} do
      {:ok, _view, html} = live(conn, ~p"/settings/organization")
      assert html =~ "Organization Settings"
      assert html =~ org.name
      assert html =~ "General Information"
      assert html =~ "Location &amp; Address"
    end

    test "updates organization details", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/organization")

      view
      |> form("#organization-form", %{
        "organization" => %{
          "name" => "Updated Corp",
          "email" => "new@email.com",
          "city" => "New City"
        }
      })
      |> render_submit()

      flash = assert_redirect(view, ~p"/settings/organization")
      assert flash["info"] == "Organization settings updated successfully!"

      {:ok, _view_updated, html_updated} = live(conn, ~p"/settings/organization")
      assert html_updated =~ "Updated Corp"
      assert html_updated =~ "new@email.com"
      assert html_updated =~ "New City"
    end

    test "validates organization data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/organization")

      result =
        view
        |> form("#organization-form", %{
          "organization" => %{
            # Invalid
            "name" => "",
            "email" => "invalid-email"
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
      assert result =~ "has invalid format"
    end
  end

  defp register_and_log_in_user_with_org do
    user = user_fixture()
    org = organization_fixture()

    {:ok, user} =
      user
      |> Ecto.Changeset.change(organization_id: org.id)
      |> FieldHub.Repo.update()

    {user, org}
  end
end
