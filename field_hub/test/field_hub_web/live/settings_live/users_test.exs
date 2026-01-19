defmodule FieldHubWeb.SettingsLive.UsersTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.AccountsFixtures

  describe "Users Settings" do
    setup do
      {user, org} = register_and_log_in_user_with_org()

      # Ensure user is owner or admin
      {:ok, user} =
        user
        |> Ecto.Changeset.change(role: "owner")
        |> FieldHub.Repo.update()

      %{conn: log_in_user(build_conn(), user), user: user, org: org}
    end

    test "lists team members", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/settings/users")
      assert html =~ "Team Management"
      assert html =~ user.name
      assert html =~ user.email
      assert html =~ "owner"
    end

    test "can invite a new user", %{conn: conn, org: _org} do
      {:ok, view, _html} = live(conn, ~p"/settings/users")

      view
      |> element("button", "Invite Member")
      |> render_click()

      assert render(view) =~ "Invite Member"

      view
      |> form("#invite-user-form", %{
        "user" => %{
          "name" => "New Teammate",
          "email" => "teammate@example.com",
          "role" => "technician"
        }
      })
      |> render_submit()

      assert render(view) =~ "User invited successfully"
      assert render(view) =~ "New Teammate"
      assert render(view) =~ "teammate@example.com"
      assert render(view) =~ "technician"
    end

    test "can delete a user", %{conn: conn, org: org} do
      # Create another user to delete
      {:ok, other_user} =
        FieldHub.Accounts.invite_user(org, %{
          "name" => "Delete Me",
          "email" => "delete@example.com",
          "role" => "viewer",
          "phone" => "555-5555",
          "avatar_url" => nil
        })

      {:ok, view, _html} = live(conn, ~p"/settings/users")

      assert render(view) =~ "Delete Me"

      view
      |> element("button[phx-value-id='#{other_user.id}']")
      |> render_click()

      refute render(view) =~ "Delete Me"
      assert render(view) =~ "User removed successfully"
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
