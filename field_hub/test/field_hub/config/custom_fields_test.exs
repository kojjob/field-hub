defmodule FieldHub.Config.CustomFieldsTest do
  use FieldHub.DataCase

  alias FieldHub.Config.CustomFields
  alias FieldHub.Config.CustomFieldDefinition
  import FieldHub.AccountsFixtures

  describe "custom_field_definitions" do
    setup do
      org = organization_fixture()
      {:ok, org: org}
    end

    test "list_definitions/1 returns all definitions for org", %{org: org} do
      {:ok, field1} = CustomFields.create_definition(%{
        name: "Field 1",
        key: "field_1",
        type: "text",
        target: "job",
        organization_id: org.id
      })

      assert CustomFields.list_definitions(org) == [field1]
    end

    test "create_definition/1 with valid data creates a definition", %{org: org} do
      valid_attrs = %{
        name: "Warranty Info",
        key: "warranty_info",
        type: "text",
        target: "job",
        organization_id: org.id
      }

      assert {:ok, %CustomFieldDefinition{} = field} = CustomFields.create_definition(valid_attrs)
      assert field.name == "Warranty Info"
      assert field.key == "warranty_info"
      assert field.target == "job"
    end
  end
end
