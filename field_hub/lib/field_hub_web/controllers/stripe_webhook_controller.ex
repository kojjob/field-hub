defmodule FieldHubWeb.StripeWebhookController do
  @moduledoc """
  Handles Stripe webhook events for payment processing.
  """
  use FieldHubWeb, :controller

  require Logger

  alias FieldHub.Payments

  @doc """
  Receives and processes Stripe webhook events.
  """
  def webhook(conn, _params) do
    payload = conn.assigns[:raw_body]
    signature = get_req_header(conn, "stripe-signature") |> List.first()

    signing_secret = Application.get_env(:stripity_stripe, :signing_secret)

    case verify_and_construct_event(payload, signature, signing_secret) do
      {:ok, %Stripe.Event{} = event} ->
        handle_event(event)
        send_resp(conn, 200, "OK")

      {:error, reason} ->
        Logger.warning("Stripe webhook verification failed: #{inspect(reason)}")
        send_resp(conn, 400, "Webhook verification failed")
    end
  end

  defp verify_and_construct_event(payload, signature, signing_secret) do
    if signing_secret do
      Stripe.Webhook.construct_event(payload, signature, signing_secret)
    else
      # In development without signing secret, just parse the event
      case Jason.decode(payload) do
        {:ok, params} ->
          event = %Stripe.Event{
            id: params["id"],
            type: params["type"],
            data: %{object: atomize_keys(params["data"]["object"] || %{})}
          }
          {:ok, event}
        error -> error
      end
    end
  end

  # Helper to atomize top-level keys for dev mode
  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
  defp atomize_keys(other), do: other

  defp handle_event(%Stripe.Event{type: "checkout.session.completed", data: %{object: session}}) do
    Logger.info("Checkout session completed: #{session.id}")

    case Payments.handle_checkout_completed(session) do
      {:ok, invoice} ->
        Logger.info("Invoice #{invoice.id} marked as paid via Stripe Checkout")

      {:error, reason} ->
        Logger.error("Failed to process checkout completion: #{inspect(reason)}")
    end
  end

  defp handle_event(%Stripe.Event{type: "payment_intent.succeeded", data: %{object: payment_intent}}) do
    Logger.info("Payment intent succeeded: #{payment_intent.id}")

    case Payments.handle_payment_succeeded(payment_intent) do
      {:ok, invoice} ->
        Logger.info("Invoice #{invoice.id} marked as paid via Payment Intent")

      {:error, reason} ->
        Logger.error("Failed to process payment success: #{inspect(reason)}")
    end
  end

  defp handle_event(%Stripe.Event{type: "payment_intent.payment_failed", data: %{object: payment_intent}}) do
    Logger.warning("Payment failed for intent: #{payment_intent.id}")
    # Could update invoice status or notify customer
  end

  defp handle_event(%Stripe.Event{type: type}) do
    Logger.debug("Unhandled Stripe event type: #{type}")
  end
end
