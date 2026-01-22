defmodule FieldHubWeb.PortalLive.InvoicePayment do
  @moduledoc """
  Customer portal invoice payment page.
  Creates a Stripe Checkout Session and redirects to Stripe.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Billing.Invoice
  alias FieldHub.Payments
  import Ecto.Query

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    customer = socket.assigns.portal_customer

    case get_invoice_for_customer(id, customer.id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Invoice not found")
         |> push_navigate(to: ~p"/portal/invoices")}

      %{status: "paid"} = invoice ->
        {:ok,
         socket
         |> put_flash(:info, "This invoice has already been paid")
         |> push_navigate(to: ~p"/portal/invoices/#{invoice.id}")}

      invoice ->
        {:ok,
         socket
         |> assign(:customer, customer)
         |> assign(:invoice, invoice)
         |> assign(:loading, false)
         |> assign(:error, nil)
         |> assign(:stripe_configured, Payments.stripe_configured?())
         |> assign(:page_title, "Pay Invoice #{invoice.number}")}
    end
  end

  defp get_invoice_for_customer(invoice_id, customer_id) do
    Invoice
    |> where([i], i.id == ^invoice_id)
    |> where([i], i.customer_id == ^customer_id)
    |> FieldHub.Repo.one()
    |> case do
      nil -> nil
      invoice -> FieldHub.Repo.preload(invoice, [:job, :organization])
    end
  end

  @impl true
  def handle_event("start_payment", _params, socket) do
    invoice = socket.assigns.invoice

    success_url = url(FieldHubWeb.Endpoint, ~p"/portal/invoices/#{invoice.id}?payment=success")
    cancel_url = url(FieldHubWeb.Endpoint, ~p"/portal/invoices/#{invoice.id}?payment=cancelled")

    socket = assign(socket, :loading, true)

    case Payments.create_checkout_session(invoice, success_url, cancel_url) do
      {:ok, session} ->
        {:noreply, redirect(socket, external: session.url)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error, reason)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950">
      <main class="max-w-2xl mx-auto px-4 sm:px-6 py-12">
        <div class="mb-8 text-center">
          <.link
            navigate={~p"/portal/invoices/#{@invoice.id}"}
            class="inline-flex items-center gap-2 text-sm font-bold text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white transition-colors mb-6"
          >
            <.icon name="hero-arrow-left" class="size-4" /> Back to Invoice
          </.link>

          <h1 class="text-3xl font-black text-zinc-900 dark:text-white tracking-tight mb-2">
            Secure Payment
          </h1>
          <p class="text-zinc-500 dark:text-zinc-400">
            Invoice {@invoice.number}
          </p>
        </div>
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
          <%!-- Amount Summary --%>
          <div class="p-8 text-center border-b border-zinc-100 dark:border-zinc-800 bg-gradient-to-br from-primary/5 to-transparent">
            <p class="text-sm text-zinc-500 mb-2">Amount Due</p>
            <p class="text-5xl font-black text-zinc-900 dark:text-white tracking-tight">
              {currency_symbol(@invoice.organization.currency)}{format_money(@invoice.total_amount)}
            </p>
            <p class="text-sm text-zinc-500 mt-2">
              Due by {format_date(@invoice.due_date)}
            </p>
          </div>

          <%!-- Invoice Details --%>
          <div class="p-6 border-b border-zinc-100 dark:border-zinc-800">
            <div class="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p class="text-zinc-500 mb-1">Invoice</p>
                <p class="font-bold text-zinc-900 dark:text-white">{@invoice.number}</p>
              </div>
              <div>
                <p class="text-zinc-500 mb-1">From</p>
                <p class="font-bold text-zinc-900 dark:text-white">{@invoice.organization.name}</p>
              </div>
              <%= if @invoice.job do %>
                <div class="col-span-2">
                  <p class="text-zinc-500 mb-1">Service</p>
                  <p class="font-bold text-zinc-900 dark:text-white">{@invoice.job.title}</p>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Payment Section --%>
          <div class="p-8">
            <%= if @error do %>
              <div class="mb-6 p-4 rounded-xl bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
                <div class="flex items-center gap-3">
                  <.icon name="hero-exclamation-circle" class="size-5 text-red-600" />
                  <p class="text-sm text-red-700 dark:text-red-400">{@error}</p>
                </div>
              </div>
            <% end %>

            <%= if @stripe_configured do %>
              <button
                phx-click="start_payment"
                disabled={@loading}
                class={[
                  "w-full py-4 px-6 rounded-2xl text-lg font-black transition-all",
                  "bg-primary text-white hover:bg-primary/90",
                  "disabled:opacity-50 disabled:cursor-not-allowed",
                  "flex items-center justify-center gap-3"
                ]}
              >
                <%= if @loading do %>
                  <svg
                    class="animate-spin size-5"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    >
                    </path>
                  </svg>
                  Processing...
                <% else %>
                  <.icon name="hero-credit-card" class="size-6" />
                  Pay {currency_symbol(@invoice.organization.currency)}{format_money(
                    @invoice.total_amount
                  )} Now
                <% end %>
              </button>

              <div class="mt-6 flex items-center justify-center gap-3 text-zinc-400">
                <svg
                  width="49"
                  height="20"
                  fill="currentColor"
                  viewBox="0 0 49 20"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    fill-rule="evenodd"
                    clip-rule="evenodd"
                    d="M48.4 10.1c0-3.3-1.6-5.9-4.6-5.9s-4.8 2.6-4.8 5.9c0 3.9 2.1 5.8 5.2 5.8 1.5 0 2.6-.3 3.5-.8v-2.6c-.8.4-1.7.7-2.9.7-1.2 0-2.2-.4-2.3-1.8h5.9v-.9c0-.2.01-.4.01-.4zm-6-1.2c0-1.4.8-1.9 1.6-1.9.8 0 1.5.6 1.5 1.9h-3.1zm-6.7-4.7c-1.2 0-1.9.5-2.4 1l-.2-.9h-2.6V20l3-.6v-3.7c.4.3 1.1.8 2.2.8 2.2 0 4.2-1.8 4.2-5.7 0-3.6-2-5.6-4.2-5.6zm-.7 8.6c-.7 0-1.2-.3-1.5-.6v-4.8c.3-.4.8-.7 1.5-.7 1.2 0 2 1.3 2 3s-.8 3.1-2 3.1zm-8.5-9.4l3-.6V0l-3 .6v2.8zm0 1.1h3v10.6h-3V4.5zm-3.2 0l-.2-1h-2.6v10.6h3V7.5c.7-.9 1.9-.8 2.3-.6V4.5c-.4-.2-1.9-.4-2.5.8v-.8zm-6.2-2.9l-2.9.6-.01 9.7c0 1.8 1.3 3.1 3.2 3.1 1 0 1.7-.2 2.2-.4v-2.4c-.4.1-2.4.6-2.4-1V7.2h2.4V4.5h-2.4l-.01-2.9zm-7.8 5.7c0-.5.4-.7 1.1-.7.9 0 2.1.3 3 .8V4.7c-1-.4-2-.5-3-.5-2.4 0-4.1 1.3-4.1 3.4 0 3.4 4.7 2.8 4.7 4.3 0 .6-.5.8-1.2.8-1.1 0-2.5-.4-3.5-1v2.7c1.2.5 2.4.8 3.5.8 2.5 0 4.2-1.2 4.2-3.4.01-3.6-4.7-3-4.7-4.4z"
                  />
                </svg>
                <span class="text-xs">Secure payment</span>
              </div>
            <% else %>
              <div class="text-center p-6 bg-amber-50 dark:bg-amber-900/20 rounded-xl border border-amber-200 dark:border-amber-800">
                <.icon name="hero-exclamation-triangle" class="size-10 text-amber-500 mx-auto mb-3" />
                <p class="text-sm text-amber-700 dark:text-amber-400 font-medium">
                  Online payments are not currently available.
                </p>
                <p class="text-xs text-amber-600 dark:text-amber-500 mt-2">
                  Please contact {@invoice.organization.name} for payment options.
                </p>
              </div>
            <% end %>

            <%= if @invoice.payment_instructions do %>
              <div class="mt-8 p-4 bg-zinc-50 dark:bg-zinc-800/50 rounded-xl">
                <h4 class="text-xs font-bold text-zinc-500 uppercase tracking-wider mb-2">
                  Alternative Payment Methods
                </h4>
                <p class="text-sm text-zinc-600 dark:text-zinc-300 whitespace-pre-line">
                  {@invoice.payment_instructions}
                </p>
              </div>
            <% end %>
          </div>
        </div>
      </main>
    </div>
    """
  end

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%B %d, %Y")

  defp format_money(nil), do: "0.00"
  defp format_money(%Decimal{} = amount), do: Decimal.to_string(amount, :normal)

  defp format_money(amount) when is_number(amount),
    do: :erlang.float_to_binary(amount / 1, decimals: 2)

  defp format_money(_), do: "0.00"

  # Currency symbol mapping based on ISO 4217 currency codes
  defp currency_symbol("USD"), do: "$"
  defp currency_symbol("EUR"), do: "€"
  defp currency_symbol("GBP"), do: "£"
  defp currency_symbol("NGN"), do: "₦"
  defp currency_symbol("GHS"), do: "₵"
  defp currency_symbol("KES"), do: "KSh"
  defp currency_symbol("ZAR"), do: "R"
  defp currency_symbol("INR"), do: "₹"
  defp currency_symbol("CAD"), do: "C$"
  defp currency_symbol("AUD"), do: "A$"
  defp currency_symbol(_), do: "$"
end
