defmodule FieldHubWeb.ReportLive.Index do
  use FieldHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Reports")
      |> assign(:current_nav, :reports)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full">
      <div class="md:flex md:items-center md:justify-between mb-8">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-zinc-900 dark:text-white sm:truncate sm:text-3xl sm:tracking-tight">
            Reports
          </h2>
          <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
            Overview of your organization's performance.
          </p>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4 mb-8">
        <div class="overflow-hidden rounded-xl bg-white dark:bg-zinc-900 shadow ring-1 ring-zinc-900/5 dark:ring-white/10">
          <div class="p-6">
            <div class="flex items-center gap-4">
              <div class="rounded-lg bg-primary/10 p-3">
                <.icon name="hero-banknotes" class="h-6 w-6 text-primary" />
              </div>
              <div>
                <dt class="truncate text-sm font-medium text-zinc-500 dark:text-zinc-400">Total Revenue</dt>
                <dd class="mt-1 text-2xl font-bold tracking-tight text-zinc-900 dark:text-white">$12,500</dd>
              </div>
            </div>
          </div>
        </div>

        <div class="overflow-hidden rounded-xl bg-white dark:bg-zinc-900 shadow ring-1 ring-zinc-900/5 dark:ring-white/10">
          <div class="p-6">
            <div class="flex items-center gap-4">
              <div class="rounded-lg bg-blue-500/10 p-3">
                <.icon name="hero-briefcase" class="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <dt class="truncate text-sm font-medium text-zinc-500 dark:text-zinc-400">Completed Jobs</dt>
                <dd class="mt-1 text-2xl font-bold tracking-tight text-zinc-900 dark:text-white">45</dd>
              </div>
            </div>
          </div>
        </div>

        <div class="overflow-hidden rounded-xl bg-white dark:bg-zinc-900 shadow ring-1 ring-zinc-900/5 dark:ring-white/10">
          <div class="p-6">
            <div class="flex items-center gap-4">
              <div class="rounded-lg bg-amber-500/10 p-3">
                <.icon name="hero-user-group" class="h-6 w-6 text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <dt class="truncate text-sm font-medium text-zinc-500 dark:text-zinc-400">New Customers</dt>
                <dd class="mt-1 text-2xl font-bold tracking-tight text-zinc-900 dark:text-white">12</dd>
              </div>
            </div>
          </div>
        </div>

         <div class="overflow-hidden rounded-xl bg-white dark:bg-zinc-900 shadow ring-1 ring-zinc-900/5 dark:ring-white/10">
          <div class="p-6">
            <div class="flex items-center gap-4">
              <div class="rounded-lg bg-emerald-500/10 p-3">
                 <.icon name="hero-check-circle" class="h-6 w-6 text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <dt class="truncate text-sm font-medium text-zinc-500 dark:text-zinc-400">Resolution Rate</dt>
                <dd class="mt-1 text-2xl font-bold tracking-tight text-zinc-900 dark:text-white">98%</dd>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State / Placeholder for Charts -->
      <div class="rounded-xl border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 shadow-sm">
        <div class="border-b border-zinc-200 dark:border-zinc-800 px-6 py-4">
           <h3 class="text-base font-semibold leading-6 text-zinc-900 dark:text-white">Revenue History</h3>
        </div>
        <div class="p-6">
           <div class="flex h-96 flex-col items-center justify-center rounded-lg border-2 border-dashed border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800/50">
            <.icon name="hero-chart-pie" class="mx-auto h-12 w-12 text-zinc-400" />
            <h3 class="mt-2 text-sm font-semibold text-zinc-900 dark:text-white">Analytics Connector Required</h3>
            <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400 max-w-sm text-center">Detailed charts and graphs will appear here once the analytics engine processes your data.</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
