defmodule FieldHub.Repo.Migrations.AddSmsNotificationsEnabledToCustomers do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :sms_notifications_enabled, :boolean, default: true
    end
  end
end
