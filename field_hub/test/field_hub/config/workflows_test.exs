defmodule FieldHub.Config.WorkflowsTest do
  use FieldHub.DataCase

  alias FieldHub.Config.Workflows
  alias FieldHub.Accounts

  describe "default_statuses/0" do
    test "returns list of default job statuses" do
      statuses = Workflows.default_statuses()

      assert is_list(statuses)
      assert length(statuses) >= 5

      # Check required fields
      for status <- statuses do
        assert Map.has_key?(status, :key)
        assert Map.has_key?(status, :label)
        assert Map.has_key?(status, :color)
        assert Map.has_key?(status, :order)
      end
    end

    test "includes core statuses" do
      keys = Enum.map(Workflows.default_statuses(), & &1.key)

      assert "pending" in keys
      assert "scheduled" in keys
      assert "in_progress" in keys
      assert "completed" in keys
    end
  end

  describe "get_statuses/1" do
    test "returns custom statuses for organization with config" do
      {:ok, org} = Accounts.create_organization(%{
        name: "Test Org",
        slug: "test-org",
        job_status_config: [
          %{"key" => "new", "label" => "New Request", "color" => "#3B82F6", "order" => 1},
          %{"key" => "approved", "label" => "Approved", "color" => "#10B981", "order" => 2}
        ]
      })

      statuses = Workflows.get_statuses(org)

      assert length(statuses) == 2
      assert Enum.at(statuses, 0)["key"] == "new"
      assert Enum.at(statuses, 0)["label"] == "New Request"
    end

    test "returns defaults for organization without config" do
      {:ok, org} = Accounts.create_organization(%{name: "Test Org", slug: "test-org-2"})

      statuses = Workflows.get_statuses(org)

      assert length(statuses) >= 5
    end
  end

  describe "get_status_label/2" do
    test "returns label for status key" do
      {:ok, org} = Accounts.create_organization(%{name: "Test Org", slug: "test-org-3"})

      assert Workflows.get_status_label(org, "pending") == "Pending"
      assert Workflows.get_status_label(org, "in_progress") == "In Progress"
    end

    test "returns key if status not found" do
      {:ok, org} = Accounts.create_organization(%{name: "Test Org", slug: "test-org-4"})

      assert Workflows.get_status_label(org, "unknown_status") == "unknown_status"
    end
  end

  describe "get_status_color/2" do
    test "returns color for status key" do
      {:ok, org} = Accounts.create_organization(%{name: "Test Org", slug: "test-org-5"})

      color = Workflows.get_status_color(org, "completed")
      assert String.starts_with?(color, "#")
    end
  end

  describe "next_statuses/2" do
    test "returns allowed next statuses from current status" do
      {:ok, org} = Accounts.create_organization(%{name: "Test Org", slug: "test-org-6"})

      next = Workflows.next_statuses(org, "pending")
      keys = Enum.map(next, & &1.key)

      assert "scheduled" in keys or "cancelled" in keys
    end
  end

  describe "industry_presets/0" do
    test "returns available workflow presets" do
      presets = Workflows.industry_presets()

      assert is_list(presets)
      assert length(presets) >= 3

      keys = Enum.map(presets, & &1.key)
      assert :field_service in keys
      assert :healthcare in keys
    end
  end
end
