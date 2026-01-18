defmodule FieldHub.CRMTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.CRM
  alias FieldHub.CRM.Customer
  alias FieldHub.Accounts

  setup do
    {:ok, org} = Accounts.create_organization(%{name: "CRM Test Org", slug: "crm-test-org"})
    %{org: org}
  end

  describe "list_customers/1" do
    test "returns all customers for the organization", %{org: org} do
      cust1 = customer_fixture(org.id, %{name: "Alice"})
      cust2 = customer_fixture(org.id, %{name: "Bob"})

      customers = CRM.list_customers(org.id)

      assert length(customers) == 2
      assert Enum.any?(customers, &(&1.id == cust1.id))
      assert Enum.any?(customers, &(&1.id == cust2.id))
    end

    test "does not return customers from other organizations", %{org: org} do
      {:ok, other_org} = Accounts.create_organization(%{name: "Other Org", slug: "other-org"})
      _other_cust = customer_fixture(other_org.id, %{name: "Other Customer"})
      my_cust = customer_fixture(org.id, %{name: "My Customer"})

      customers = CRM.list_customers(org.id)

      assert length(customers) == 1
      assert hd(customers).id == my_cust.id
    end

    test "returns empty list when no customers exist", %{org: org} do
      assert CRM.list_customers(org.id) == []
    end
  end

  describe "get_customer!/2" do
    test "returns the customer with given id", %{org: org} do
      cust = customer_fixture(org.id)
      assert CRM.get_customer!(org.id, cust.id).id == cust.id
    end

    test "raises if customer belongs to different organization", %{org: org} do
      {:ok, other_org} = Accounts.create_organization(%{name: "Other Org", slug: "other-org-2"})
      other_cust = customer_fixture(other_org.id)

      assert_raise Ecto.NoResultsError, fn ->
        CRM.get_customer!(org.id, other_cust.id)
      end
    end
  end

  describe "create_customer/2" do
    test "creates customer with valid data", %{org: org} do
      valid_attrs = %{
        name: "John Doe",
        email: "john@example.com",
        phone: "555-0100",
        address_line1: "123 Main St",
        city: "Austin",
        state: "TX",
        zip: "78701",
        preferred_contact: "email"
      }

      assert {:ok, %Customer{} = customer} = CRM.create_customer(org.id, valid_attrs)
      assert customer.name == "John Doe"
      assert customer.email == "john@example.com"
      assert customer.state == "TX"
      assert customer.portal_token != nil
      assert customer.organization_id == org.id
    end

    test "returns error with invalid data", %{org: org} do
      assert {:error, %Ecto.Changeset{}} = CRM.create_customer(org.id, %{name: nil})
    end

    test "generates portal token automatically", %{org: org} do
      {:ok, customer} = CRM.create_customer(org.id, %{name: "Token Test"})
      assert customer.portal_token != nil
    end
  end

  describe "update_customer/2" do
    test "updates customer with valid data", %{org: org} do
      customer = customer_fixture(org.id)
      update_attrs = %{name: "Updated Name", notes: "Updated notes"}

      assert {:ok, updated} = CRM.update_customer(customer, update_attrs)
      assert updated.name == "Updated Name"
      assert updated.notes == "Updated notes"
    end

    test "returns error with invalid data", %{org: org} do
      customer = customer_fixture(org.id)

      assert {:error, %Ecto.Changeset{}} =
               CRM.update_customer(customer, %{email: "invalid-email"})
    end
  end

  describe "archive_customer/1" do
    test "sets archived_at timestamp", %{org: org} do
      customer = customer_fixture(org.id)
      assert {:ok, archived} = CRM.archive_customer(customer)
      assert archived.archived_at != nil
    end

    test "archived customers are excluded from list", %{org: org} do
      customer = customer_fixture(org.id)
      {:ok, _archived} = CRM.archive_customer(customer)

      assert CRM.list_customers(org.id) == []
    end
  end

  describe "search_customers/2" do
    test "searches by name", %{org: org} do
      match = customer_fixture(org.id, %{name: "John Match"})
      _miss = customer_fixture(org.id, %{name: "No"})

      results = CRM.search_customers(org.id, "Match")
      assert length(results) == 1
      assert hd(results).id == match.id
    end

    test "searches by email", %{org: org} do
      match = customer_fixture(org.id, %{name: "C1", email: "match@example.com"})
      _miss = customer_fixture(org.id, %{name: "C2", email: "miss@example.com"})

      results = CRM.search_customers(org.id, "match@")
      assert length(results) == 1
      assert hd(results).id == match.id
    end

    test "searches by phone", %{org: org} do
      match = customer_fixture(org.id, %{name: "C1", phone: "555-9999"})
      _miss = customer_fixture(org.id, %{name: "C2", phone: "555-1111"})

      results = CRM.search_customers(org.id, "9999")
      assert length(results) == 1
      assert hd(results).id == match.id
    end

    test "searches by address", %{org: org} do
      match = customer_fixture(org.id, %{name: "C1", address_line1: "123 Elm St"})
      _miss = customer_fixture(org.id, %{name: "C2", address_line1: "456 Oak St"})

      results = CRM.search_customers(org.id, "Elm")
      assert length(results) == 1
      assert hd(results).id == match.id
    end
  end

  defp customer_fixture(org_id, attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> Enum.into(%{
        name: "Customer #{System.unique_integer([:positive])}",
        email: "customer#{System.unique_integer([:positive])}@example.com",
        state: "CA",
        zip: "90210"
      })
      |> then(&CRM.create_customer(org_id, &1))

    customer
  end
end
