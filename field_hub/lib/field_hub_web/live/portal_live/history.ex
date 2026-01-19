defmodule FieldHubWeb.PortalLive.History do
  @moduledoc """
  Customer portal service history view.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs

  @impl true
  def mount(_params, _session, socket) do
    customer = socket.assigns.portal_customer
    completed_jobs = Jobs.list_completed_jobs_for_customer(customer.id, limit: 50)

    {:ok,
     socket
     |> assign(:customer, customer)
     |> assign(:completed_jobs, completed_jobs)
     |> assign(:page_title, "Service History")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950">
      <header class="bg-white dark:bg-zinc-900 border-b border-zinc-200 dark:border-zinc-800 sticky top-0 z-50">
        <div class="max-w-4xl mx-auto px-4 sm:px-6 py-4 flex items-center gap-4">
          <.link
            navigate={~p"/portal"}
            class="size-10 rounded-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors"
          >
            <.icon name="hero-arrow-left" class="size-5 text-zinc-600 dark:text-zinc-400" />
          </.link>
          <div class="flex-1">
            <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em]">
              {@customer.organization.name}
            </p>
            <h1 class="text-lg font-bold text-zinc-900 dark:text-white">
              Service History
            </h1>
          </div>
        </div>
      </header>

      <main class="max-w-4xl mx-auto px-4 sm:px-6 py-8">
        <%= if Enum.empty?(@completed_jobs) do %>
          <div class="bg-white dark:bg-zinc-900 rounded-3xl border border-zinc-200 dark:border-zinc-800 p-12 text-center">
            <div class="size-20 mx-auto mb-6 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
              <.icon name="hero-clock" class="size-10 text-zinc-300 dark:text-zinc-700" />
            </div>
            <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2">No service history</h3>
            <p class="text-zinc-500 max-w-sm mx-auto text-sm">
              Your completed services will appear here once they are finished.
            </p>
          </div>
        <% else %>
          <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
            <div class="px-6 py-4 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between bg-zinc-50/50 dark:bg-zinc-800/50">
              <h2 class="text-sm font-bold text-zinc-900 dark:text-white uppercase tracking-wider">
                {length(@completed_jobs)} Completed Services
              </h2>
            </div>
            <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
              <%= for job <- @completed_jobs do %>
                <.link
                  navigate={~p"/portal/jobs/#{job.id}"}
                  class="block p-5 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors group"
                >
                  <div class="flex items-start justify-between gap-4">
                    <div class="flex-1 min-w-0">
                      <h3 class="font-bold text-zinc-900 dark:text-white group-hover:text-primary transition-colors truncate">
                        {job.title}
                      </h3>
                      <div class="flex items-center gap-4 mt-2">
                        <p class="text-xs text-zinc-500 flex items-center gap-1.5">
                          <.icon name="hero-calendar" class="size-3.5" />
                          <%= if job.completed_at do %>
                            {Calendar.strftime(job.completed_at, "%b %d, %Y")}
                          <% else %>
                            {Calendar.strftime(job.inserted_at, "%b %d, %Y")}
                          <% end %>
                        </p>
                        <%= if job.technician do %>
                          <p class="text-xs text-zinc-500 flex items-center gap-1.5">
                            <.icon name="hero-user" class="size-3.5" />
                            {job.technician.name}
                          </p>
                        <% end %>
                      </div>
                    </div>
                    <.icon name="hero-chevron-right" class="size-5 text-zinc-300 dark:text-zinc-700 group-hover:translate-x-1 transition-transform" />
                  </div>
                </.link>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="mt-8 text-center">
          <p class="text-xs text-zinc-400">
            Showing last 50 completed services.
          </p>
        </div>
      </main>
    </div>
    """
  end
end
