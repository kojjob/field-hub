defmodule FieldHub.Repo.Migrations.AddJobStatusConfigToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :job_status_config, {:array, :map}, default: []
    end
  end
end
