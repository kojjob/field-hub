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
    <div class="space-y-10 pb-20">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            Organization
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Billing & Subscription
          </h2>
          <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 max-w-lg">
             Manage your plan, payment methods, and billing history.
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <!-- Main Content -->
        <div class="xl:col-span-2 space-y-8">
            <!-- Current Plan Card -->
            <div class="bg-white dark:bg-zinc-900 rounded-[24px] overflow-hidden shadow-sm border border-zinc-200 dark:border-zinc-800 relative group">
                <div class="absolute top-0 right-0 w-64 h-64 bg-emerald-500/5 rounded-full -mr-20 -mt-20 transition-all group-hover:bg-emerald-500/10 pointer-events-none"></div>

                <div class="p-8 border-b border-zinc-100 dark:border-zinc-800 flex flex-col md:flex-row md:items-center justify-between gap-6 relative z-10">
                <div>
                    <h2 class="text-lg font-black text-zinc-900 dark:text-white flex items-center gap-2">
                        <div class="size-8 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                            <.icon name="hero-sparkles" class="size-4 text-emerald-500" />
                        </div>
                        Current Plan
                    </h2>
                    <div class="mt-4 flex items-center gap-3">
                    <span class="text-4xl font-black text-zinc-900 dark:text-white capitalize">
                        <%= @current_organization.subscription_tier %>
                    </span>
                    <span class={[
                        "px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wide",
                        @current_organization.subscription_status == "active" && "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300",
                        @current_organization.subscription_status == "trial" && "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300",
                        @current_organization.subscription_status == "past_due" && "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300",
                    ]}>
                        <%= @current_organization.subscription_status %>
                    </span>
                    </div>
                    <%= if @current_organization.subscription_status == "trial" do %>
                    <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 font-bold">
                        Trial ends on <span class="text-zinc-900 dark:text-white"><%= Calendar.strftime(@current_organization.trial_ends_at || DateTime.utc_now(), "%B %d, %Y") %></span>
                    </p>
                    <% end %>
                </div>

                <button class="px-6 py-3 bg-zinc-900 hover:bg-zinc-800 dark:bg-white dark:hover:bg-zinc-200 text-white dark:text-zinc-900 rounded-xl font-bold transition-all shadow-lg shadow-zinc-900/10">
                    Upgrade Plan
                </button>
                </div>

                <div class="p-8 grid grid-cols-1 md:grid-cols-2 gap-8 bg-zinc-50/50 dark:bg-zinc-800/20">
                <div class="space-y-1">
                    <div class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">Next Billing Date</div>
                    <div class="text-lg font-bold text-zinc-900 dark:text-white flex items-center gap-2">
                     <.icon name="hero-calendar" class="size-5 text-zinc-400" />
                    <%= Calendar.strftime(Date.add(Date.utc_today(), 30), "%b %d, %Y") %>
                    </div>
                </div>
                <div class="space-y-1">
                    <div class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">Payment Method</div>
                    <div class="flex items-center gap-2 font-bold text-zinc-900 dark:text-white text-lg">
                    <.icon name="hero-credit-card" class="size-5 text-zinc-400" />
                    Not set
                    </div>
                    <button class="text-xs font-bold text-primary hover:text-primary/80">
                        + Add Method
                    </button>
                </div>
                </div>
            </div>

            <!-- Invoices -->
            <div class="bg-white dark:bg-zinc-900 rounded-[24px] overflow-hidden shadow-sm border border-zinc-200 dark:border-zinc-800 p-8">
                 <div class="flex items-center justify-between mb-8">
                     <h2 class="text-lg font-black text-zinc-900 dark:text-white flex items-center gap-2">
                        <div class="size-8 rounded-lg bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
                            <.icon name="hero-document-text" class="size-4 text-zinc-500" />
                        </div>
                        Billing History
                    </h2>
                    <button class="text-sm font-bold text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200">
                        Download All
                    </button>
                 </div>

                <div class="text-center py-12 bg-zinc-50/50 dark:bg-zinc-800/20 rounded-2xl border border-dashed border-zinc-200 dark:border-zinc-700">
                    <div class="size-16 bg-zinc-100 dark:bg-zinc-800 rounded-full flex items-center justify-center mx-auto mb-4">
                    <.icon name="hero-inbox" class="size-8 text-zinc-300" />
                    </div>
                    <h3 class="text-zinc-900 dark:text-white font-bold">No invoices yet</h3>
                    <p class="text-zinc-500 text-sm mt-1 max-w-xs mx-auto">When you verify your payment method, your invoices will appear here.</p>
                </div>
            </div>
        </div>

        <!-- Sidebar Info -->
        <div class="xl:col-span-1 space-y-6">
             <div class="bg-primary/5 p-6 rounded-[24px] border border-primary/10">
                <h3 class="font-black text-primary mb-2 flex items-center gap-2">
                    <.icon name="hero-rocket-launch" class="size-5" />
                    Pro Features
                </h3>
                <p class="text-sm text-zinc-600 dark:text-zinc-400 mb-6 leading-relaxed">
                    Upgrade to Pro to unlock advanced features for your growing business.
                </p>
                <ul class="space-y-3 mb-6">
                    <li class="flex items-start gap-3 text-sm text-zinc-700 dark:text-zinc-300 font-medium">
                        <.icon name="hero-check-circle" class="size-5 text-emerald-500 shrink-0" />
                        <span>Unlimited Technicians</span>
                    </li>
                    <li class="flex items-start gap-3 text-sm text-zinc-700 dark:text-zinc-300 font-medium">
                        <.icon name="hero-check-circle" class="size-5 text-emerald-500 shrink-0" />
                        <span>Advanced Reporting</span>
                    </li>
                    <li class="flex items-start gap-3 text-sm text-zinc-700 dark:text-zinc-300 font-medium">
                        <.icon name="hero-check-circle" class="size-5 text-emerald-500 shrink-0" />
                        <span>Priority Support</span>
                    </li>
                </ul>
                <button class="w-full py-3 bg-primary text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 hover:brightness-110 transition-all">
                    View Pricing
                </button>
             </div>

             <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
                <h3 class="font-bold text-zinc-900 dark:text-white mb-2">Need help?</h3>
                <p class="text-sm text-zinc-500 mb-4">
                    Contact our billing support team for assistance with invoices or payments.
                </p>
                <a href="mailto:billing@fieldhub.com" class="text-sm font-bold text-zinc-900 dark:text-white flex items-center gap-2 hover:underline">
                    <.icon name="hero-envelope" class="size-4" /> billing@fieldhub.com
                </a>
             </div>
        </div>
      </div>
    </div>
    """
  end
end
