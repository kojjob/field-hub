defmodule FieldHub.Repo.Migrations.CreateCustomFieldDefinitions do
  use Ecto.Migration

  def change do
    create table(:custom_field_definitions) do
      add :name, :string, null: false
      add :key, :string, null: false
      add :type, :string, null: false
      add :target, :string, null: false
      add :required, :boolean, default: false, null: false
      add :options, {:array, :string}, default: []
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:custom_field_definitions, [:organization_id, :target, :key])
    create index(:custom_field_definitions, [:organization_id, :target])
  end
end
