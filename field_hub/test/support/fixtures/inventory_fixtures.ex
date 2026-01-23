defmodule FieldHub.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FieldHub.Inventory` context.
  """

  @doc """
  Generate a part.
  """
  def part_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        category: "some category",
        description: "some description",
        name: "some name",
        quantity_on_hand: 42,
        reorder_point: 42,
        sku: "some sku",
        unit_price: "120.5"
      })

    {:ok, part} = FieldHub.Inventory.create_part(scope, attrs)
    part
  end
end
