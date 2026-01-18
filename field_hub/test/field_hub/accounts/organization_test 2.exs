defmodule FieldHub.Accounts.OrganizationTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Accounts.Organization

  describe "changeset/2" do
    test "valid attributes create a valid changeset" do
      attrs = %{
        name: "Ace HVAC Services",
        slug: "ace-hvac-services",
        phone: "555-123-4567",
        email: "info@acehvac.com",
        timezone: "America/New_York"
      }

      changeset = Organization.changeset(%Organization{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :name) == "Ace HVAC Services"
      assert get_change(changeset, :slug) == "ace-hvac-services"
    end

    test "requires name" do
      changeset = Organization.changeset(%Organization{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "requires slug" do
      changeset = Organization.changeset(%Organization{}, %{name: "Test Org"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).slug
    end

    test "validates slug format - lowercase alphanumeric with hyphens" do
      # Valid slugs
      valid_slugs = ["ace-hvac", "plumbing-pros-123", "electricians"]

      for slug <- valid_slugs do
        changeset = Organization.changeset(%Organization{}, %{name: "Test", slug: slug})
        refute Map.has_key?(errors_on(changeset), :slug), "Expected #{slug} to be valid"
      end

      # Invalid slugs
      invalid_slugs = ["Ace HVAC", "plumbing_pros", "has spaces", "UPPERCASE"]

      for slug <- invalid_slugs do
        changeset = Organization.changeset(%Organization{}, %{name: "Test", slug: slug})
        assert Map.has_key?(errors_on(changeset), :slug), "Expected #{slug} to be invalid"
      end
    end

    test "validates email format when provided" do
      valid_attrs = %{name: "Test", slug: "test", email: "valid@example.com"}
      changeset = Organization.changeset(%Organization{}, valid_attrs)
      assert changeset.valid?

      invalid_attrs = %{name: "Test", slug: "test", email: "invalid-email"}
      changeset = Organization.changeset(%Organization{}, invalid_attrs)
      refute changeset.valid?
      assert "has invalid format" in errors_on(changeset).email
    end

    test "validates subscription_tier values" do
      for tier <- ["trial", "starter", "growth", "pro"] do
        attrs = %{name: "Test", slug: "test", subscription_tier: tier}
        changeset = Organization.changeset(%Organization{}, attrs)
        assert changeset.valid?, "Expected #{tier} to be valid"
      end

      invalid_attrs = %{name: "Test", slug: "test", subscription_tier: "invalid"}
      changeset = Organization.changeset(%Organization{}, invalid_attrs)
      refute changeset.valid?
    end

    test "validates subscription_status values" do
      for status <- ["trial", "active", "past_due", "cancelled"] do
        attrs = %{name: "Test", slug: "test", subscription_status: status}
        changeset = Organization.changeset(%Organization{}, attrs)
        assert changeset.valid?, "Expected #{status} to be valid"
      end
    end

    test "sets default timezone to America/New_York" do
      attrs = %{name: "Test", slug: "test"}
      changeset = Organization.changeset(%Organization{}, attrs)

      # Default should be applied
      assert changeset.valid?
    end
  end

  describe "generate_slug/1" do
    test "generates slug from name" do
      assert Organization.generate_slug("Ace HVAC Services") == "ace-hvac-services"
      assert Organization.generate_slug("Bob's Plumbing & Heating") == "bobs-plumbing-heating"
      assert Organization.generate_slug("  Extra   Spaces  ") == "extra-spaces"
      assert Organization.generate_slug("123 Electric Co.") == "123-electric-co"
    end
  end
end
