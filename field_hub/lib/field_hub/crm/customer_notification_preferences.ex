defmodule FieldHub.CRM.CustomerNotificationPreferences do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # Job Status Updates
    field :job_scheduled_email, :boolean, default: true
    field :job_scheduled_sms, :boolean, default: true

    field :technician_en_route_email, :boolean, default: false
    field :technician_en_route_sms, :boolean, default: true

    field :technician_arrived_email, :boolean, default: false
    field :technician_arrived_sms, :boolean, default: true

    field :job_completed_email, :boolean, default: true
    field :job_completed_sms, :boolean, default: true

    # Billing
    field :invoice_email, :boolean, default: true

    # General
    field :marketing_email, :boolean, default: false
  end

  def changeset(preferences, attrs) do
    preferences
    |> cast(attrs, [
      :job_scheduled_email,
      :job_scheduled_sms,
      :technician_en_route_email,
      :technician_en_route_sms,
      :technician_arrived_email,
      :technician_arrived_sms,
      :job_completed_email,
      :job_completed_sms,
      :invoice_email,
      :marketing_email
    ])
  end
end
