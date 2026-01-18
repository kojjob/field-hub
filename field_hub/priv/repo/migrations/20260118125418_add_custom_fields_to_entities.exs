defmodule FieldHub.Repo.Migrations.AddCustomFieldsToEntities do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :custom_fields, :map, default: %{}
    end

    alter table(:customers) do
      add :custom_fields, :map, default: %{}
    end

    alter table(:technicians) do
      add :custom_fields, :map, default: %{}
    end
  end
end
