defmodule FieldHub.Repo.Migrations.CreateInventoryTables do
  use Ecto.Migration

  def change do
    # Parts table
    create table(:parts) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :sku, :string
      add :description, :text
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :quantity_on_hand, :integer, default: 0, null: false
      add :reorder_point, :integer, default: 5, null: false
      add :category, :string, default: "material"

      timestamps(type: :utc_datetime)
    end

    create index(:parts, [:organization_id])
    create unique_index(:parts, [:organization_id, :sku], where: "sku IS NOT NULL")
    create index(:parts, [:category])
    create index(:parts, [:quantity_on_hand])

    # Job parts join table
    create table(:job_parts) do
      add :job_id, references(:jobs, on_delete: :delete_all), null: false
      add :part_id, references(:parts, on_delete: :restrict), null: false
      add :quantity_used, :integer, default: 1, null: false
      add :unit_price_at_time, :decimal, precision: 10, scale: 2, null: false
      add :notes, :string

      timestamps(type: :utc_datetime)
    end

    create index(:job_parts, [:job_id])
    create index(:job_parts, [:part_id])
  end
end
