defmodule FieldHub.Config.IndustryTemplatesTest do
  use FieldHub.DataCase

  alias FieldHub.Config.IndustryTemplates

  describe "templates/0" do
    test "returns list of industry templates" do
      templates = IndustryTemplates.templates()

      assert is_list(templates)
      assert length(templates) == 5
    end

    test "each template has required keys" do
      for template <- IndustryTemplates.templates() do
        assert Map.has_key?(template, :key)
        assert Map.has_key?(template, :name)
        assert Map.has_key?(template, :description)
        assert Map.has_key?(template, :icon)
        assert Map.has_key?(template, :primary_color)
        assert Map.has_key?(template, :secondary_color)
      end
    end

    test "includes core industry types" do
      keys = Enum.map(IndustryTemplates.templates(), & &1.key)

      assert :field_service in keys
      assert :healthcare in keys
      assert :delivery in keys
      assert :inspection in keys
      assert :cleaning in keys
    end
  end

  describe "get_template/1" do
    test "returns template by atom key" do
      template = IndustryTemplates.get_template(:healthcare)

      assert template.key == :healthcare
      assert template.name == "Home Healthcare"
    end

    test "returns template by string key" do
      template = IndustryTemplates.get_template("delivery")

      assert template.key == :delivery
    end

    test "returns nil for unknown key" do
      assert IndustryTemplates.get_template(:unknown) == nil
      assert IndustryTemplates.get_template("nonexistent") == nil
    end
  end

  describe "get_config/1" do
    test "returns terminology and colors for template" do
      config = IndustryTemplates.get_config(:healthcare)

      assert config.terminology["worker_label"] == "Caregiver"
      assert config.terminology["client_label"] == "Patient"
      assert config.primary_color == "#10B981"
    end

    test "returns defaults for unknown template" do
      config = IndustryTemplates.get_config(:unknown)

      assert config.terminology["worker_label"] == "Technician"
      assert config.primary_color == "#3B82F6"
    end
  end

  describe "apply_template/2" do
    test "merges template config into attrs" do
      attrs = %{name: "Test Org", slug: "test-org"}

      result = IndustryTemplates.apply_template(attrs, :healthcare)

      assert result.name == "Test Org"
      assert result.slug == "test-org"
      assert result.terminology["worker_label"] == "Caregiver"
      assert result.primary_color == "#10B981"
    end
  end
end
