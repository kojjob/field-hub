defmodule FieldHub.Repo.Migrations.AddOnboardingFieldsToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :industry, :string
      add :size, :string
      add :currency, :string, default: "USD"
      add :onboarding_completed_at, :utc_datetime
    end
  end
end
