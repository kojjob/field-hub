defmodule FieldHub.InventoryTest do
  use FieldHub.DataCase

  alias FieldHub.Inventory
  alias FieldHub.Inventory.Part

  import FieldHub.AccountsFixtures

  describe "parts" do
    setup do
      org = organization_fixture()
      %{org: org}
    end

    @valid_attrs %{
      name: "HVAC Filter",
      sku: "HVAC-001",
      description: "Standard 20x20 filter",
      unit_price: Decimal.new("25.99"),
      quantity_on_hand: 50,
      reorder_point: 10,
      category: "material"
    }

    @update_attrs %{
      name: "HVAC Filter Premium",
      unit_price: Decimal.new("35.99"),
      quantity_on_hand: 75
    }

    @invalid_attrs %{name: nil, unit_price: nil}

    test "list_parts/1 returns all parts for an organization", %{org: org} do
      {:ok, part} = Inventory.create_part(org.id, @valid_attrs)
      parts = Inventory.list_parts(org.id)
      assert length(parts) == 1
      assert hd(parts).id == part.id
    end

    test "get_part!/2 returns the part with given id", %{org: org} do
      {:ok, part} = Inventory.create_part(org.id, @valid_attrs)
      fetched = Inventory.get_part!(org.id, part.id)
      assert fetched.id == part.id
      assert fetched.name == "HVAC Filter"
    end

    test "create_part/2 with valid data creates a part", %{org: org} do
      assert {:ok, %Part{} = part} = Inventory.create_part(org.id, @valid_attrs)
      assert part.name == "HVAC Filter"
      assert part.sku == "HVAC-001"
      assert Decimal.equal?(part.unit_price, Decimal.new("25.99"))
      assert part.quantity_on_hand == 50
    end

    test "create_part/2 with invalid data returns error changeset", %{org: org} do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_part(org.id, @invalid_attrs)
    end

    test "update_part/2 with valid data updates the part", %{org: org} do
      {:ok, part} = Inventory.create_part(org.id, @valid_attrs)
      assert {:ok, %Part{} = updated} = Inventory.update_part(part, @update_attrs)
      assert updated.name == "HVAC Filter Premium"
      assert Decimal.equal?(updated.unit_price, Decimal.new("35.99"))
    end

    test "delete_part/1 deletes the part", %{org: org} do
      {:ok, part} = Inventory.create_part(org.id, @valid_attrs)
      assert {:ok, %Part{}} = Inventory.delete_part(part)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_part!(org.id, part.id) end
    end

    test "adjust_stock/2 increases stock", %{org: org} do
      {:ok, part} = Inventory.create_part(org.id, @valid_attrs)
      assert {:ok, updated} = Inventory.adjust_stock(part, 10)
      assert updated.quantity_on_hand == 60
    end

    test "adjust_stock/2 decreases stock", %{org: org} do
      {:ok, part} = Inventory.create_part(org.id, @valid_attrs)
      assert {:ok, updated} = Inventory.adjust_stock(part, -20)
      assert updated.quantity_on_hand == 30
    end

    test "adjust_stock/2 does not go below zero", %{org: org} do
      {:ok, part} = Inventory.create_part(org.id, @valid_attrs)
      assert {:ok, updated} = Inventory.adjust_stock(part, -100)
      assert updated.quantity_on_hand == 0
    end

    test "search_parts/2 finds parts by name", %{org: org} do
      {:ok, _part} = Inventory.create_part(org.id, @valid_attrs)
      results = Inventory.search_parts(org.id, "HVAC")
      assert length(results) == 1
    end

    test "list_low_stock_parts/1 returns parts at or below reorder point", %{org: org} do
      {:ok, _part} = Inventory.create_part(org.id, Map.put(@valid_attrs, :quantity_on_hand, 5))
      low_stock = Inventory.list_low_stock_parts(org.id)
      assert length(low_stock) == 1
    end

    test "get_inventory_stats/1 returns correct stats", %{org: org} do
      {:ok, _} = Inventory.create_part(org.id, @valid_attrs)
      stats = Inventory.get_inventory_stats(org.id)
      assert stats.total_parts == 1
      assert stats.low_stock_count == 0
    end
  end
end
