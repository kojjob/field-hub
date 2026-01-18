defmodule FieldHubWeb.SettingsLive.CustomFieldsTest do
  use FieldHubWeb.ConnCase

  import Phoenix.LiveViewTest
  import FieldHub.AccountsFixtures

  describe "Custom Fields Settings" do
    setup do
      {user, org} = register_and_log_in_user_with_org()
      %{conn: log_in_user(build_conn(), user), user: user, org: org}
    end

    test "lists custom fields", %{conn: conn, org: _org} do
      {:ok, _view, html} = live(conn, ~p"/settings/custom-fields")
      assert html =~ "Custom Fields"
      assert html =~ "Extend your data model"
    end

    test "can create a new custom field", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/custom-fields")

      view
      |> element("a", "Add Field")
      |> render_click()

      assert_patch(view, ~p"/settings/custom-fields/new?target=job")

      view
      |> form("#custom-field-form", %{
        "custom_field_definition" => %{
          "name" => "Gate Code",
          "key" => "gate_code",
          "type" => "text",
          "target" => "job"
        }
      })
      |> render_submit()

      assert_patch(view, ~p"/settings/custom-fields?tab=job")
      assert render(view) =~ "Gate Code"
      assert render(view) =~ "gate_code"
    end

    test "can delete a custom field", %{conn: conn, org: org} do
      {:ok, field} =
        FieldHub.Config.CustomFields.create_definition(%{
          name: "Gate Code",
          key: "gate_code",
          type: "text",
          target: "job",
          organization_id: org.id
        })

      {:ok, view, _html} = live(conn, ~p"/settings/custom-fields")

      assert render(view) =~ "Gate Code"

      view
      |> element("button[phx-click='delete_field']")
      |> render_click()

      refute render(view) =~ "Gate Code"
    end

    test "validates field data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/custom-fields/new")

      result =
        view
        |> form("#custom-field-form", %{
          "custom_field_definition" => %{
            "name" => "",
            "key" => "Invalid Key!"
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
      assert result =~ "must be lowercase alphanumeric with underscores"
    end
  end

  # Helper to register user and create org
  defp register_and_log_in_user_with_org do
    user = user_fixture()
    org = organization_fixture()

    # Associate user with org
    {:ok, user} =
      user
      |> Ecto.Changeset.change(organization_id: org.id)
      |> FieldHub.Repo.update()

    {user, org}
  end
end
