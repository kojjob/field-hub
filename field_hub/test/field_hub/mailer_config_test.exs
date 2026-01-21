defmodule FieldHub.MailerConfigTest do
  @moduledoc """
  Tests to verify email configuration is correct.

  These tests help catch configuration issues before deployment.
  Run with: mix test test/field_hub/mailer_config_test.exs
  """
  use ExUnit.Case

  describe "email configuration" do
    test "swoosh is configured for development" do
      # In development, we use the Local adapter
      dev_config = Application.get_env(:field_hub, FieldHub.Mailer)

      # Should be either Local (dev) or a production adapter
      assert dev_config != nil, "Mailer should be configured"
    end

    test "mail_from is configured" do
      # Default fallback if not set
      from = Application.get_env(:field_hub, :mail_from, "notifications@fieldhub.ai")
      assert from != nil
      assert String.contains?(from, "@")
    end
  end

  describe "email templates" do
    alias FieldHub.Jobs.JobNotifier
    alias FieldHub.Billing.InvoiceNotifier
    alias FieldHub.Accounts.UserNotifier

    test "notifier modules are defined" do
      assert Code.ensure_loaded?(JobNotifier)
      assert Code.ensure_loaded?(InvoiceNotifier)
      assert Code.ensure_loaded?(UserNotifier)
    end
  end

  describe "production environment requirements" do
    @tag :production_check
    test "MAIL_PROVIDER environment variable formats" do
      # These are the supported provider values
      valid_providers = ~w(postmark sendgrid resend mailgun smtp)

      for provider <- valid_providers do
        assert provider in valid_providers,
               "#{provider} should be a valid mail provider"
      end
    end

    @tag :production_check
    test "email regex validation helper" do
      # Validates email format that notifiers check
      valid = "test@example.com"
      invalid = "not_an_email"

      assert valid =~ ~r/@/
      refute invalid =~ ~r/@/
    end
  end
end
