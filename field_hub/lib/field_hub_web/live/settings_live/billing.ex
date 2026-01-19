defmodule FieldHubWeb.SettingsLive.Billing do
  use FieldHubWeb, :live_view




  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role not in ["owner"] do
      {:ok,
       socket
       |> put_flash(:error, "You do not have permission to view billing settings.")
       |> push_navigate(to: ~p"/dashboard")}
    else
      socket =
        socket
        |> assign(:page_title, "Billing & Subscription")
        |> assign(:current_nav, :billing)

      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-8">
      <div>
        <h1 class="text-3xl font-black text-zinc-900 dark:text-white tracking-tight">
          Subscription
        </h1>
        <p class="mt-2 text-zinc-600 dark:text-zinc-400">
          Manage your plan and billing details.
        </p>
      </div>

      <!-- Current Plan -->
      <div class="bg-white dark:bg-zinc-900 rounded-[32px] overflow-hidden shadow-xl shadow-zinc-900/5 ring-1 ring-zinc-200 dark:ring-zinc-800">
        <div class="p-8 border-b border-zinc-100 dark:border-zinc-800 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <h2 class="text-lg font-bold text-zinc-900 dark:text-white">Current Plan</h2>
            <div class="mt-2 flex items-center gap-3">
              <span class="text-3xl font-black text-primary capitalize">
                <%= @current_organization.subscription_tier %>
              </span>
              <span class={[
                "px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wide",
                @current_organization.subscription_status == "active" && "bg-emerald-100 text-emerald-800",
                @current_organization.subscription_status == "trial" && "bg-blue-100 text-blue-800",
                @current_organization.subscription_status == "past_due" && "bg-red-100 text-red-800",
              ]}>
                <%= @current_organization.subscription_status %>
              </span>
            </div>
            <%= if @current_organization.subscription_status == "trial" do %>
              <p class="mt-2 text-sm text-zinc-500">
                Trial ends on <%= Calendar.strftime(@current_organization.trial_ends_at || DateTime.utc_now(), "%B %d, %Y") %>
              </p>
            <% end %>
          </div>

          <button class="px-6 py-3 bg-zinc-900 hover:bg-zinc-800 dark:bg-white dark:hover:bg-zinc-200 text-white dark:text-zinc-900 rounded-xl font-bold transition-all">
            Upgrade Plan
          </button>
        </div>

        <div class="p-8 grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <div class="text-sm font-bold text-zinc-500 uppercase tracking-wide">Monthly Total</div>
            <div class="mt-1 text-2xl font-bold text-zinc-900 dark:text-white">$0.00</div>
          </div>
          <div>
             <div class="text-sm font-bold text-zinc-500 uppercase tracking-wide">Next Billing Date</div>
            <div class="mt-1 text-2xl font-bold text-zinc-900 dark:text-white">
              <%= Calendar.strftime(Date.add(Date.utc_today(), 30), "%b %d, %Y") %>
            </div>
          </div>
          <div>
             <div class="text-sm font-bold text-zinc-500 uppercase tracking-wide">Payment Method</div>
            <div class="mt-1 flex items-center gap-2 font-medium text-zinc-900 dark:text-white">
              <.icon name="hero-credit-card" class="size-5 text-zinc-400" />
              Not set
            </div>
          </div>
        </div>
      </div>

      <!-- Invoices -->
      <div class="bg-white dark:bg-zinc-900 rounded-[32px] overflow-hidden shadow-xl shadow-zinc-900/5 ring-1 ring-zinc-200 dark:ring-zinc-800 p-8">
         <h2 class="text-lg font-bold text-zinc-900 dark:text-white mb-6">Billing History</h2>

         <div class="text-center py-12">
            <div class="size-16 bg-zinc-50 dark:bg-zinc-800 rounded-full flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-document-text" class="size-8 text-zinc-300" />
            </div>
            <h3 class="text-zinc-900 dark:text-white font-bold">No invoices yet</h3>
            <p class="text-zinc-500 text-sm mt-1">When you verify your payment method, your invoices will appear here.</p>
         </div>
      </div>
    </div>
    """
  end
end
