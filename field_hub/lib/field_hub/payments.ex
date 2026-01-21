defmodule FieldHub.Payments do
  @moduledoc """
  Handles Stripe payment processing for invoices.
  """

  alias FieldHub.Billing
  alias FieldHub.Billing.Invoice
  alias FieldHub.Repo

  @doc """
  Creates a Stripe Checkout Session for paying an invoice.
  Returns {:ok, checkout_session} or {:error, reason}.
  """
  def create_checkout_session(%Invoice{} = invoice, success_url, cancel_url) do
    invoice = Repo.preload(invoice, [:customer, :organization])

    line_items = build_line_items(invoice)

    params = %{
      mode: "payment",
      success_url: success_url,
      cancel_url: cancel_url,
      customer_email: invoice.customer.email,
      client_reference_id: "invoice_#{invoice.id}",
      line_items: line_items,
      metadata: %{
        invoice_id: invoice.id,
        invoice_number: invoice.number,
        organization_id: invoice.organization_id,
        customer_id: invoice.customer_id
      },
      payment_intent_data: %{
        metadata: %{
          invoice_id: invoice.id,
          invoice_number: invoice.number
        }
      }
    }

    case Stripe.Checkout.Session.create(params) do
      {:ok, session} ->
        # Store the checkout session ID on the invoice for tracking
        {:ok, session}

      {:error, %Stripe.Error{} = error} ->
        {:error, error.message}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  @doc """
  Handles successful payment from Stripe webhook.
  Updates invoice status to paid.
  """
  def handle_payment_succeeded(payment_intent) do
    invoice_id = get_in(payment_intent, [:metadata, "invoice_id"])

    if invoice_id do
      case Repo.get(Invoice, invoice_id) do
        nil ->
          {:error, :invoice_not_found}

        invoice ->
          Billing.update_invoice(invoice, %{
            status: "paid",
            paid_at: DateTime.utc_now(),
            stripe_payment_intent_id: payment_intent.id
          })
      end
    else
      {:error, :no_invoice_id}
    end
  end

  @doc """
  Handles checkout session completion from Stripe webhook.
  """
  def handle_checkout_completed(session) do
    invoice_id =
      case session.metadata do
        %{"invoice_id" => id} -> id
        _ -> nil
      end

    if invoice_id do
      case Repo.get(Invoice, invoice_id) do
        nil ->
          {:error, :invoice_not_found}

        invoice ->
          # Mark invoice as paid
          Billing.update_invoice(invoice, %{
            status: "paid",
            paid_at: DateTime.utc_now(),
            stripe_checkout_session_id: session.id
          })
      end
    else
      {:error, :no_invoice_id}
    end
  end

  # Build Stripe line items from invoice
  defp build_line_items(invoice) do
    items = []

    # Add labor
    items =
      if invoice.labor_amount && Decimal.gt?(invoice.labor_amount, Decimal.new(0)) do
        item = %{
          price_data: %{
            currency: "usd",
            unit_amount: decimal_to_cents(invoice.labor_amount),
            product_data: %{
              name: "Labor",
              description:
                "#{format_decimal(invoice.labor_hours)} hours at $#{format_decimal(invoice.labor_rate)}/hr"
            }
          },
          quantity: 1
        }

        items ++ [item]
      else
        items
      end

    # Add parts
    items =
      if invoice.parts_amount && Decimal.gt?(invoice.parts_amount, Decimal.new(0)) do
        item = %{
          price_data: %{
            currency: "usd",
            unit_amount: decimal_to_cents(invoice.parts_amount),
            product_data: %{
              name: "Parts & Materials"
            }
          },
          quantity: 1
        }

        items ++ [item]
      else
        items
      end

    # Add materials
    items =
      if invoice.materials_amount && Decimal.gt?(invoice.materials_amount, Decimal.new(0)) do
        item = %{
          price_data: %{
            currency: "usd",
            unit_amount: decimal_to_cents(invoice.materials_amount),
            product_data: %{
              name: "Additional Materials"
            }
          },
          quantity: 1
        }

        items ++ [item]
      else
        items
      end

    # Add tax as a line item
    items =
      if invoice.tax_amount && Decimal.gt?(invoice.tax_amount, Decimal.new(0)) do
        item = %{
          price_data: %{
            currency: "usd",
            unit_amount: decimal_to_cents(invoice.tax_amount),
            product_data: %{
              name: "Tax (#{format_decimal(invoice.tax_rate)}%)"
            }
          },
          quantity: 1
        }

        items ++ [item]
      else
        items
      end

    # Subtract discount if any
    items =
      if invoice.discount_amount && Decimal.gt?(invoice.discount_amount, Decimal.new(0)) do
        item = %{
          price_data: %{
            currency: "usd",
            unit_amount: -decimal_to_cents(invoice.discount_amount),
            product_data: %{
              name: "Discount"
            }
          },
          quantity: 1
        }

        items ++ [item]
      else
        items
      end

    # If no line items, create a single total line item
    if items == [] do
      [
        %{
          price_data: %{
            currency: "usd",
            unit_amount: decimal_to_cents(invoice.total_amount),
            product_data: %{
              name: "Invoice #{invoice.number}"
            }
          },
          quantity: 1
        }
      ]
    else
      items
    end
  end

  defp decimal_to_cents(nil), do: 0

  defp decimal_to_cents(%Decimal{} = amount) do
    amount
    |> Decimal.mult(100)
    |> Decimal.round(0)
    |> Decimal.to_integer()
  end

  defp format_decimal(nil), do: "0"
  defp format_decimal(%Decimal{} = d), do: Decimal.to_string(d, :normal)
  defp format_decimal(n), do: to_string(n)

  @doc """
  Check if Stripe is configured.
  """
  def stripe_configured? do
    Application.get_env(:stripity_stripe, :api_key) != nil
  end

  @doc """
  Get the Stripe publishable key.
  """
  def publishable_key do
    Application.get_env(:field_hub, :stripe)[:publishable_key]
  end
end
