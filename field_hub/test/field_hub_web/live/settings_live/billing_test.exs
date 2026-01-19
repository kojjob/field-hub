defmodule FieldHubWeb.SettingsLive.BillingTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.AccountsFixtures

  describe "Billing Page" do
    setup do
      {user, org} = register_and_log_in_user_with_org()

      # Ensure user is owner
      {:ok, user} =
        user
        |> Ecto.Changeset.change(role: "owner")
        |> FieldHub.Repo.update()

      %{conn: log_in_user(build_conn(), user), user: user, org: org}
    end

    test "renders billing page", %{conn: conn, org: org} do
      {:ok, _view, html} = live(conn, ~p"/settings/billing")

      assert html =~ "Subscription"
      assert html =~ "Current Plan"
      # trial
      assert html =~ org.subscription_tier
      # trial
      assert html =~ org.subscription_status
      assert html =~ "Upgrade Plan"
    end

    test "redirects non-owner", %{user: user} do
      # Demote user
      {:ok, user} =
        user
        |> Ecto.Changeset.change(role: "technician")
        |> FieldHub.Repo.update()

      conn = log_in_user(build_conn(), user)

      assert {:error,
              {:live_redirect,
               %{
                 to: "/dashboard",
                 flash: %{"error" => "You do not have permission to view billing settings."}
               }}} =
               live(conn, ~p"/settings/billing")
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
