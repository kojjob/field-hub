defmodule FieldHub.Accounts.NotificationPreferences do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # Job Assignment
    field :job_assignment_email, :boolean, default: true
    field :job_assignment_sms, :boolean, default: true
    field :job_assignment_push, :boolean, default: true

    # Job Cancellation
    field :job_cancellation_email, :boolean, default: true
    field :job_cancellation_sms, :boolean, default: true
    field :job_cancellation_push, :boolean, default: true

    # Job Updates (Status change)
    field :job_update_email, :boolean, default: false
    field :job_update_sms, :boolean, default: false
    field :job_update_push, :boolean, default: true

    # Marketing
    field :marketing_email, :boolean, default: false
  end

  def changeset(preferences, attrs) do
    preferences
    |> cast(attrs, [
      :job_assignment_email, :job_assignment_sms, :job_assignment_push,
      :job_cancellation_email, :job_cancellation_sms, :job_cancellation_push,
      :job_update_email, :job_update_sms, :job_update_push,
      :marketing_email
    ])
  end
end
