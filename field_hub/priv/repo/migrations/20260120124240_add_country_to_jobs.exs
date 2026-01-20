defmodule FieldHub.Repo.Migrations.AddCountryToJobs do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :service_country, :string, default: "US"
    end
  end
end
