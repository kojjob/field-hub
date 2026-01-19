defmodule FieldHubWeb.PortalLive.Dashboard do
  @moduledoc """
  Customer portal dashboard showing active jobs and service history.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs

  @impl true
  def mount(_params, _session, socket) do
    customer = socket.assigns.portal_customer

    if connected?(socket) do
      Phoenix.PubSub.subscribe(FieldHub.PubSub, "customer:#{customer.id}")
    end

    active_jobs = Jobs.list_active_jobs_for_customer(customer.id)
    completed_jobs = Jobs.list_completed_jobs_for_customer(customer.id, limit: 5)

    socket =
      socket
      |> assign(:customer, customer)
      |> assign(:active_jobs, active_jobs)
      |> assign(:completed_jobs, completed_jobs)
      |> assign(:page_title, "Your Jobs")

    {:ok, socket}
  end

  @impl true
  def handle_info({:job_updated, _job}, socket) do
    customer = socket.assigns.customer
    active_jobs = Jobs.list_active_jobs_for_customer(customer.id)
    completed_jobs = Jobs.list_completed_jobs_for_customer(customer.id, limit: 5)

    {:noreply,
     socket
     |> assign(:active_jobs, active_jobs)
     |> assign(:completed_jobs, completed_jobs)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950">
      <header class="bg-white dark:bg-zinc-900 border-b border-zinc-200 dark:border-zinc-800 sticky top-0 z-50">
        <div class="max-w-4xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="size-10 rounded-xl bg-primary flex items-center justify-center text-white font-black text-xl">
              {String.at(@customer.organization.name, 0)}
            </div>
            <div>
              <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em]">
                {@customer.organization.name}
              </p>
              <h1 class="text-lg font-bold text-zinc-900 dark:text-white">
                Welcome, {@customer.name}
              </h1>
            </div>
          </div>
          <.link
            href={~p"/portal/logout"}
            method="delete"
            class="size-10 rounded-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center text-zinc-600 dark:text-zinc-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
            title="Log out"
          >
            <.icon name="hero-arrow-right-on-rectangle" class="size-5" />
          </.link>
        </div>
      </header>

      <main class="max-w-4xl mx-auto px-4 sm:px-6 py-8 space-y-10">
        <section>
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-3">
              <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center">
                <.icon name="hero-bolt" class="size-5 text-primary" />
              </div>
              <div>
                <h2 class="text-lg font-bold text-zinc-900 dark:text-white">Active Jobs</h2>
                <p class="text-xs text-zinc-500">Your upcoming and in-progress services</p>
              </div>
            </div>
          </div>

          <%= if Enum.empty?(@active_jobs) do %>
            <div class="bg-white dark:bg-zinc-900 rounded-3xl border border-zinc-200 dark:border-zinc-800 p-12 text-center">
              <div class="size-20 mx-auto mb-6 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
                <.icon name="hero-calendar" class="size-10 text-zinc-300 dark:text-zinc-700" />
              </div>
              <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2">No active jobs</h3>
              <p class="text-zinc-500 max-w-xs mx-auto text-sm">
                When you have a scheduled or active service, it will appear here.
              </p>
            </div>
          <% else %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= for job <- @active_jobs do %>
                <.link
                  navigate={~p"/portal/jobs/#{job.id}"}
                  class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-5 hover:border-primary/50 transition-all group"
                >
                  <div class="flex items-start justify-between mb-4">
                    <span class={[
                      "px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider",
                      status_color_classes(job.status)
                    ]}>
                      {String.replace(job.status, "_", " ")}
                    </span>
                    <.icon name="hero-chevron-right" class="size-4 text-zinc-300 group-hover:translate-x-1 transition-transform" />
                  </div>
                  <h3 class="font-bold text-zinc-900 dark:text-white mb-1 group-hover:text-primary transition-colors">
                    {job.title}
                  </h3>
                  <div class="space-y-2 mt-4">
                    <div class="flex items-center gap-2 text-xs text-zinc-500">
                      <.icon name="hero-calendar" class="size-4" />
                      {Calendar.strftime(job.scheduled_date, "%b %d, %Y")}
                    </div>
                    <%= if job.technician do %>
                      <div class="flex items-center gap-2 text-xs text-zinc-500">
                        <.icon name="hero-user" class="size-4" />
                        Tech: {job.technician.name}
                      </div>
                    <% end %>
                  </div>
                </.link>
              <% end %>
            </div>
          <% end %>
        </section>

        <section>
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-lg font-bold text-zinc-900 dark:text-white">Recent Completed</h2>
            <.link navigate={~p"/portal/history"} class="text-xs font-bold text-primary hover:underline">
              View All History
            </.link>
          </div>

          <%= if Enum.empty?(@completed_jobs) do %>
            <p class="text-zinc-500 text-sm">No service history yet.</p>
          <% else %>
            <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 divide-y divide-zinc-100 dark:divide-zinc-800">
              <%= for job <- @completed_jobs do %>
                <.link
                  navigate={~p"/portal/jobs/#{job.id}"}
                  class="p-4 flex items-center justify-between hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
                >
                  <div class="min-w-0 flex-1">
                    <p class="font-bold text-zinc-900 dark:text-white truncate">{job.title}</p>
                    <p class="text-xs text-zinc-500 mt-1">
                       {Calendar.strftime(job.completed_at, "%b %d, %Y")}
                       <%= if job.technician do %>
                        • {job.technician.name}
                       <% end %>
                    </p>
                  </div>
                  <.icon name="hero-chevron-right" class="size-4 text-zinc-300" />
                </.link>
              <% end %>
            </div>
          <% end %>
        </section>
      </main>
    </div>
    """
  end

  defp status_color_classes("pending"), do: "bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400"
  defp status_color_classes("en_route"), do: "bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400"
  defp status_color_classes("arrived"), do: "bg-indigo-100 text-indigo-600 dark:bg-indigo-900/30 dark:text-indigo-400"
  defp status_color_classes("in_progress"), do: "bg-primary/10 text-primary"
  defp status_color_classes("completed"), do: "bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400"
  defp status_color_classes(_), do: "bg-zinc-100 text-zinc-600"

end
