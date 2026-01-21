defmodule FieldHub.CRM.InternationalCustomerTest do
  use FieldHub.DataCase

  alias FieldHub.CRM.Customer

  describe "international zip codes" do
    test "validates US zip code strict format" do
      changeset = Customer.changeset(%Customer{}, %{country: "US", zip: "123"})
      assert "must be a valid ZIP code" in errors_on(changeset).zip

      # Defaults to US logic if nil? No, schema default is built into struct, but changeset might verify against passed params.
      changeset = Customer.changeset(%Customer{}, %{country: nil, zip: "123"})
      # Actually if we pass a struct with default country="US", it will use that.
      # Let's verify defaults.
    end

    test "allows arbitrary zip code for non-US countries" do
      params = %{
        name: "Foreign Customer",
        organization_id: 1,
        country: "CA",
        state: "Ontario",
        # Canadian format
        zip: "M5V 2T6"
      }

      changeset = Customer.changeset(%Customer{}, params)
      refute changeset.errors[:zip]

      params_uk = %{
        name: "UK Customer",
        organization_id: 1,
        country: "GB",
        state: "London",
        zip: "SW1A 1AA"
      }

      changeset_uk = Customer.changeset(%Customer{}, params_uk)
      refute changeset_uk.errors[:zip]
    end
  end
end
