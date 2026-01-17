defmodule FieldHub.Mailer do
  @moduledoc """
  Mailer module for sending emails via Swoosh.

  In development, emails are captured by the local mailbox viewer
  available at /dev/mailbox.

  In production, configure the adapter in runtime.exs to use
  your preferred email service (SendGrid, Postmark, etc.)
  """
  use Swoosh.Mailer, otp_app: :field_hub
end
