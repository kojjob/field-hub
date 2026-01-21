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
    <div class="space-y-10 pb-20">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            Financial Management
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Billing & Invoicing
          </h2>
        </div>
        <div class="flex items-center gap-3">
          <div class="px-4 py-2.5 bg-zinc-100 dark:bg-zinc-800 rounded-xl text-sm font-bold border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400 flex items-center gap-2">
            <.icon name="hero-calendar" class="size-5" />
            <span>Monthly Cycle</span>
          </div>
        </div>
      </div>
      
    <!-- Stats Row -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <div class="bg-white dark:bg-zinc-900 rounded-[28px] p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col justify-between group hover:border-primary/20 transition-all">
          <div class="flex items-center justify-between mb-4">
            <div class="size-11 rounded-2xl bg-primary/10 flex items-center justify-center group-hover:bg-primary group-hover:text-white transition-all">
              <.icon name="hero-calculator" class="size-6 text-primary group-hover:text-white" />
            </div>
            <span class="text-[10px] font-black text-zinc-400 uppercase tracking-widest">
              Generated
            </span>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-black text-zinc-400 uppercase tracking-widest">
              Total Invoiced
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              ${format_money(@stats.total_invoiced)}
            </p>
          </div>
        </div>

        <div class="bg-white dark:bg-zinc-900 rounded-[28px] p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col justify-between group hover:border-emerald-500/20 transition-all">
          <div class="flex items-center justify-between mb-4">
            <div class="size-11 rounded-2xl bg-emerald-500/10 flex items-center justify-center group-hover:bg-emerald-500 group-hover:text-white transition-all">
              <.icon name="hero-check-badge" class="size-6 text-emerald-600 group-hover:text-white" />
            </div>
            <span class="text-[10px] font-black text-emerald-500 uppercase tracking-widest">
              Settled
            </span>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-black text-zinc-400 uppercase tracking-widest">Paid In Full</p>
            <p class="text-3xl font-black text-emerald-600 tracking-tighter">
              ${format_money(@stats.total_paid)}
            </p>
          </div>
        </div>

        <div class="bg-white dark:bg-zinc-900 rounded-[28px] p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col justify-between group hover:border-amber-500/20 transition-all border-b-4 border-b-amber-500/10">
          <div class="flex items-center justify-between mb-4">
            <div class="size-11 rounded-2xl bg-amber-500/10 flex items-center justify-center group-hover:bg-amber-500 group-hover:text-white transition-all">
              <.icon name="hero-clock" class="size-6 text-amber-600 group-hover:text-white" />
            </div>
            <span class="text-[10px] font-black text-amber-500 uppercase tracking-widest">
              Pending
            </span>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-black text-zinc-400 uppercase tracking-widest">Outstanding</p>
            <p class="text-3xl font-black text-amber-600 tracking-tighter">
              ${format_money(@stats.outstanding)}
            </p>
          </div>
        </div>

        <div class="bg-white dark:bg-zinc-900 rounded-[28px] p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col justify-between group hover:border-zinc-500/20 transition-all">
          <div class="flex items-center justify-between mb-4">
            <div class="size-11 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center group-hover:bg-zinc-900 dark:group-hover:bg-white dark:group-hover:text-zinc-900 group-hover:text-white transition-all">
              <.icon name="hero-hashtag" class="size-6 text-zinc-500" />
            </div>
            <span class="text-[10px] font-black text-zinc-400 uppercase tracking-widest">
              Volume
            </span>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-black text-zinc-400 uppercase tracking-widest">Total Count</p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              {@stats.invoice_count}
            </p>
          </div>
        </div>
      </div>
      
    <!-- Control Bar -->
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-6 bg-zinc-50 dark:bg-zinc-800/50 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800">
        <div class="flex items-center gap-2 overflow-x-auto pb-2 md:pb-0">
          <%= for {label, value} <- [{"All", "all"}, {"Draft", "draft"}, {"Sent", "sent"}, {"Paid", "paid"}, {"Overdue", "overdue"}] do %>
            <button
              phx-click="filter"
              phx-value-status={value}
              class={[
                "px-5 py-2.5 text-xs font-black rounded-xl transition-all uppercase tracking-widest whitespace-nowrap",
                @filter == value && "bg-primary text-white shadow-lg shadow-primary/20",
                @filter != value &&
                  "text-zinc-500 hover:bg-white dark:hover:bg-zinc-800 border border-transparent hover:border-zinc-200"
              ]}
            >
              {label}
            </button>
          <% end %>
        </div>

        <div class="flex items-center gap-3">
          <div class="relative group">
            <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
              <.icon
                name="hero-magnifying-glass"
                class="size-4 text-zinc-400 group-focus-within:text-primary transition-colors"
              />
            </div>
            <input
              type="text"
              placeholder="Search invoices..."
              class="block w-full sm:w-64 pl-10 pr-4 py-2.5 rounded-xl border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-900 text-sm font-bold focus:ring-primary focus:border-primary transition-all"
            />
          </div>
        </div>
      </div>
      
    <!-- Invoice Table -->
      <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
        <%= if @invoices == [] do %>
          <div class="p-20 text-center">
            <div class="size-20 rounded-3xl bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center mx-auto mb-6 border border-dashed border-zinc-200 dark:border-zinc-700">
              <.icon name="hero-document-text" class="size-10 text-zinc-300" />
            </div>
            <h3 class="text-xl font-black text-zinc-900 dark:text-white mb-2">No invoices found</h3>
            <p class="text-sm text-zinc-500 dark:text-zinc-400 max-w-xs mx-auto">
              We couldn't find any invoices matching your current filter. Try adjusting your search.
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full text-left">
              <thead>
                <tr class="text-[10px] font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-widest border-b border-zinc-50 dark:border-zinc-800">
                  <th class="px-8 py-5">Reference</th>
                  <th class="px-8 py-5">Customer</th>
                  <th class="px-8 py-5">Issue Date</th>
                  <th class="px-8 py-5">Status</th>
                  <th class="px-8 py-5 text-right">Amount</th>
                  <th class="px-8 py-5"></th>
                </tr>
              </thead>
              <tbody class="divide-y divide-zinc-50 dark:divide-zinc-800/50">
                <%= for invoice <- @invoices do %>
                  <tr class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/20 transition-all duration-300">
                    <td class="px-8 py-6">
                      <div class="flex items-center gap-4">
                        <div class="size-10 rounded-xl bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center border border-zinc-200 dark:border-zinc-700 group-hover:border-primary/50 group-hover:bg-primary/5 transition-all">
                          <.icon
                            name="hero-document"
                            class="size-5 text-zinc-400 group-hover:text-primary transition-colors"
                          />
                        </div>
                        <.link
                          navigate={~p"/invoices/#{invoice.id}"}
                          class="font-black text-[15px] text-zinc-900 dark:text-white hover:text-primary transition-colors"
                        >
                          {invoice.number}
                        </.link>
                      </div>
                    </td>
                    <td class="px-8 py-6">
                      <div :if={invoice.customer} class="flex items-center gap-3">
                        <div class="size-8 rounded-full border border-zinc-200 dark:border-zinc-700 overflow-hidden">
                          <img
                            src={"https://ui-avatars.com/api/?name=#{URI.encode_www_form(invoice.customer.name)}&background=f4f4f5&color=71717a"}
                            class="size-full object-cover"
                          />
                        </div>
                        <span class="text-sm font-bold text-zinc-700 dark:text-zinc-300">
                          {invoice.customer.name}
                        </span>
                      </div>
                      <span :if={!invoice.customer} class="text-sm text-zinc-400 italic">
                        No customer
                      </span>
                    </td>
                    <td class="px-8 py-6">
                      <p class="text-[14px] font-black text-zinc-900 dark:text-white">
                        {format_date(invoice.issue_date)}
                      </p>
                      <p class="text-[11px] text-zinc-500 font-bold uppercase tracking-wider mt-0.5">
                        Due: {format_date(invoice.due_date)}
                      </p>
                    </td>
                    <td class="px-8 py-6">
                      <span class={[
                        "px-3.5 py-1.5 rounded-xl text-[10px] font-black border tracking-widest shadow-sm uppercase",
                        status_badge_theme(invoice.status)
                      ]}>
                        {invoice.status}
                      </span>
                    </td>
                    <td class="px-8 py-6 text-right">
                      <span class="text-lg font-black text-zinc-900 dark:text-white tracking-tighter">
                        ${format_money(invoice.total_amount)}
                      </span>
                    </td>
                    <td class="px-8 py-6 text-right">
                      <div class="flex justify-end items-center gap-2">
                        <.link
                          navigate={~p"/invoices/#{invoice.id}"}
                          class="size-10 flex items-center justify-center rounded-xl bg-zinc-50 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-300 hover:bg-zinc-900 hover:text-white dark:hover:bg-white dark:hover:text-zinc-900 transition-all shadow-sm border border-zinc-200 dark:border-zinc-700"
                        >
                          <.icon name="hero-arrow-right" class="size-5" />
                        </.link>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
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

  defp status_badge_theme("draft"), do: "bg-zinc-100 text-zinc-600 border-zinc-200"
  defp status_badge_theme("sent"), do: "bg-blue-50 text-blue-700 border-blue-100"
  defp status_badge_theme("viewed"), do: "bg-purple-50 text-purple-700 border-purple-100"
  defp status_badge_theme("paid"), do: "bg-emerald-50 text-emerald-700 border-emerald-100"
  defp status_badge_theme("overdue"), do: "bg-red-50 text-red-700 border-red-100"
  defp status_badge_theme("cancelled"), do: "bg-zinc-50 text-zinc-500 border-zinc-100"
  defp status_badge_theme(_), do: "bg-zinc-100 text-zinc-600 border-zinc-200"
end
