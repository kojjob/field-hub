defmodule FieldHub.Billing.InvoiceNotifier do
  @moduledoc """
  Handles invoice-related notifications to customers.
  """
  import Swoosh.Email

  use FieldHubWeb, :verified_routes

  alias FieldHub.Mailer
  alias FieldHub.CRM

  @doc """
  Deliver invoice notification to customer.
  """
  def deliver_invoice(invoice) do
    # Ensure all associations are loaded
    invoice = FieldHub.Repo.preload(invoice, [:customer, :organization])
    customer = invoice.customer || FieldHub.Repo.get!(FieldHub.CRM.Customer, invoice.customer_id)

    # Ensure customer has portal access
    customer = ensure_portal_token(customer)

    # Generate portal link
    url = url(FieldHubWeb.Endpoint, ~p"/portal/login/#{customer.portal_token}")

    deliver(customer.email, customer.name, "New Invoice ##{invoice.number} from #{invoice.organization.name}", """
    Hi #{customer.name},

    You have received a new invoice from #{invoice.organization.name}.

    Invoice Details:
    - Invoice #: #{invoice.number}
    - Amount Due: $#{format_money(invoice.total_amount)}
    - Due Date: #{format_date(invoice.due_date)}

    You can view and pay your invoice securely online by clicking the link below:
    #{url}

    If you have any questions, please contact us at #{invoice.organization.email || "support@fieldhub.ai"}.

    Thank you for your business!
    """)
  end

  defp deliver(recipient_email, recipient_name, subject, body) do
    if recipient_email && recipient_email =~ "@" do
      from_address = Application.get_env(:field_hub, :mail_from, "billing@fieldhub.ai")

      email =
        new()
        |> to({recipient_name || "", recipient_email})
        |> from({"FieldHub Billing", from_address})
        |> subject(subject)
        |> text_body(body)

      with {:ok, _metadata} <- Mailer.deliver(email) do
        {:ok, email}
      end
    else
      {:error, :no_recipient}
    end
  end

  defp ensure_portal_token(customer) do
    case CRM.ensure_portal_access(customer) do
      {:ok, updated_customer} -> updated_customer
      _ -> customer
    end
  end

  defp format_money(amount) do
    Decimal.to_string(amount, :normal)
  end

  defp format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end
end
