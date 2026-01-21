defmodule FieldHub.Repo.Migrations.AddPreferencesToCustomers do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :preferences, :map, default: "{}"
    end
  end
end
