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
      |> assign(:current_nav, :invoices)
      |> assign(:page_title, "Invoices")
      |> assign(:filter, "all")
      |> assign(:search_query, "")
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

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, :search_query, query)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 pb-20">
      <%!-- Page Header --%>
      <div class="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            Financial Management
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Invoicing & Payments Center
          </h2>
          <p class="text-zinc-500 dark:text-zinc-400 font-medium mt-1">
            Manage cash flow, process payments, and track receivables.
          </p>
        </div>
        <div class="flex items-center gap-3">
          <button class="flex items-center gap-2 px-4 py-2.5 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-700 dark:text-zinc-200 rounded-xl font-bold text-sm hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all">
            <.icon name="hero-clock" class="size-4" /> Payment History
          </button>
          <.link navigate={~p"/jobs"}>
            <button class="flex items-center gap-2 px-5 py-2.5 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1">
              <.icon name="hero-plus" class="size-5" /> Create New Invoice
            </button>
          </.link>
        </div>
      </div>

      <%!-- KPI Cards --%>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <%!-- Total Receivables --%>
        <div class="bg-white dark:bg-zinc-900 p-6 rounded-2xl border border-zinc-100 dark:border-zinc-800 shadow-sm border-l-4 border-l-primary">
          <div class="flex items-center justify-between">
            <span class="text-sm font-semibold text-zinc-500 dark:text-zinc-400">
              Total Receivables
            </span>
            <span class="p-2.5 bg-primary/10 text-primary rounded-xl">
              <.icon name="hero-banknotes" class="size-5" />
            </span>
          </div>
          <div class="mt-3">
            <p class="text-3xl font-black text-zinc-900 dark:text-white">
              {currency_symbol(@current_organization.currency)}{format_money(@stats.outstanding)}
            </p>
            <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 mt-1">
              {pending_count(@invoices)} pending invoices
            </p>
          </div>
        </div>

        <%!-- Overdue Invoices --%>
        <div class="bg-white dark:bg-zinc-900 p-6 rounded-2xl border border-zinc-100 dark:border-zinc-800 shadow-sm border-l-4 border-l-red-500">
          <div class="flex items-center justify-between">
            <span class="text-sm font-semibold text-zinc-500 dark:text-zinc-400">
              Overdue Invoices
            </span>
            <span class="p-2.5 bg-red-100 dark:bg-red-900/30 text-red-600 rounded-xl">
              <.icon name="hero-exclamation-triangle" class="size-5" />
            </span>
          </div>
          <div class="mt-3">
            <p class="text-3xl font-black text-red-600">
              {currency_symbol(@current_organization.currency)}{format_money(overdue_amount(@invoices))}
            </p>
            <p class="text-xs font-bold text-red-400 mt-1">
              {overdue_count(@invoices)} invoices past due
            </p>
          </div>
        </div>

        <%!-- Paid This Month --%>
        <div class="bg-white dark:bg-zinc-900 p-6 rounded-2xl border border-zinc-100 dark:border-zinc-800 shadow-sm border-l-4 border-l-emerald-500">
          <div class="flex items-center justify-between">
            <span class="text-sm font-semibold text-zinc-500 dark:text-zinc-400">
              Paid This Month
            </span>
            <span class="p-2.5 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 rounded-xl">
              <.icon name="hero-check-badge" class="size-5" />
            </span>
          </div>
          <div class="mt-3">
            <p class="text-3xl font-black text-zinc-900 dark:text-white">
              {currency_symbol(@current_organization.currency)}{format_money(@stats.total_paid || Decimal.new(0))}
            </p>
            <span class="text-xs font-bold text-emerald-600 bg-emerald-50 dark:bg-emerald-900/30 px-2 py-0.5 rounded-md">
              {paid_count(@invoices)} paid
            </span>
          </div>
        </div>
      </div>

      <%!-- Main Content Grid --%>
      <div class="flex flex-col lg:flex-row gap-8">
        <%!-- Invoice Table (Main Content) --%>
        <div class="flex-1 lg:w-[60%] space-y-4">
          <%!-- Table Header with Filters --%>
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <h3 class="text-xl font-bold tracking-tight text-zinc-900 dark:text-white">
                Recent Invoices
              </h3>
              <div class="flex items-center bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 p-1">
                <button
                  phx-click="filter"
                  phx-value-status="all"
                  class={"px-3 py-1.5 text-xs font-bold rounded-md transition-all #{if @filter == "all", do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-900 dark:text-white", else: "text-zinc-500 hover:text-primary"}"}
                >
                  All
                </button>
                <button
                  phx-click="filter"
                  phx-value-status="sent"
                  class={"px-3 py-1.5 text-xs font-bold rounded-md transition-all #{if @filter == "sent", do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-900 dark:text-white", else: "text-zinc-500 hover:text-primary"}"}
                >
                  Unpaid
                </button>
                <button
                  phx-click="filter"
                  phx-value-status="overdue"
                  class={"px-3 py-1.5 text-xs font-bold rounded-md transition-all #{if @filter == "overdue", do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-900 dark:text-white", else: "text-zinc-500 hover:text-primary"}"}
                >
                  Overdue
                </button>
              </div>
            </div>
            <button class="flex items-center gap-2 text-sm font-semibold text-zinc-500 hover:text-primary transition-colors">
              <.icon name="hero-funnel" class="size-4" /> Filter
            </button>
          </div>

          <%!-- Invoice Table --%>
          <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-100 dark:border-zinc-800 shadow-sm overflow-hidden">
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-zinc-50 dark:bg-zinc-800/50 border-b border-zinc-100 dark:border-zinc-800">
                    <th class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-zinc-500 dark:text-zinc-400">
                      Customer Name
                    </th>
                    <th class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-zinc-500 dark:text-zinc-400">
                      Invoice #
                    </th>
                    <th class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-zinc-500 dark:text-zinc-400">
                      Issue Date
                    </th>
                    <th class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-zinc-500 dark:text-zinc-400">
                      Amount
                    </th>
                    <th class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-zinc-500 dark:text-zinc-400">
                      Status
                    </th>
                    <th class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-zinc-500 dark:text-zinc-400">
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
                  <%= if Enum.empty?(@invoices) do %>
                    <tr>
                      <td colspan="6" class="px-6 py-12 text-center">
                        <div class="flex flex-col items-center gap-3">
                          <div class="size-16 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
                            <.icon name="hero-document-text" class="size-8 text-zinc-400" />
                          </div>
                          <p class="text-zinc-500 dark:text-zinc-400 font-medium">
                            No invoices found
                          </p>
                          <p class="text-sm text-zinc-400 dark:text-zinc-500">
                            Create an invoice from a completed job.
                          </p>
                        </div>
                      </td>
                    </tr>
                  <% else %>
                    <%= for invoice <- @invoices do %>
                      <tr class="hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors group">
                        <td class="px-6 py-4">
                          <div class="flex items-center gap-3">
                            <div class={"size-9 rounded-full flex items-center justify-center font-bold text-xs #{avatar_color(invoice.customer.name)}"}>
                              {initials(invoice.customer.name)}
                            </div>
                            <span class="text-sm font-bold text-zinc-900 dark:text-white">
                              {invoice.customer.name}
                            </span>
                          </div>
                        </td>
                        <td class="px-6 py-4 text-sm font-medium text-zinc-600 dark:text-zinc-400">
                          {invoice.number}
                        </td>
                        <td class="px-6 py-4 text-sm font-medium text-zinc-600 dark:text-zinc-400">
                          {format_date(invoice.issue_date)}
                        </td>
                        <td class="px-6 py-4 text-sm font-bold text-zinc-900 dark:text-white">
                          {currency_symbol(@current_organization.currency)}{format_money(invoice.total_amount)}
                        </td>
                        <td class="px-6 py-4">
                          <span class={"inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold #{status_badge_theme(invoice.status)}"}>
                            {String.capitalize(invoice.status)}
                          </span>
                        </td>
                        <td class="px-6 py-4 text-right">
                          <.link
                            navigate={~p"/invoices/#{invoice.id}"}
                            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-zinc-500 hover:text-primary hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-lg transition-all opacity-0 group-hover:opacity-100"
                          >
                            View <.icon name="hero-arrow-right" class="size-3.5" />
                          </.link>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
            <%!-- Table Footer/Pagination --%>
            <div class="px-6 py-4 bg-zinc-50 dark:bg-zinc-800/30 border-t border-zinc-100 dark:border-zinc-800 flex items-center justify-between">
              <p class="text-xs font-bold text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                Showing {length(@invoices)} of {length(@invoices)} Invoices
              </p>
              <div class="flex gap-2">
                <button
                  disabled
                  class="px-3 py-1.5 text-xs font-bold border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 disabled:opacity-50"
                >
                  Previous
                </button>
                <button class="px-3 py-1.5 text-xs font-bold border border-zinc-200 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-colors">
                  Next
                </button>
              </div>
            </div>
          </div>
        </div>

        <%!-- Sidebar --%>
        <div class="lg:w-[40%] space-y-6">
          <%!-- Quick Pay Entry --%>
          <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-100 dark:border-zinc-800 shadow-sm overflow-hidden">
            <div class="p-5 border-b border-zinc-100 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-800/50">
              <h3 class="font-bold text-zinc-900 dark:text-white flex items-center gap-2">
                <.icon name="hero-credit-card" class="size-5 text-primary" /> Quick Pay Entry
              </h3>
            </div>
            <div class="p-5 space-y-4">
              <div class="space-y-1.5">
                <label class="text-[10px] font-extrabold uppercase text-zinc-400 dark:text-zinc-500 tracking-wider">
                  Invoice / Job ID
                </label>
                <input
                  type="text"
                  placeholder="e.g. INV-1021"
                  class="w-full text-sm py-2 px-3 border border-zinc-200 dark:border-zinc-700 rounded-lg dark:bg-zinc-800 focus:ring-primary focus:border-primary"
                />
              </div>
              <div class="space-y-1.5">
                <label class="text-[10px] font-extrabold uppercase text-zinc-400 dark:text-zinc-500 tracking-wider">
                  Amount
                </label>
                <div class="relative">
                  <span class="absolute left-2.5 top-1/2 -translate-y-1/2 text-zinc-400 text-sm font-medium">
                    {currency_symbol(@current_organization.currency)}
                  </span>
                  <input
                    type="number"
                    placeholder="0.00"
                    class="w-full pl-6 text-sm py-2 px-3 border border-zinc-200 dark:border-zinc-700 rounded-lg dark:bg-zinc-800 focus:ring-primary focus:border-primary"
                  />
                </div>
              </div>
              <div class="space-y-1.5">
                <label class="text-[10px] font-extrabold uppercase text-zinc-400 dark:text-zinc-500 tracking-wider">
                  Payment Method
                </label>
                <select class="w-full text-sm py-2 px-3 border border-zinc-200 dark:border-zinc-700 rounded-lg dark:bg-zinc-800 focus:ring-primary focus:border-primary">
                  <option>Credit Card</option>
                  <option>Bank Transfer (ACH)</option>
                  <option>Check</option>
                  <option>Cash</option>
                </select>
              </div>
              <button class="w-full py-2.5 bg-primary text-white text-sm font-bold rounded-lg hover:brightness-110 transition-all mt-2">
                Process Payment
              </button>
            </div>
          </div>

          <%!-- Smart Reminders --%>
          <div class="bg-amber-50 dark:bg-amber-900/10 rounded-2xl border border-amber-100 dark:border-amber-900/30 p-5 space-y-4">
            <div>
              <h4 class="text-sm font-bold text-amber-900 dark:text-amber-100 flex items-center gap-2">
                <.icon name="hero-bell-alert" class="size-4" /> Smart Reminders
              </h4>
              <p class="text-[11px] text-amber-700 dark:text-amber-400 mt-1">
                There are {overdue_count(@invoices)} overdue invoices that haven't received a reminder this week.
              </p>
            </div>
            <button class="w-full py-2 bg-white dark:bg-amber-900/50 border border-amber-200 dark:border-amber-800 text-amber-600 dark:text-amber-300 text-xs font-bold rounded-lg hover:bg-amber-100 dark:hover:bg-amber-900/70 transition-all">
              Send Automated Reminders
            </button>
          </div>

          <%!-- Shortcuts --%>
          <div class="space-y-3">
            <h4 class="text-[10px] font-extrabold text-zinc-400 dark:text-zinc-500 uppercase tracking-widest px-1">
              Shortcuts
            </h4>
            <div class="grid grid-cols-2 gap-3">
              <button class="flex flex-col items-center justify-center p-4 rounded-xl border border-zinc-100 dark:border-zinc-800 bg-white dark:bg-zinc-900 hover:border-primary/50 transition-all gap-2 group">
                <.icon
                  name="hero-arrow-up-tray"
                  class="size-5 text-zinc-400 group-hover:text-primary"
                />
                <span class="text-[10px] font-bold text-zinc-600 dark:text-zinc-300">
                  Bulk Import
                </span>
              </button>
              <button class="flex flex-col items-center justify-center p-4 rounded-xl border border-zinc-100 dark:border-zinc-800 bg-white dark:bg-zinc-900 hover:border-primary/50 transition-all gap-2 group">
                <.icon
                  name="hero-document-chart-bar"
                  class="size-5 text-zinc-400 group-hover:text-primary"
                />
                <span class="text-[10px] font-bold text-zinc-600 dark:text-zinc-300">
                  Tax Report
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp format_money(nil), do: "0.00"
  defp format_money(%Decimal{} = amount), do: Decimal.to_string(Decimal.round(amount, 2), :normal)

  defp format_money(amount) when is_number(amount),
    do: :erlang.float_to_binary(amount / 1, decimals: 2)

  defp format_money(_), do: "0.00"

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp initials(nil), do: "?"

  defp initials(name) when is_binary(name) do
    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp avatar_color(nil), do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-500"

  defp avatar_color(name) when is_binary(name) do
    colors = [
      "bg-primary/10 text-primary",
      "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600",
      "bg-amber-100 dark:bg-amber-900/30 text-amber-600",
      "bg-sky-100 dark:bg-sky-900/30 text-sky-600",
      "bg-rose-100 dark:bg-rose-900/30 text-rose-600",
      "bg-violet-100 dark:bg-violet-900/30 text-violet-600"
    ]

    index = :erlang.phash2(name, length(colors))
    Enum.at(colors, index)
  end

  defp pending_count(invoices) do
    Enum.count(invoices, fn inv -> inv.status in ["draft", "sent", "viewed"] end)
  end

  defp overdue_count(invoices) do
    Enum.count(invoices, fn inv -> inv.status == "overdue" end)
  end

  defp paid_count(invoices) do
    Enum.count(invoices, fn inv -> inv.status == "paid" end)
  end

  defp overdue_amount(invoices) do
    invoices
    |> Enum.filter(fn inv -> inv.status == "overdue" end)
    |> Enum.reduce(Decimal.new(0), fn inv, acc ->
      Decimal.add(acc, inv.total_amount || Decimal.new(0))
    end)
  end

  defp status_badge_theme("draft"),
    do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400"

  defp status_badge_theme("sent"),
    do: "bg-sky-100 dark:bg-sky-900/30 text-sky-700 dark:text-sky-400"

  defp status_badge_theme("viewed"),
    do: "bg-violet-100 dark:bg-violet-900/30 text-violet-700 dark:text-violet-400"

  defp status_badge_theme("paid"),
    do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"

  defp status_badge_theme("overdue"),
    do: "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400"

  defp status_badge_theme("cancelled"),
    do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-500 dark:text-zinc-500"

  defp status_badge_theme(_),
    do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400"

  # Currency symbol mapping based on ISO 4217 currency codes
  defp currency_symbol("USD"), do: "$"
  defp currency_symbol("EUR"), do: "€"
  defp currency_symbol("GBP"), do: "£"
  defp currency_symbol("JPY"), do: "¥"
  defp currency_symbol("CNY"), do: "¥"
  defp currency_symbol("KRW"), do: "₩"
  defp currency_symbol("INR"), do: "₹"
  defp currency_symbol("RUB"), do: "₽"
  defp currency_symbol("BRL"), do: "R$"
  defp currency_symbol("CAD"), do: "C$"
  defp currency_symbol("AUD"), do: "A$"
  defp currency_symbol("CHF"), do: "CHF"
  defp currency_symbol("MXN"), do: "$"
  defp currency_symbol("ZAR"), do: "R"
  defp currency_symbol("NGN"), do: "₦"
  defp currency_symbol("GHS"), do: "₵"
  defp currency_symbol("KES"), do: "KSh"
  defp currency_symbol("AED"), do: "د.إ"
  defp currency_symbol("SAR"), do: "﷼"
  defp currency_symbol("SGD"), do: "S$"
  defp currency_symbol("HKD"), do: "HK$"
  defp currency_symbol("NZD"), do: "NZ$"
  defp currency_symbol("SEK"), do: "kr"
  defp currency_symbol("NOK"), do: "kr"
  defp currency_symbol("DKK"), do: "kr"
  defp currency_symbol("PLN"), do: "zł"
  defp currency_symbol("THB"), do: "฿"
  defp currency_symbol("PHP"), do: "₱"
  defp currency_symbol("IDR"), do: "Rp"
  defp currency_symbol("MYR"), do: "RM"
  defp currency_symbol("VND"), do: "₫"
  defp currency_symbol("TRY"), do: "₺"
  defp currency_symbol("ILS"), do: "₪"
  defp currency_symbol("EGP"), do: "£"
  defp currency_symbol("PKR"), do: "₨"
  defp currency_symbol("BDT"), do: "৳"
  defp currency_symbol("COP"), do: "$"
  defp currency_symbol("ARS"), do: "$"
  defp currency_symbol("CLP"), do: "$"
  defp currency_symbol("PEN"), do: "S/"
  defp currency_symbol(_), do: "$"
end
