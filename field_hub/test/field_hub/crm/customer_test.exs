defmodule FieldHub.CRM.CustomerTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.CRM.Customer
  alias FieldHub.Accounts.Organization

  setup do
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
        name: "Jane Doe",
        email: "jane@example.com",
        phone: "555-987-6543",
        address_line1: "123 Main St",
        city: "New York",
        state: "NY",
        zip: "10001"
      }

      changeset = Customer.changeset(%Customer{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :name) == "Jane Doe"
    end

    test "requires name" do
      changeset = Customer.changeset(%Customer{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "requires organization_id" do
      changeset = Customer.changeset(%Customer{}, %{name: "Jane"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).organization_id
    end

    test "validates email format when provided", %{organization: org} do
      valid_attrs = %{name: "Jane", organization_id: org.id, email: "jane@example.com"}
      changeset = Customer.changeset(%Customer{}, valid_attrs)
      assert changeset.valid?

      invalid_attrs = %{name: "Jane", organization_id: org.id, email: "not-valid"}
      changeset = Customer.changeset(%Customer{}, invalid_attrs)
      assert "has invalid format" in errors_on(changeset).email
    end

    test "validates preferred_contact values", %{organization: org} do
      for method <- ["phone", "email", "sms"] do
        attrs = %{name: "Jane", organization_id: org.id, preferred_contact: method}
        changeset = Customer.changeset(%Customer{}, attrs)
        assert changeset.valid?, "Expected #{method} to be valid"
      end

      invalid_attrs = %{name: "Jane", organization_id: org.id, preferred_contact: "fax"}
      changeset = Customer.changeset(%Customer{}, invalid_attrs)
      refute changeset.valid?
    end

    test "validates state code format", %{organization: org} do
      valid_attrs = %{name: "Jane", organization_id: org.id, state: "NY"}
      changeset = Customer.changeset(%Customer{}, valid_attrs)
      assert changeset.valid?

      # 2-letter state codes only
      invalid_attrs = %{name: "Jane", organization_id: org.id, state: "New York"}
      changeset = Customer.changeset(%Customer{}, invalid_attrs)
      assert "must be a 2-letter state code" in errors_on(changeset).state
    end

    test "validates zip code format", %{organization: org} do
      valid_zips = ["10001", "90210-1234"]

      for zip <- valid_zips do
        attrs = %{name: "Jane", organization_id: org.id, zip: zip}
        changeset = Customer.changeset(%Customer{}, attrs)
        refute Map.has_key?(errors_on(changeset), :zip), "Expected #{zip} to be valid"
      end

      invalid_zips = ["1234", "ABCDE", "123456789"]

      for zip <- invalid_zips do
        attrs = %{name: "Jane", organization_id: org.id, zip: zip}
        changeset = Customer.changeset(%Customer{}, attrs)
        assert Map.has_key?(errors_on(changeset), :zip), "Expected #{zip} to be invalid"
      end
    end

    test "portal_enabled defaults to true" do
      attrs = %{name: "Jane", organization_id: 1}
      changeset = Customer.changeset(%Customer{}, attrs)

      assert changeset.valid?
    end
  end

  describe "generate_portal_token/1" do
    test "generates a unique token", %{organization: org} do
      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(%{name: "Jane", organization_id: org.id})
        |> Repo.insert()

      changeset = Customer.generate_portal_token(customer)

      assert changeset.valid?
      token = get_change(changeset, :portal_token)
      assert is_binary(token)
      assert String.length(token) >= 20
    end
  end

  describe "full_address/1" do
    test "returns formatted address" do
      customer = %Customer{
        address_line1: "123 Main St",
        address_line2: "Apt 4B",
        city: "New York",
        state: "NY",
        zip: "10001"
      }

      assert Customer.full_address(customer) == "123 Main St, Apt 4B, New York, NY 10001"
    end

    test "handles missing address_line2" do
      customer = %Customer{
        address_line1: "123 Main St",
        city: "New York",
        state: "NY",
        zip: "10001"
      }

      assert Customer.full_address(customer) == "123 Main St, New York, NY 10001"
    end
  end
end
