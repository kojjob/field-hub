defmodule FieldHub.Config.TerminologyTest do
  use FieldHub.DataCase

  alias FieldHub.Config.Terminology
  alias FieldHub.Accounts.Organization

  describe "get_terminology/1" do
    test "returns default terminology for nil" do
      org = %Organization{terminology: nil}
      terms = Terminology.get_terminology(org)

      assert terms["worker_label"] == "Technician"
      assert terms["client_label"] == "Customer"
      assert terms["task_label"] == "Job"
    end

    test "merges custom terminology with defaults" do
      org = %Organization{
        terminology: %{
          "worker_label" => "Caregiver",
          "client_label" => "Patient"
        }
      }

      terms = Terminology.get_terminology(org)

      assert terms["worker_label"] == "Caregiver"
      assert terms["client_label"] == "Patient"
      assert terms["task_label"] == "Job"
    end
  end

  describe "get/2" do
    test "retrieves specific terminology by string key" do
      org = %Organization{terminology: %{"worker_label" => "Driver"}}
      assert Terminology.get(org, "worker_label") == "Driver"
    end

    test "retrieves specific terminology by atom key" do
      org = %Organization{terminology: %{"task_label" => "Delivery"}}
      assert Terminology.get(org, :task_label) == "Delivery"
    end

    test "returns default for missing keys" do
      org = %Organization{terminology: %{}}
      assert Terminology.get(org, :dispatch_label) == "Dispatch"
    end
  end

  describe "convenience functions" do
    test "worker_label/1 returns correct value" do
      org = %Organization{terminology: %{"worker_label" => "Inspector"}}
      assert Terminology.worker_label(org) == "Inspector"
    end

    test "task_label_plural/1 returns correct value" do
      org = %Organization{terminology: %{"task_label_plural" => "Inspections"}}
      assert Terminology.task_label_plural(org) == "Inspections"
    end
  end

  describe "presets" do
    test "healthcare preset returns correct terminology" do
      preset = Terminology.preset(:healthcare)

      assert preset["worker_label"] == "Caregiver"
      assert preset["client_label"] == "Patient"
      assert preset["task_label"] == "Visit"
    end

    test "delivery preset returns correct terminology" do
      preset = Terminology.preset(:delivery)

      assert preset["worker_label"] == "Driver"
      assert preset["task_label"] == "Delivery"
    end

    test "unknown preset returns defaults" do
      preset = Terminology.preset(:unknown)
      assert preset["worker_label"] == "Technician"
    end

    test "available_presets returns list of presets" do
      presets = Terminology.available_presets()
      assert :healthcare in presets
      assert :delivery in presets
      assert :inspection in presets
    end
  end
end
