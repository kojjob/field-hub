defmodule FieldHub.CRMFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FieldHub.CRM` context.
  """

  @doc """
  Generate a customer.
  """
  def customer_fixture(org_id, attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> Enum.into(%{
        name: "Test Customer #{System.unique_integer([:positive])}",
        email: "customer#{System.unique_integer([:positive])}@example.com",
        phone: "555-#{System.unique_integer([:positive])}",
        address_line1: "123 Main St",
        city: "New York",
        state: "NY",
        zip: "10001",
        country: "US"
      })
      |> then(&FieldHub.CRM.create_customer(org_id, &1))

    customer
  end
end
