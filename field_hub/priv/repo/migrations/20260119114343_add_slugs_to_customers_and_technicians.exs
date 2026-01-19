defmodule FieldHub.Repo.Migrations.AddSlugsToCustomersAndTechnicians do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :slug, :string
    end

    create unique_index(:customers, [:organization_id, :slug])

    alter table(:technicians) do
      add :slug, :string
    end

    create unique_index(:technicians, [:organization_id, :slug])
  end
end
