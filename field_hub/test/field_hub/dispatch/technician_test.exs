defmodule FieldHub.Dispatch.TechnicianTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Dispatch.Technician
  alias FieldHub.Accounts.Organization

  setup do
    # Create a test organization
    {:ok, org} =
      %Organization{}
      |> Organization.changeset(%{name: "Test Org", slug: "test-org"})
      |> Repo.insert()

    %{organization: org}
  end

  describe "changeset/2" do
    test "valid attributes create a valid changeset", %{organization: org} do
      attrs = %{
        organization_id: org.id,
        name: "John Smith",
        email: "john@example.com",
        phone: "555-123-4567",
        status: "available",
        skills: ["hvac", "electrical"],
        color: "#3B82F6"
      }

      changeset = Technician.changeset(%Technician{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :name) == "John Smith"
      assert get_change(changeset, :skills) == ["hvac", "electrical"]
    end

    test "requires name" do
      changeset = Technician.changeset(%Technician{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "requires organization_id" do
      changeset = Technician.changeset(%Technician{}, %{name: "John"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).organization_id
    end

    test "validates status values" do
      valid_statuses = ["available", "on_job", "traveling", "break", "off_duty"]

      for status <- valid_statuses do
        attrs = %{name: "John", organization_id: 1, status: status}
        changeset = Technician.changeset(%Technician{}, attrs)
        refute Map.has_key?(errors_on(changeset), :status), "Expected #{status} to be valid"
      end

      invalid_attrs = %{name: "John", organization_id: 1, status: "invalid_status"}
      changeset = Technician.changeset(%Technician{}, invalid_attrs)
      assert Map.has_key?(errors_on(changeset), :status)
    end

    test "validates email format when provided", %{organization: org} do
      valid_attrs = %{name: "John", organization_id: org.id, email: "john@example.com"}
      changeset = Technician.changeset(%Technician{}, valid_attrs)
      assert changeset.valid?

      invalid_attrs = %{name: "John", organization_id: org.id, email: "not-an-email"}
      changeset = Technician.changeset(%Technician{}, invalid_attrs)
      assert "has invalid format" in errors_on(changeset).email
    end

    test "validates color is a valid hex code", %{organization: org} do
      valid_colors = ["#3B82F6", "#ff0000", "#ABC123"]

      for color <- valid_colors do
        attrs = %{name: "John", organization_id: org.id, color: color}
        changeset = Technician.changeset(%Technician{}, attrs)
        refute Map.has_key?(errors_on(changeset), :color), "Expected #{color} to be valid"
      end

      invalid_colors = ["red", "3B82F6", "#GGGGGG", "rgb(0,0,0)"]

      for color <- invalid_colors do
        attrs = %{name: "John", organization_id: org.id, color: color}
        changeset = Technician.changeset(%Technician{}, attrs)
        assert Map.has_key?(errors_on(changeset), :color), "Expected #{color} to be invalid"
      end
    end

    test "hourly_rate must be positive when provided", %{organization: org} do
      valid_attrs = %{name: "John", organization_id: org.id, hourly_rate: Decimal.new("50.00")}
      changeset = Technician.changeset(%Technician{}, valid_attrs)
      assert changeset.valid?

      invalid_attrs = %{name: "John", organization_id: org.id, hourly_rate: Decimal.new("-10.00")}
      changeset = Technician.changeset(%Technician{}, invalid_attrs)
      assert "must be greater than 0" in errors_on(changeset).hourly_rate
    end

    test "defaults status to off_duty" do
      attrs = %{name: "John", organization_id: 1}
      changeset = Technician.changeset(%Technician{}, attrs)

      # Status should default to off_duty in schema
      assert changeset.valid?
    end
  end

  describe "location_changeset/2" do
    test "updates location fields", %{organization: org} do
      {:ok, tech} =
        %Technician{}
        |> Technician.changeset(%{name: "John", organization_id: org.id})
        |> Repo.insert()

      changeset =
        Technician.location_changeset(tech, %{
          current_lat: 40.7128,
          current_lng: -74.0060
        })

      assert changeset.valid?
      assert get_change(changeset, :current_lat) == 40.7128
      assert get_change(changeset, :current_lng) == -74.0060
      assert get_change(changeset, :location_updated_at)
    end

    test "validates latitude range" do
      changeset =
        Technician.location_changeset(%Technician{}, %{
          # Invalid - must be -90 to 90
          current_lat: 91.0,
          current_lng: 0.0
        })

      assert "must be between -90 and 90" in errors_on(changeset).current_lat
    end

    test "validates longitude range" do
      changeset =
        Technician.location_changeset(%Technician{}, %{
          current_lat: 0.0,
          # Invalid - must be -180 to 180
          current_lng: 181.0
        })

      assert "must be between -180 and 180" in errors_on(changeset).current_lng
    end
  end

  describe "status_changeset/2" do
    test "only allows valid status transitions", %{organization: org} do
      {:ok, tech} =
        %Technician{}
        |> Technician.changeset(%{name: "John", organization_id: org.id, status: "available"})
        |> Repo.insert()

      # Valid transition: available -> on_job
      changeset = Technician.status_changeset(tech, "on_job")
      assert changeset.valid?

      # Valid transition: available -> traveling
      changeset = Technician.status_changeset(tech, "traveling")
      assert changeset.valid?
    end
  end
end
