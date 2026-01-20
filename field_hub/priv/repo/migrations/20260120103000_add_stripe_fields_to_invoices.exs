defmodule FieldHub.Repo.Migrations.AddStripeFieldsToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add :stripe_checkout_session_id, :string
      add :stripe_payment_intent_id, :string
    end

    create index(:invoices, [:stripe_checkout_session_id])
    create index(:invoices, [:stripe_payment_intent_id])
  end
end
