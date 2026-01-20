defmodule FieldHubWeb.InvoiceLive.Index do
  @moduledoc """
  Invoice listing LiveView.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Billing

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    org = FieldHub.Accounts.get_organization!(user.organization_id)

    socket =
      socket
      |> assign(:current_organization, org)
      |> assign(:current_user, user)
      |> assign(:current_nav, :jobs)
      |> assign(:page_title, "Invoices")
      |> assign(:filter, "all")
      |> load_invoices()
      |> load_stats()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp load_invoices(socket) do
    invoices = Billing.list_invoices(socket.assigns.current_organization.id)
    assign(socket, :invoices, invoices)
  end

  defp load_stats(socket) do
    stats = Billing.get_invoice_stats(socket.assigns.current_organization.id)
    assign(socket, :stats, stats)
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    opts = if status == "all", do: [], else: [status: status]
    invoices = Billing.list_invoices(socket.assigns.current_organization.id, opts)

    {:noreply,
     socket
     |> assign(:filter, status)
     |> assign(:invoices, invoices)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 p-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            Billing
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Invoices
          </h2>
        </div>
      </div>
      
    <!-- Stats Cards -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <div class="bg-white dark:bg-zinc-900 rounded-[24px] p-6 border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <div class="flex items-center gap-3 mb-3">
            <div class="size-10 rounded-2xl bg-primary/10 flex items-center justify-center">
              <.icon name="hero-document-text" class="size-5 text-primary" />
            </div>
            <span class="text-xs font-bold text-zinc-500 uppercase tracking-widest">
              Total Invoiced
            </span>
          </div>
          <p class="text-2xl font-black text-zinc-900 dark:text-white">
            ${format_money(@stats.total_invoiced)}
          </p>
        </div>

        <div class="bg-white dark:bg-zinc-900 rounded-[24px] p-6 border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <div class="flex items-center gap-3 mb-3">
            <div class="size-10 rounded-2xl bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <.icon name="hero-check-circle" class="size-5 text-emerald-600" />
            </div>
            <span class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Paid</span>
          </div>
          <p class="text-2xl font-black text-emerald-600">
            ${format_money(@stats.total_paid)}
          </p>
        </div>

        <div class="bg-white dark:bg-zinc-900 rounded-[24px] p-6 border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <div class="flex items-center gap-3 mb-3">
            <div class="size-10 rounded-2xl bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
              <.icon name="hero-clock" class="size-5 text-amber-600" />
            </div>
            <span class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Outstanding</span>
          </div>
          <p class="text-2xl font-black text-amber-600">
            ${format_money(@stats.outstanding)}
          </p>
        </div>

        <div class="bg-white dark:bg-zinc-900 rounded-[24px] p-6 border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <div class="flex items-center gap-3 mb-3">
            <div class="size-10 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
              <.icon name="hero-hashtag" class="size-5 text-zinc-500" />
            </div>
            <span class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Count</span>
          </div>
          <p class="text-2xl font-black text-zinc-900 dark:text-white">
            {@stats.invoice_count}
          </p>
        </div>
      </div>
      
    <!-- Filters -->
      <div class="flex items-center gap-2">
        <%= for {label, value} <- [{"All", "all"}, {"Draft", "draft"}, {"Sent", "sent"}, {"Paid", "paid"}, {"Overdue", "overdue"}] do %>
          <button
            phx-click="filter"
            phx-value-status={value}
            class={[
              "px-4 py-2.5 text-xs font-bold rounded-xl transition-all",
              @filter == value && "bg-primary/10 text-primary border border-primary/20",
              @filter != value &&
                "text-zinc-500 hover:bg-zinc-100 dark:hover:bg-zinc-800 border border-transparent"
            ]}
          >
            {label}
          </button>
        <% end %>
      </div>
      
    <!-- Invoice List -->
      <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
        <%= if @invoices == [] do %>
          <div class="p-12 text-center">
            <div class="size-16 rounded-full bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-document-text" class="size-8 text-zinc-400" />
            </div>
            <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2">No invoices yet</h3>
            <p class="text-sm text-zinc-500 dark:text-zinc-400">
              Generate invoices from completed jobs to see them here.
            </p>
          </div>
        <% else %>
          <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead class="bg-zinc-50 dark:bg-zinc-800/50">
              <tr>
                <th class="px-6 py-4 text-left text-xs font-black text-zinc-500 uppercase tracking-widest">
                  Invoice
                </th>
                <th class="px-6 py-4 text-left text-xs font-black text-zinc-500 uppercase tracking-widest">
                  Customer
                </th>
                <th class="px-6 py-4 text-left text-xs font-black text-zinc-500 uppercase tracking-widest">
                  Date
                </th>
                <th class="px-6 py-4 text-left text-xs font-black text-zinc-500 uppercase tracking-widest">
                  Status
                </th>
                <th class="px-6 py-4 text-right text-xs font-black text-zinc-500 uppercase tracking-widest">
                  Amount
                </th>
                <th class="px-6 py-4"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
              <%= for invoice <- @invoices do %>
                <tr class="hover:bg-zinc-50 dark:hover:bg-zinc-800/30 transition-colors">
                  <td class="px-6 py-5">
                    <.link
                      navigate={~p"/invoices/#{invoice.id}"}
                      class="font-bold text-zinc-900 dark:text-white hover:text-primary transition-colors"
                    >
                      {invoice.number}
                    </.link>
                  </td>
                  <td class="px-6 py-5">
                    <span class="text-sm text-zinc-600 dark:text-zinc-300">
                      {(invoice.customer && invoice.customer.name) || "—"}
                    </span>
                  </td>
                  <td class="px-6 py-5">
                    <span class="text-sm text-zinc-500">
                      {format_date(invoice.issue_date)}
                    </span>
                  </td>
                  <td class="px-6 py-5">
                    <span class={"inline-flex px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-widest #{status_badge(invoice.status)}"}>
                      {invoice.status}
                    </span>
                  </td>
                  <td class="px-6 py-5 text-right">
                    <span class="font-bold text-zinc-900 dark:text-white">
                      ${format_money(invoice.total_amount)}
                    </span>
                  </td>
                  <td class="px-6 py-5 text-right">
                    <.link
                      navigate={~p"/invoices/#{invoice.id}"}
                      class="text-sm font-bold text-primary hover:text-primary/80 transition-colors"
                    >
                      View
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_money(nil), do: "0.00"
  defp format_money(%Decimal{} = amount), do: Decimal.to_string(amount, :normal)

  defp format_money(amount) when is_number(amount),
    do: :erlang.float_to_binary(amount / 1, decimals: 2)

  defp format_money(_), do: "0.00"

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp status_badge("draft"), do: "bg-zinc-100 text-zinc-600"
  defp status_badge("sent"), do: "bg-blue-50 text-blue-700"
  defp status_badge("viewed"), do: "bg-purple-50 text-purple-700"
  defp status_badge("paid"), do: "bg-emerald-50 text-emerald-700"
  defp status_badge("overdue"), do: "bg-red-50 text-red-700"
  defp status_badge("cancelled"), do: "bg-zinc-50 text-zinc-500"
  defp status_badge(_), do: "bg-zinc-100 text-zinc-600"
end
