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
      <main class="max-w-4xl mx-auto px-4 sm:px-6 py-12">
        <div class="mb-8">
           <.link
              navigate={~p"/portal"}
              class="inline-flex items-center gap-2 text-sm font-bold text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white transition-colors mb-4"
            >
              <.icon name="hero-arrow-left" class="size-4" />
              Back to Dashboard
            </.link>
            <h1 class="text-3xl font-black text-zinc-900 dark:text-white tracking-tight">My Invoices</h1>
            <p class="text-zinc-500 dark:text-zinc-400 mt-1">Manage and pay your invoices from {@customer.organization.name}.</p>
        </div>

        <%= if Enum.empty?(@invoices) do %>
          <div class="bg-white dark:bg-zinc-900 rounded-3xl border border-zinc-200 dark:border-zinc-800 p-12 text-center shadow-sm">
            <div class="size-20 rounded-3xl bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center mx-auto mb-6">
              <.icon name="hero-document-text" class="size-10 text-zinc-300 dark:text-zinc-600" />
            </div>
            <h3 class="text-xl font-bold text-zinc-900 dark:text-white mb-2">No invoices yet</h3>
            <p class="text-zinc-500 dark:text-zinc-400 max-w-sm mx-auto">
              When you receive invoices for completed services, they will appear here.
            </p>
          </div>
        <% else %>
          <div class="flex flex-col gap-4">
            <%= for invoice <- @invoices do %>
              <.link
                navigate={~p"/portal/invoices/#{invoice.id}"}
                class="block bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6 hover:border-primary/50 dark:hover:border-primary/50 transition-all shadow-sm group hover:shadow-md"
              >
                <div class="flex items-center justify-between gap-6">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-3 mb-2">
                       <span class={"inline-flex px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border #{status_badge_class(invoice.status)}"}>
                        {invoice.status}
                      </span>
                      <span class="text-xs text-zinc-400 font-mono">{invoice.number}</span>
                    </div>
                    <div class="flex items-center gap-4 text-sm text-zinc-500 dark:text-zinc-400">
                      <%= if invoice.job do %>
                        <span class="font-medium text-zinc-700 dark:text-zinc-300">Service: {invoice.job.title}</span>
                      <% end %>
                      <span class="text-zinc-400">•</span>
                      <span>Due {format_date(invoice.due_date)}</span>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-2xl font-black text-zinc-900 dark:text-white tracking-tight group-hover:text-primary transition-colors">
                      ${format_money(invoice.total_amount)}
                    </p>
                    <div class="flex items-center justify-end gap-1 text-xs text-primary font-bold mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      View Details <.icon name="hero-arrow-right" class="size-3" />
                    </div>
                  </div>
                </div>
              </.link>
            <% end %>
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
