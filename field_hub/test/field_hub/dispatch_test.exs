defmodule FieldHub.DispatchTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Dispatch
  alias FieldHub.Dispatch.Technician
  alias FieldHub.Accounts

  import FieldHub.DispatchFixtures

  setup do
    {:ok, org} = Accounts.create_organization(%{name: "Test Org", slug: "test-org"})
    %{org: org}
  end

  describe "list_technicians/1" do
    test "returns all technicians for the organization", %{org: org} do
      tech1 = technician_fixture(org.id, %{name: "John Doe"})
      tech2 = technician_fixture(org.id, %{name: "Jane Smith"})

      technicians = Dispatch.list_technicians(org.id)

      assert length(technicians) == 2
      assert Enum.any?(technicians, &(&1.id == tech1.id))
      assert Enum.any?(technicians, &(&1.id == tech2.id))
    end

    test "does not return technicians from other organizations", %{org: org} do
      {:ok, other_org} = Accounts.create_organization(%{name: "Other Org", slug: "other-org"})
      _other_tech = technician_fixture(other_org.id, %{name: "Other Tech"})
      my_tech = technician_fixture(org.id, %{name: "My Tech"})

      technicians = Dispatch.list_technicians(org.id)

      assert length(technicians) == 1
      assert hd(technicians).id == my_tech.id
    end

    test "returns empty list when no technicians exist", %{org: org} do
      assert Dispatch.list_technicians(org.id) == []
    end
  end

  describe "get_technician!/2" do
    test "returns the technician with given id", %{org: org} do
      tech = technician_fixture(org.id)

      assert Dispatch.get_technician!(org.id, tech.id).id == tech.id
    end

    test "raises if technician belongs to different organization", %{org: org} do
      {:ok, other_org} = Accounts.create_organization(%{name: "Other Org", slug: "other-org-2"})
      other_tech = technician_fixture(other_org.id)

      assert_raise Ecto.NoResultsError, fn ->
        Dispatch.get_technician!(org.id, other_tech.id)
      end
    end

    test "raises if technician doesn't exist", %{org: org} do
      assert_raise Ecto.NoResultsError, fn ->
        Dispatch.get_technician!(org.id, 9999)
      end
    end
  end

  describe "create_technician/2" do
    test "creates technician with valid data", %{org: org} do
      valid_attrs = %{
        name: "John Doe",
        email: "john@example.com",
        phone: "555-123-4567",
        skills: ["HVAC", "Plumbing"],
        hourly_rate: Decimal.new("45.00"),
        color: "#3B82F6"
      }

      assert {:ok, %Technician{} = tech} = Dispatch.create_technician(org.id, valid_attrs)
      assert tech.name == "John Doe"
      assert tech.email == "john@example.com"
      assert tech.organization_id == org.id
      assert tech.status == "off_duty"
      assert "HVAC" in tech.skills
    end

    test "returns error changeset with invalid data", %{org: org} do
      assert {:error, %Ecto.Changeset{}} = Dispatch.create_technician(org.id, %{})
    end

    test "returns error for duplicate email within organization", %{org: org} do
      attrs = %{name: "John Doe", email: "john@example.com"}
      {:ok, _tech} = Dispatch.create_technician(org.id, attrs)

      assert {:error, changeset} = Dispatch.create_technician(org.id, %{name: "Jane Doe", email: "john@example.com"})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "allows same email in different organizations", %{org: org} do
      {:ok, other_org} = Accounts.create_organization(%{name: "Other Org", slug: "other-org-3"})
      attrs = %{name: "John Doe", email: "john@example.com"}

      assert {:ok, _tech1} = Dispatch.create_technician(org.id, attrs)
      assert {:ok, _tech2} = Dispatch.create_technician(other_org.id, attrs)
    end
  end

  describe "update_technician/2" do
    test "updates technician with valid data", %{org: org} do
      tech = technician_fixture(org.id)
      update_attrs = %{name: "Updated Name", phone: "555-999-8888"}

      assert {:ok, updated_tech} = Dispatch.update_technician(tech, update_attrs)
      assert updated_tech.name == "Updated Name"
      assert updated_tech.phone == "555-999-8888"
    end

    test "returns error changeset with invalid data", %{org: org} do
      tech = technician_fixture(org.id)

      assert {:error, %Ecto.Changeset{}} = Dispatch.update_technician(tech, %{name: nil})
    end
  end

  describe "update_technician_status/2" do
    test "updates technician status to available", %{org: org} do
      tech = technician_fixture(org.id, %{status: "on_job"})

      assert {:ok, updated} = Dispatch.update_technician_status(tech, "available")
      assert updated.status == "available"
    end

    test "updates technician status to on_job", %{org: org} do
      tech = technician_fixture(org.id)

      assert {:ok, updated} = Dispatch.update_technician_status(tech, "on_job")
      assert updated.status == "on_job"
    end

    test "updates technician status to off_duty", %{org: org} do
      tech = technician_fixture(org.id, %{status: "available"})

      assert {:ok, updated} = Dispatch.update_technician_status(tech, "off_duty")
      assert updated.status == "off_duty"
    end

    test "returns error for invalid status", %{org: org} do
      tech = technician_fixture(org.id)

      assert {:error, changeset} = Dispatch.update_technician_status(tech, "invalid")
      assert "is invalid" in errors_on(changeset).status
    end
  end

  describe "update_technician_location/3" do
    test "updates technician lat/lng", %{org: org} do
      tech = technician_fixture(org.id)

      assert {:ok, updated} = Dispatch.update_technician_location(tech, 33.749, -84.388)
      assert updated.current_lat == 33.749
      assert updated.current_lng == -84.388
    end
  end

  describe "archive_technician/1" do
    test "sets archived_at timestamp", %{org: org} do
      tech = technician_fixture(org.id)

      assert {:ok, archived} = Dispatch.archive_technician(tech)
      assert archived.archived_at != nil
    end

    test "archived technicians are excluded from list", %{org: org} do
      tech = technician_fixture(org.id)
      {:ok, _archived} = Dispatch.archive_technician(tech)

      assert Dispatch.list_technicians(org.id) == []
    end
  end

  describe "get_available_technicians/1" do
    test "returns only available technicians", %{org: org} do
      available = technician_fixture(org.id, %{status: "available", name: "Available"})
      _on_job = technician_fixture(org.id, %{status: "on_job", name: "On Job"})
      _off = technician_fixture(org.id, %{status: "off_duty", name: "Off"})

      technicians = Dispatch.get_available_technicians(org.id)

      assert length(technicians) == 1
      assert hd(technicians).id == available.id
    end
  end

  describe "get_technicians_with_skill/2" do
    test "returns technicians with matching skill", %{org: org} do
      hvac_tech = technician_fixture(org.id, %{skills: ["HVAC", "Plumbing"], name: "HVAC Tech"})
      _plumbing_only = technician_fixture(org.id, %{skills: ["Plumbing"], name: "Plumb Tech"})

      technicians = Dispatch.get_technicians_with_skill(org.id, "HVAC")

      assert length(technicians) == 1
      assert hd(technicians).id == hvac_tech.id
    end

    test "returns empty list if no technicians have skill", %{org: org} do
      _tech = technician_fixture(org.id, %{skills: ["Plumbing"]})

      assert Dispatch.get_technicians_with_skill(org.id, "Electrical") == []
    end
  end

  describe "count_technicians/1" do
    test "returns count of active technicians", %{org: org} do
      _tech1 = technician_fixture(org.id, %{name: "One"})
      _tech2 = technician_fixture(org.id, %{name: "Two"})
      archived = technician_fixture(org.id, %{name: "Archived"})
      Dispatch.archive_technician(archived)

      assert Dispatch.count_technicians(org.id) == 2
    end
  end

end
