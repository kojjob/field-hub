defmodule FieldHubWeb.SettingsLive.NotificationsTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.AccountsFixtures

  describe "Notifications Page" do
    setup do
      {user, org} = register_and_log_in_user_with_org()
      %{conn: log_in_user(build_conn(), user), user: user, org: org}
    end

    test "renders notifications page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/notifications")

      assert html =~ "Notifications"
      assert html =~ "Manage how and when you receive updates"
      assert html =~ "Email Notifications"
      assert html =~ "New Job Assignments"
    end

    test "updates notification preferences", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/settings/notifications")

      # Initial state (defaults are true, true, false)
      assert user.notify_on_new_jobs == true
      assert user.notify_marketing == false

      view
      |> form("#notifications-form", %{
        "user" => %{
          "notify_on_new_jobs" => "false",
          "notify_marketing" => "true"
        }
      })
      |> render_submit()

      assert render(view) =~ "Notifications preferences updated successfully"

      # Verify updates
      updated_user = FieldHub.Accounts.get_user!(user.id)
      assert updated_user.notify_on_new_jobs == false
      assert updated_user.notify_marketing == true
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
