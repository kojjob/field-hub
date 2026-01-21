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
      <main class="max-w-4xl mx-auto px-4 sm:px-6 py-12">
        <div class="mb-8">
           <.link
              navigate={~p"/portal"}
              class="inline-flex items-center gap-2 text-sm font-bold text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white transition-colors mb-4"
            >
              <.icon name="hero-arrow-left" class="size-4" />
              Back to Dashboard
            </.link>
            <h1 class="text-3xl font-black text-zinc-900 dark:text-white tracking-tight">Service History</h1>
            <p class="text-zinc-500 dark:text-zinc-400 mt-1">Review all your past services with {@customer.organization.name}.</p>
        </div>

        <%= if Enum.empty?(@completed_jobs) do %>
          <div class="bg-white dark:bg-zinc-900 rounded-3xl border border-zinc-200 dark:border-zinc-800 p-12 text-center shadow-sm">
            <div class="size-20 mx-auto mb-6 rounded-3xl bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center">
              <.icon name="hero-clock" class="size-10 text-zinc-300 dark:text-zinc-600" />
            </div>
            <h3 class="text-xl font-bold text-zinc-900 dark:text-white mb-2">No service history</h3>
            <p class="text-zinc-500 max-w-sm mx-auto">
              Your completed services will appear here once they are finished.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for job <- @completed_jobs do %>
              <.link
                navigate={~p"/portal/jobs/#{job}"}
                class="block bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6 hover:border-primary/50 dark:hover:border-primary/50 transition-all shadow-sm group hover:shadow-md"
              >
                <div class="flex items-start justify-between gap-4">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-3 mb-2">
                       <span class="px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border bg-teal-50 text-teal-600 border-teal-100 dark:bg-teal-500/10 dark:text-teal-400 dark:border-teal-500/20">
                         Completed
                       </span>
                       <span class="text-xs text-zinc-400 font-mono">#{job.number}</span>
                    </div>
                    <h3 class="text-lg font-bold text-zinc-900 dark:text-white group-hover:text-primary transition-colors truncate mb-1">
                      {job.title}
                    </h3>
                    <div class="flex items-center gap-4 text-sm text-zinc-500 dark:text-zinc-400">
                      <div class="flex items-center gap-1.5">
                        <.icon name="hero-calendar" class="size-4" />
                        <%= if job.completed_at do %>
                          {Calendar.strftime(job.completed_at, "%B %d, %Y")}
                        <% else %>
                          {Calendar.strftime(job.inserted_at, "%B %d, %Y")}
                        <% end %>
                      </div>
                      <%= if job.technician do %>
                        <div class="flex items-center gap-1.5">
                          <.icon name="hero-user" class="size-4" />
                          {job.technician.name}
                        </div>
                      <% end %>
                    </div>
                  </div>
                  <div class="flex flex-col items-end justify-center h-full">
                     <.icon
                      name="hero-chevron-right"
                      class="size-5 text-zinc-300 dark:text-zinc-700 group-hover:text-primary group-hover:translate-x-1 transition-all"
                    />
                  </div>
                </div>
              </.link>
            <% end %>
          </div>
        <% end %>

        <div class="mt-8 text-center border-t border-zinc-100 dark:border-zinc-800 pt-8">
          <p class="text-xs font-medium text-zinc-400 uppercase tracking-widest">
            Showing last {length(@completed_jobs)} services
          </p>
        </div>
      </main>
    </div>
    """
  end
end
