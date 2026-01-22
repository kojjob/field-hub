defmodule FieldHubWeb.PortalLive.InvoiceDetail do
  @moduledoc """
  Customer portal invoice detail view.
  Shows full invoice details with print-friendly layout.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Billing
  alias FieldHub.Billing.Invoice
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

      invoice ->
        # Mark as viewed if currently sent
        invoice = maybe_mark_viewed(invoice)

        {:ok,
         socket
         |> assign(:customer, customer)
         |> assign(:invoice, invoice)
         |> assign(:page_title, "Invoice #{invoice.number}")}
    end
  end

  defp get_invoice_for_customer(invoice_id, customer_id) do
    Invoice
    |> where([i], i.id == ^invoice_id)
    |> where([i], i.customer_id == ^customer_id)
    |> FieldHub.Repo.one()
    |> case do
      nil -> nil
      invoice -> FieldHub.Repo.preload(invoice, [:job, :organization, :line_items])
    end
  end

  defp maybe_mark_viewed(%Invoice{status: "sent"} = invoice) do
    case Billing.update_invoice(invoice, %{status: "viewed"}) do
      {:ok, updated} -> FieldHub.Repo.preload(updated, [:job, :organization, :line_items])
      _ -> invoice
    end
  end

  defp maybe_mark_viewed(invoice), do: invoice

  @impl true
  def handle_event("print", _params, socket) do
    {:noreply, push_event(socket, "print_invoice", %{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="min-h-screen bg-zinc-50 dark:bg-zinc-950 print:bg-white"
      id="portal-invoice"
      phx-hook="PrintInvoice"
    >
      <main class="max-w-4xl mx-auto px-4 sm:px-6 py-12 print:px-0 print:py-0">
        <%!-- Header Section (hidden on print) --%>
        <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-6 mb-8 print:hidden">
          <div>
            <.link
              navigate={~p"/portal/invoices"}
              class="inline-flex items-center gap-2 text-sm font-bold text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white transition-colors mb-4"
            >
              <.icon name="hero-arrow-left" class="size-4" /> Back to Invoices
            </.link>
            <div class="flex items-center gap-3 mb-1">
              <span class={"inline-flex items-center px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-widest #{status_badge_class(@invoice.status)}"}>
                {@invoice.status}
              </span>
            </div>
            <h1 class="text-3xl font-black text-zinc-900 dark:text-white tracking-tight">
              Invoice {@invoice.number}
            </h1>
          </div>

          <div class="flex items-center gap-3 mt-2 sm:mt-0">
            <%= if @invoice.status not in ["paid", "cancelled", "draft"] do %>
              <.link
                navigate={~p"/portal/invoices/#{@invoice.id}/pay"}
                class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-primary text-white text-sm font-bold hover:bg-primary/90 transition-all shadow-lg shadow-primary/20"
              >
                <.icon name="hero-credit-card" class="size-5" /> Pay Now
              </.link>
            <% end %>
            <button
              phx-click="print"
              class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white dark:bg-zinc-800 text-zinc-700 dark:text-zinc-200 text-sm font-bold border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all shadow-sm"
            >
              <.icon name="hero-printer" class="size-5" /> Print
            </button>
          </div>
        </div>
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden print:rounded-none print:border-0">
          <%!-- Invoice Header --%>
          <div class="p-8 border-b border-zinc-100 dark:border-zinc-800 bg-gradient-to-br from-primary/5 to-transparent print:bg-white">
            <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-8">
              <%!-- Company Info --%>
              <div>
                <div class="flex items-center gap-3 mb-4">
                  <div class="size-12 rounded-2xl bg-primary flex items-center justify-center text-white print:hidden">
                    <.icon name="hero-building-office-2" class="size-6" />
                  </div>
                  <div>
                    <h1 class="text-2xl font-black text-zinc-900 dark:text-white tracking-tight">
                      {@invoice.organization.name}
                    </h1>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400">
                      {@invoice.organization.email || "billing@example.com"}
                    </p>
                  </div>
                </div>
                <div class="text-sm text-zinc-600 dark:text-zinc-400 space-y-1">
                  <%= if @invoice.organization.address_line1 do %>
                    <p>{@invoice.organization.address_line1}</p>
                  <% end %>
                  <p>
                    {@invoice.organization.city || "City"}, {@invoice.organization.state || "ST"} {@invoice.organization.zip ||
                      "00000"}
                  </p>
                  <%= if @invoice.organization.phone do %>
                    <p>{@invoice.organization.phone}</p>
                  <% end %>
                </div>
              </div>

              <%!-- Invoice Info --%>
              <div class="text-right">
                <h2 class="text-3xl font-black text-primary tracking-tight mb-2">INVOICE</h2>
                <p class="text-xl font-bold text-zinc-900 dark:text-white">{@invoice.number}</p>
                <div class="mt-4 space-y-1 text-sm">
                  <div class="flex justify-end gap-4">
                    <span class="text-zinc-500">Issue Date:</span>
                    <span class="font-bold text-zinc-900 dark:text-white">
                      {format_date(@invoice.issue_date)}
                    </span>
                  </div>
                  <div class="flex justify-end gap-4">
                    <span class="text-zinc-500">Due Date:</span>
                    <span class="font-bold text-zinc-900 dark:text-white">
                      {format_date(@invoice.due_date)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Bill To Section --%>
          <div class="p-8 border-b border-zinc-100 dark:border-zinc-800">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-8">
              <div>
                <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-3">
                  Bill To
                </h4>
                <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl p-5 border border-zinc-100 dark:border-zinc-800">
                  <p class="text-lg font-bold text-zinc-900 dark:text-white">
                    {@customer.name}
                  </p>
                  <%= if @customer.email do %>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                      {@customer.email}
                    </p>
                  <% end %>
                  <%= if @customer.phone do %>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400">
                      {@customer.phone}
                    </p>
                  <% end %>
                </div>
              </div>

              <%= if @invoice.job do %>
                <div>
                  <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-3">
                    Service Details
                  </h4>
                  <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl p-5 border border-zinc-100 dark:border-zinc-800">
                    <p class="text-lg font-bold text-zinc-900 dark:text-white">
                      {@invoice.job.title}
                    </p>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                      Job #{@invoice.job.number}
                    </p>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Charges Section --%>
          <div class="p-8">
            <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-4">
              Charges
            </h4>

            <div class="rounded-2xl border border-zinc-200 dark:border-zinc-700 overflow-hidden">
              <table class="w-full">
                <thead class="bg-zinc-50 dark:bg-zinc-800/50">
                  <tr>
                    <th class="text-left px-6 py-4 text-xs font-black text-zinc-500 uppercase tracking-wider">
                      Description
                    </th>
                    <th class="text-right px-6 py-4 text-xs font-black text-zinc-500 uppercase tracking-wider">
                      Qty/Hours
                    </th>
                    <th class="text-right px-6 py-4 text-xs font-black text-zinc-500 uppercase tracking-wider">
                      Rate
                    </th>
                    <th class="text-right px-6 py-4 text-xs font-black text-zinc-500 uppercase tracking-wider">
                      Amount
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
                  <%!-- Labor Row --%>
                  <%= if Decimal.gt?(@invoice.labor_amount, Decimal.new(0)) do %>
                    <tr>
                      <td class="px-6 py-5">
                        <div class="flex items-center gap-3">
                          <div class="size-8 rounded-xl bg-primary/10 flex items-center justify-center">
                            <.icon name="hero-clock" class="size-4 text-primary" />
                          </div>
                          <span class="font-bold text-zinc-900 dark:text-white">Labor</span>
                        </div>
                      </td>
                      <td class="px-6 py-5 text-right text-zinc-600 dark:text-zinc-300 font-medium">
                        {format_decimal(@invoice.labor_hours)} hrs
                      </td>
                      <td class="px-6 py-5 text-right text-zinc-600 dark:text-zinc-300 font-medium">
                        ${format_decimal(@invoice.labor_rate)}/hr
                      </td>
                      <td class="px-6 py-5 text-right font-bold text-zinc-900 dark:text-white">
                        ${format_money(@invoice.labor_amount)}
                      </td>
                    </tr>
                  <% end %>

                  <%!-- Parts Row --%>
                  <%= if Decimal.gt?(@invoice.parts_amount, Decimal.new(0)) do %>
                    <tr>
                      <td class="px-6 py-5">
                        <div class="flex items-center gap-3">
                          <div class="size-8 rounded-xl bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
                            <.icon name="hero-wrench-screwdriver" class="size-4 text-amber-600" />
                          </div>
                          <span class="font-bold text-zinc-900 dark:text-white">
                            Parts & Materials
                          </span>
                        </div>
                      </td>
                      <td class="px-6 py-5 text-right text-zinc-600 dark:text-zinc-300 font-medium">
                        —
                      </td>
                      <td class="px-6 py-5 text-right text-zinc-600 dark:text-zinc-300 font-medium">
                        —
                      </td>
                      <td class="px-6 py-5 text-right font-bold text-zinc-900 dark:text-white">
                        ${format_money(@invoice.parts_amount)}
                      </td>
                    </tr>
                  <% end %>

                  <%!-- Line Items --%>
                  <%= for item <- @invoice.line_items || [] do %>
                    <tr>
                      <td class="px-6 py-5">
                        <div class="flex items-center gap-3">
                          <div class="size-8 rounded-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
                            <.icon name="hero-cube" class="size-4 text-zinc-500" />
                          </div>
                          <span class="font-bold text-zinc-900 dark:text-white">
                            {item.description}
                          </span>
                        </div>
                      </td>
                      <td class="px-6 py-5 text-right text-zinc-600 dark:text-zinc-300 font-medium">
                        {format_decimal(item.quantity)}
                      </td>
                      <td class="px-6 py-5 text-right text-zinc-600 dark:text-zinc-300 font-medium">
                        ${format_money(item.unit_price)}
                      </td>
                      <td class="px-6 py-5 text-right font-bold text-zinc-900 dark:text-white">
                        ${format_money(item.amount)}
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <%!-- Totals --%>
            <div class="mt-8 flex justify-end">
              <div class="w-full sm:w-80 space-y-3">
                <div class="flex justify-between text-sm">
                  <span class="text-zinc-500">Subtotal</span>
                  <span class="font-bold text-zinc-900 dark:text-white">
                    ${format_money(subtotal(@invoice))}
                  </span>
                </div>

                <%= if Decimal.gt?(@invoice.discount_amount || Decimal.new(0), Decimal.new(0)) do %>
                  <div class="flex justify-between text-sm">
                    <span class="text-zinc-500">Discount</span>
                    <span class="font-bold text-emerald-600">
                      -${format_money(@invoice.discount_amount)}
                    </span>
                  </div>
                <% end %>

                <div class="flex justify-between text-sm">
                  <span class="text-zinc-500">Tax ({format_decimal(@invoice.tax_rate)}%)</span>
                  <span class="font-bold text-zinc-900 dark:text-white">
                    ${format_money(@invoice.tax_amount)}
                  </span>
                </div>

                <div class="pt-4 border-t border-zinc-200 dark:border-zinc-700 flex justify-between">
                  <span class="text-lg font-bold text-zinc-900 dark:text-white">Total Due</span>
                  <span class="text-2xl font-black text-primary">
                    ${format_money(@invoice.total_amount)}
                  </span>
                </div>
              </div>
            </div>

            <%!-- Pay Now CTA (for unpaid invoices) --%>
            <%= if @invoice.status not in ["paid", "cancelled", "draft"] do %>
              <div class="mt-8 p-6 bg-gradient-to-r from-primary/10 to-primary/5 rounded-2xl border border-primary/20 print:hidden">
                <div class="flex flex-col sm:flex-row items-center justify-between gap-4">
                  <div>
                    <p class="text-lg font-bold text-zinc-900 dark:text-white">Ready to pay?</p>
                    <p class="text-sm text-zinc-500">Secure online payment via credit card</p>
                  </div>
                  <.link
                    navigate={~p"/portal/invoices/#{@invoice.id}/pay"}
                    class="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-primary text-white font-bold hover:bg-primary/90 transition-all shadow-lg shadow-primary/25"
                  >
                    <.icon name="hero-credit-card" class="size-5" />
                    Pay ${format_money(@invoice.total_amount)} Now
                  </.link>
                </div>
              </div>
            <% end %>
          </div>

          <%!-- Payment Status Banner --%>
          <%= if @invoice.status == "paid" do %>
            <div class="p-6 bg-emerald-50 dark:bg-emerald-900/20 border-t border-emerald-100 dark:border-emerald-900/30">
              <div class="flex items-center justify-center gap-3">
                <div class="size-10 rounded-full bg-emerald-100 dark:bg-emerald-900/50 flex items-center justify-center">
                  <.icon name="hero-check-circle" class="size-6 text-emerald-600" />
                </div>
                <div class="text-center">
                  <p class="text-lg font-bold text-emerald-700 dark:text-emerald-400">Paid in Full</p>
                  <%= if @invoice.paid_at do %>
                    <p class="text-sm text-emerald-600 dark:text-emerald-500">
                      Payment received on {Calendar.strftime(@invoice.paid_at, "%B %d, %Y")}
                    </p>
                  <% end %>
                </div>
              </div>
            </div>
          <% else %>
            <%!-- Payment Instructions --%>
            <%= if @invoice.payment_instructions do %>
              <div class="p-8 border-t border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20">
                <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-2">
                  Payment Instructions
                </h4>
                <p class="text-sm text-zinc-600 dark:text-zinc-300 whitespace-pre-line">
                  {@invoice.payment_instructions}
                </p>
              </div>
            <% end %>
          <% end %>

          <%!-- Notes --%>
          <%= if @invoice.notes do %>
            <div class="p-8 border-t border-zinc-100 dark:border-zinc-800">
              <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-2">
                Notes
              </h4>
              <p class="text-sm text-zinc-600 dark:text-zinc-300 whitespace-pre-line">
                {@invoice.notes}
              </p>
            </div>
          <% end %>

          <%!-- Footer --%>
          <div class="p-8 border-t border-zinc-100 dark:border-zinc-800 text-center">
            <p class="text-sm text-zinc-500 dark:text-zinc-400">
              Thank you for your business!
            </p>
            <p class="text-xs text-zinc-400 mt-2">
              Questions? Contact us at {@invoice.organization.email || "support@example.com"}
            </p>
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

  defp format_decimal(nil), do: "—"
  defp format_decimal(%Decimal{} = d), do: Decimal.to_string(d, :normal)
  defp format_decimal(n), do: to_string(n)

  defp subtotal(invoice) do
    labor = invoice.labor_amount || Decimal.new(0)
    parts = invoice.parts_amount || Decimal.new(0)
    materials = invoice.materials_amount || Decimal.new(0)
    Decimal.add(labor, parts) |> Decimal.add(materials)
  end

  defp status_badge_class("draft"), do: "bg-zinc-100 text-zinc-600 border border-zinc-200"
  defp status_badge_class("sent"), do: "bg-blue-50 text-blue-700 border border-blue-200"
  defp status_badge_class("viewed"), do: "bg-purple-50 text-purple-700 border border-purple-200"
  defp status_badge_class("paid"), do: "bg-emerald-50 text-emerald-700 border border-emerald-200"
  defp status_badge_class("overdue"), do: "bg-red-50 text-red-700 border border-red-200"
  defp status_badge_class("cancelled"), do: "bg-zinc-100 text-zinc-500 border border-zinc-200"
  defp status_badge_class(_), do: "bg-zinc-100 text-zinc-600 border border-zinc-200"
end
