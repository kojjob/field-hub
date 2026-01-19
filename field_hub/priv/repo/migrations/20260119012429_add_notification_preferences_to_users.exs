defmodule FieldHub.Repo.Migrations.AddNotificationPreferencesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notify_on_new_jobs, :boolean, default: true, null: false
      add :notify_on_job_updates, :boolean, default: true, null: false
      add :notify_marketing, :boolean, default: false, null: false
    end
  end
end
