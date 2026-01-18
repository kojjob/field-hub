defmodule FieldHub.Config.CustomFieldDefinitionTest do
  use FieldHub.DataCase

  alias FieldHub.Config.CustomFieldDefinition

  describe "changeset/2" do
    test "validates required fields" do
      changeset = CustomFieldDefinition.changeset(%CustomFieldDefinition{}, %{})

      assert %{
               name: ["can't be blank"],
               key: ["can't be blank"],
               type: ["can't be blank"],
               target: ["can't be blank"],
               organization_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates type inclusion" do
      changeset =
        CustomFieldDefinition.changeset(%CustomFieldDefinition{}, %{
          name: "Test",
          key: "test",
          type: "invalid_type",
          target: "job",
          organization_id: 1
        })

      assert "is invalid" in errors_on(changeset).type
    end

    test "validates target inclusion" do
      changeset =
        CustomFieldDefinition.changeset(%CustomFieldDefinition{}, %{
          name: "Test",
          key: "test",
          type: "text",
          target: "invalid_target",
          organization_id: 1
        })

      assert "is invalid" in errors_on(changeset).target
    end

    test "validates key format" do
      changeset =
        CustomFieldDefinition.changeset(%CustomFieldDefinition{}, %{
          name: "Test",
          key: "Invalid Key",
          type: "text",
          target: "job",
          organization_id: 1
        })

      assert "must be lowercase alphanumeric with underscores" in errors_on(changeset).key
    end

    test "creates valid changeset" do
      changeset =
        CustomFieldDefinition.changeset(%CustomFieldDefinition{}, %{
          name: "Warranty Info",
          key: "warranty_info",
          type: "text",
          target: "job",
          organization_id: 1,
          required: true
        })

      assert changeset.valid?
    end
  end
end
