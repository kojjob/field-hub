defmodule FieldHubWeb.InvoiceLive.Show do
  @moduledoc """
  Invoice detail and preview LiveView.
  Displays a beautiful, printable invoice matching our design system.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Billing
  alias FieldHub.Jobs
  alias FieldHub.Repo

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    org = FieldHub.Accounts.get_organization!(user.organization_id)

    {:ok,
     socket
     |> assign(:current_organization, org)
     |> assign(:current_user, user)
     |> assign(:current_nav, :jobs)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    invoice = Billing.get_invoice!(socket.assigns.current_organization.id, id)
    job = invoice.job && Repo.preload(invoice.job, [:technician])

    {:noreply,
     socket
     |> assign(:page_title, "Invoice #{invoice.number}")
     |> assign(:invoice, invoice)
     |> assign(:job, job)}
  end

  @impl true
  def handle_event("send_invoice", _params, socket) do
    case Billing.send_invoice(socket.assigns.invoice) do
      {:ok, invoice} ->
        # Send email notification
        send_invoice_email(invoice)
        {:noreply,
         socket
         |> assign(:invoice, invoice)
         |> put_flash(:info, "Invoice sent to #{invoice.customer.email}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to send invoice")}
    end
  end

  def handle_event("mark_paid", _params, socket) do
    case Billing.mark_invoice_paid(socket.assigns.invoice) do
      {:ok, invoice} ->
        # Update job payment status
        if socket.assigns.job do
          Jobs.update_job(socket.assigns.job, %{payment_status: "paid"})
        end

        {:noreply,
         socket
         |> assign(:invoice, invoice)
         |> put_flash(:info, "Invoice marked as paid")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update invoice")}
    end
  end

  def handle_event("download_pdf", _params, socket) do
    # For now, trigger browser print dialog
    {:noreply, push_event(socket, "print_invoice", %{})}
  end

  defp send_invoice_email(invoice) do
    # Send email notification
    FieldHub.Billing.InvoiceNotifier.deliver_invoice(invoice)
    :ok
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950 py-8 print:bg-white print:py-0" id="invoice-page" phx-hook="PrintInvoice">
      <!-- Action Bar (hidden when printing) -->
      <div class="max-w-4xl mx-auto px-6 mb-6 print:hidden">
        <div class="flex items-center justify-between">
          <.link
            navigate={~p"/jobs/#{@job && @job.number || ""}"}
            class="inline-flex items-center gap-2 text-sm font-bold text-zinc-500 hover:text-primary transition-colors"
          >
            <.icon name="hero-arrow-left" class="size-4" />
            Back to Job
          </.link>

          <div class="flex items-center gap-3">
            <%= if @invoice.status == "draft" do %>
              <button
                phx-click="send_invoice"
                class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-white text-sm font-bold shadow-lg shadow-primary/20 hover:brightness-110 transition-all"
              >
                <.icon name="hero-paper-airplane" class="size-5" />
                Send Invoice
              </button>
            <% end %>

            <%= if @invoice.status in ["sent", "viewed", "overdue"] do %>
              <button
                phx-click="mark_paid"
                class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 text-white text-sm font-bold shadow-lg shadow-emerald-600/20 hover:brightness-110 transition-all"
              >
                <.icon name="hero-check-circle" class="size-5" />
                Mark as Paid
              </button>
            <% end %>

            <button
              phx-click="download_pdf"
              class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-700 dark:text-zinc-200 text-sm font-bold hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all"
            >
              <.icon name="hero-arrow-down-tray" class="size-5" />
              Download PDF
            </button>
          </div>
        </div>

        <!-- Status Badge -->
        <div class="mt-4 flex items-center gap-3">
          <span class={"inline-flex items-center px-3 py-1 rounded-full text-xs font-black uppercase tracking-widest #{status_badge_class(@invoice.status)}"}>
            {@invoice.status}
          </span>
          <%= if @invoice.status == "paid" && @invoice.paid_at do %>
            <span class="text-sm text-zinc-500">
              Paid on {Calendar.strftime(@invoice.paid_at, "%B %d, %Y")}
            </span>
          <% end %>
        </div>
      </div>

      <!-- Invoice Card -->
      <div class="max-w-4xl mx-auto px-6 print:px-0">
        <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-xl overflow-hidden print:rounded-none print:border-0 print:shadow-none">
          <!-- Invoice Header -->
          <div class="p-8 sm:p-12 border-b border-zinc-100 dark:border-zinc-800 bg-gradient-to-br from-primary/5 to-transparent print:bg-white">
            <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-8">
              <!-- Company Info -->
              <div>
                <div class="flex items-center gap-3 mb-4">
                  <div class="size-12 rounded-2xl bg-primary flex items-center justify-center text-white">
                    <.icon name="hero-building-office-2" class="size-6" />
                  </div>
                  <div>
                    <h1 class="text-2xl font-black text-zinc-900 dark:text-white tracking-tight">
                      {@current_organization.name}
                    </h1>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400">
                      {@current_organization.email || "billing@example.com"}
                    </p>
                  </div>
                </div>
                <div class="text-sm text-zinc-600 dark:text-zinc-400 space-y-1">
                  <%= if @current_organization.address_line1 do %>
                    <p>{@current_organization.address_line1}</p>
                  <% end %>
                  <p>
                    {@current_organization.city || "City"}, {@current_organization.state || "ST"} {@current_organization.zip || "00000"}
                  </p>
                  <%= if @current_organization.phone do %>
                    <p>{@current_organization.phone}</p>
                  <% end %>
                </div>
              </div>

              <!-- Invoice Info -->
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

          <!-- Bill To Section -->
          <div class="p-8 sm:p-12 border-b border-zinc-100 dark:border-zinc-800">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-8">
              <div>
                <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-3">
                  Bill To
                </h4>
                <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl p-5 border border-zinc-100 dark:border-zinc-800">
                  <p class="text-lg font-bold text-zinc-900 dark:text-white">
                    {@invoice.customer.name}
                  </p>
                  <%= if @invoice.customer.email do %>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                      {@invoice.customer.email}
                    </p>
                  <% end %>
                  <%= if @invoice.customer.phone do %>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400">
                      {@invoice.customer.phone}
                    </p>
                  <% end %>
                  <%= if @invoice.customer.address_line1 do %>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-2">
                      {@invoice.customer.address_line1}
                      <%= if @invoice.customer.address_line2 do %>
                        <br />{@invoice.customer.address_line2}
                      <% end %>
                      <br />
                      {@invoice.customer.city}, {@invoice.customer.state} {@invoice.customer.zip}
                    </p>
                  <% end %>
                </div>
              </div>

              <%= if @job do %>
                <div>
                  <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-3">
                    Service Details
                  </h4>
                  <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl p-5 border border-zinc-100 dark:border-zinc-800">
                    <p class="text-lg font-bold text-zinc-900 dark:text-white">
                      {@job.title}
                    </p>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                      Job #{@job.number}
                    </p>
                    <%= if @job.technician do %>
                      <p class="text-sm text-zinc-500 dark:text-zinc-400">
                        Technician: {@job.technician.name}
                      </p>
                    <% end %>
                    <%= if @job.completed_at do %>
                      <p class="text-sm text-zinc-500 dark:text-zinc-400">
                        Completed: {Calendar.strftime(@job.completed_at, "%B %d, %Y")}
                      </p>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Line Items / Financial Breakdown -->
          <div class="p-8 sm:p-12">
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
                  <!-- Labor Row -->
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

                  <!-- Parts & Materials Row -->
                  <%= if Decimal.gt?(@invoice.parts_amount, Decimal.new(0)) do %>
                    <tr>
                      <td class="px-6 py-5">
                        <div class="flex items-center gap-3">
                          <div class="size-8 rounded-xl bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
                            <.icon name="hero-wrench-screwdriver" class="size-4 text-amber-600" />
                          </div>
                          <span class="font-bold text-zinc-900 dark:text-white">Parts & Materials</span>
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

                  <!-- Dynamic Line Items -->
                  <%= for item <- @invoice.line_items || [] do %>
                    <tr>
                      <td class="px-6 py-5">
                        <div class="flex items-center gap-3">
                          <div class="size-8 rounded-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
                            <.icon name="hero-cube" class="size-4 text-zinc-500" />
                          </div>
                          <span class="font-bold text-zinc-900 dark:text-white">{item.description}</span>
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

            <!-- Totals -->
            <div class="mt-8 flex justify-end">
              <div class="w-full sm:w-80 space-y-3">
                <div class="flex justify-between text-sm">
                  <span class="text-zinc-500">Subtotal</span>
                  <span class="font-bold text-zinc-900 dark:text-white">${format_money(subtotal(@invoice))}</span>
                </div>

                <%= if Decimal.gt?(@invoice.discount_amount || Decimal.new(0), Decimal.new(0)) do %>
                  <div class="flex justify-between text-sm">
                    <span class="text-zinc-500">Discount</span>
                    <span class="font-bold text-emerald-600">-${format_money(@invoice.discount_amount)}</span>
                  </div>
                <% end %>

                <div class="flex justify-between text-sm">
                  <span class="text-zinc-500">Tax ({format_decimal(@invoice.tax_rate)}%)</span>
                  <span class="font-bold text-zinc-900 dark:text-white">${format_money(@invoice.tax_amount)}</span>
                </div>

                <div class="pt-4 border-t border-zinc-200 dark:border-zinc-700 flex justify-between">
                  <span class="text-lg font-bold text-zinc-900 dark:text-white">Total Due</span>
                  <span class="text-2xl font-black text-primary">${format_money(@invoice.total_amount)}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Notes & Terms -->
          <%= if @invoice.notes || @invoice.terms do %>
            <div class="p-8 sm:p-12 border-t border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-8">
                <%= if @invoice.notes do %>
                  <div>
                    <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-2">
                      Notes
                    </h4>
                    <p class="text-sm text-zinc-600 dark:text-zinc-300 whitespace-pre-line">
                      {@invoice.notes}
                    </p>
                  </div>
                <% end %>

                <%= if @invoice.payment_instructions do %>
                  <div>
                    <h4 class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-2">
                      Payment Instructions
                    </h4>
                    <p class="text-sm text-zinc-600 dark:text-zinc-300 whitespace-pre-line">
                      {@invoice.payment_instructions}
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <!-- Footer -->
          <div class="p-8 sm:p-12 border-t border-zinc-100 dark:border-zinc-800 text-center">
            <p class="text-sm text-zinc-500 dark:text-zinc-400">
              Thank you for your business!
            </p>
            <p class="text-xs text-zinc-400 mt-2">
              Questions? Contact us at {@current_organization.email || "support@example.com"}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions
  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%B %d, %Y")

  defp format_money(nil), do: "0.00"
  defp format_money(%Decimal{} = amount), do: Decimal.to_string(amount, :normal)
  defp format_money(amount) when is_number(amount), do: :erlang.float_to_binary(amount / 1, decimals: 2)
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
