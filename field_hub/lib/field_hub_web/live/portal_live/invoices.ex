defmodule FieldHubWeb.PortalLive.Invoices do
  @moduledoc """
  Customer portal invoice listing view.
  Customers can view all their invoices and navigate to details.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Billing.Invoice
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    customer = socket.assigns.portal_customer
    invoices = list_customer_invoices(customer.id)

    {:ok,
     socket
     |> assign(:customer, customer)
     |> assign(:invoices, invoices)
     |> assign(:page_title, "My Invoices")}
  end

  defp list_customer_invoices(customer_id) do
    Invoice
    |> Invoice.for_customer(customer_id)
    |> order_by([i], desc: i.inserted_at)
    |> FieldHub.Repo.all()
    |> FieldHub.Repo.preload([:job])
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950">
      <header class="bg-white dark:bg-zinc-900 border-b border-zinc-200 dark:border-zinc-800 sticky top-0 z-50">
        <div class="max-w-4xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between">
          <div class="flex items-center gap-4">
            <.link
              navigate={~p"/portal"}
              class="size-10 rounded-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center hover:bg-zinc-200 dark:hover:hover:bg-zinc-700 transition-colors"
            >
              <.icon name="hero-arrow-left" class="size-5 text-zinc-600 dark:text-zinc-400" />
            </.link>
            <div>
              <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em]">
                Billing
              </p>
              <h1 class="text-lg font-bold text-zinc-900 dark:text-white">
                My Invoices
              </h1>
            </div>
          </div>
        </div>
      </header>

      <main class="max-w-4xl mx-auto px-4 sm:px-6 py-8">
        <%= if Enum.empty?(@invoices) do %>
          <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-12 text-center">
            <div class="size-16 rounded-full bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-document-text" class="size-8 text-zinc-400" />
            </div>
            <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2">No invoices yet</h3>
            <p class="text-zinc-500 dark:text-zinc-400 text-sm max-w-xs mx-auto">
              When you receive invoices for completed services, they will appear here.
            </p>
          </div>
        <% else %>
          <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
            <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
              <%= for invoice <- @invoices do %>
                <.link
                  navigate={~p"/portal/invoices/#{invoice.id}"}
                  class="block px-6 py-5 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
                >
                  <div class="flex items-center justify-between">
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-3 mb-2">
                        <span class="text-base font-bold text-zinc-900 dark:text-white">
                          {invoice.number}
                        </span>
                        <span class={"inline-flex px-2 py-0.5 rounded-lg text-[10px] font-black uppercase tracking-wider #{status_badge_class(invoice.status)}"}>
                          {invoice.status}
                        </span>
                      </div>
                      <div class="flex items-center gap-4 text-sm text-zinc-500">
                        <%= if invoice.job do %>
                          <span>Job: {invoice.job.title}</span>
                        <% end %>
                        <span>Due: {format_date(invoice.due_date)}</span>
                      </div>
                    </div>
                    <div class="flex items-center gap-4">
                      <span class="text-lg font-black text-zinc-900 dark:text-white">
                        ${format_money(invoice.total_amount)}
                      </span>
                      <.icon name="hero-chevron-right" class="size-5 text-zinc-300" />
                    </div>
                  </div>
                </.link>
              <% end %>
            </div>
          </div>
        <% end %>
      </main>
    </div>
    """
  end

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp format_money(nil), do: "0.00"
  defp format_money(%Decimal{} = amount), do: Decimal.to_string(amount, :normal)

  defp format_money(amount) when is_number(amount),
    do: :erlang.float_to_binary(amount / 1, decimals: 2)

  defp format_money(_), do: "0.00"

  defp status_badge_class("draft"), do: "bg-zinc-100 text-zinc-600"
  defp status_badge_class("sent"), do: "bg-blue-50 text-blue-700"
  defp status_badge_class("viewed"), do: "bg-purple-50 text-purple-700"
  defp status_badge_class("paid"), do: "bg-emerald-50 text-emerald-700"
  defp status_badge_class("overdue"), do: "bg-red-50 text-red-700"
  defp status_badge_class("cancelled"), do: "bg-zinc-50 text-zinc-500"
  defp status_badge_class(_), do: "bg-zinc-100 text-zinc-600"
end
