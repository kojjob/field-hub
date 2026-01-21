defmodule FieldHub.Repo.Migrations.CreatePushSubscriptions do
  use Ecto.Migration

  def change do
    create table(:push_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :endpoint, :text, null: false
      add :keys, :map, null: false
      add :user_agent, :string

      timestamps()
    end

    create index(:push_subscriptions, [:user_id])
    create unique_index(:push_subscriptions, [:endpoint])
  end
end
