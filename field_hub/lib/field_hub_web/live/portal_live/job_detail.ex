defmodule FieldHubWeb.PortalLive.JobDetail do
  @moduledoc """
  Customer portal job detail view with real-time status updates.
  """
  use FieldHubWeb, :live_view

  import Ecto.Query

  alias FieldHub.Repo
  alias FieldHub.Jobs.Job

  @impl true
  def mount(%{"number" => number}, _session, socket) do
    customer = socket.assigns.portal_customer

    case get_job_for_customer(number, customer.id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Job not found")
         |> push_navigate(to: ~p"/portal")}

      job ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(FieldHub.PubSub, "job:#{job.id}")
        end

        {:ok,
         socket
         |> assign(:job, job)
         |> assign(:customer, customer)
         |> assign(:page_title, job.title)}
    end
  end

  defp get_job_for_customer(job_number, customer_id) do
    Job
    |> where([j], j.number == ^job_number)
    |> where([j], j.customer_id == ^customer_id)
    |> Repo.one()
    |> case do
      nil -> nil
      job -> Repo.preload(job, [:technician, :customer])
    end
  end

  @impl true
  def handle_info({:job_updated, job}, socket) do
    job = Repo.preload(job, [:technician, :customer], force: true)
    socket = assign(socket, :job, job)

    if job.status == "en_route" do
      {:noreply, push_map_update(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:job_location_updated, location}, socket) do
    # Update tech location in assigns broadly or just push event
    # We update the technician inside the job struct in assigns to keep state consistent
    technician = socket.assigns.job.technician

    updated_tech = %{technician | current_lat: location.lat, current_lng: location.lng}
    updated_job = %{socket.assigns.job | technician: updated_tech}

    socket = assign(socket, :job, updated_job)

    {:noreply, push_map_update(socket)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp push_map_update(socket) do
    job = socket.assigns.job

    if job.technician && job.service_lat && job.service_lng do
      push_event(socket, "update_map_data", %{
        technicians: [serialize_tech(job.technician)],
        jobs: [serialize_job(job)]
      })
    else
      socket
    end
  end

  defp serialize_tech(tech) do
    %{
      id: tech.id,
      name: tech.name,
      status: tech.status,
      current_lat: tech.current_lat,
      current_lng: tech.current_lng,
      color: tech.calendar_color || "#099268"
    }
  end

  defp serialize_job(job) do
    %{
      id: job.id,
      number: job.number,
      title: job.title,
      service_lat: job.service_lat,
      service_lng: job.service_lng
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950">
      <main class="max-w-4xl mx-auto px-4 sm:px-6 py-12 space-y-8">
        <%!-- Header Section --%>
        <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-6">
          <div>
            <.link
              navigate={~p"/portal"}
              class="inline-flex items-center gap-2 text-sm font-bold text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white transition-colors mb-4"
            >
              <.icon name="hero-arrow-left" class="size-4" /> Back to Dashboard
            </.link>
            <div class="flex items-center gap-3 mb-1">
              <span class="px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400">
                Job {@job.number}
              </span>
              <%= if @job.status == "en_route" do %>
                <span class="relative flex h-2.5 w-2.5">
                  <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75">
                  </span>
                  <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-primary"></span>
                </span>
              <% end %>
            </div>
            <h1 class="text-3xl font-black text-zinc-900 dark:text-white tracking-tight">
              {@job.title}
            </h1>
          </div>
        </div>
        <%!-- Status Timeline --%>
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-8">
          <div class="relative">
            <%!-- Background line --%>
            <div class="absolute top-5 left-0 w-full h-0.5 bg-zinc-100 dark:bg-zinc-800" />

            <div class="relative flex justify-between">
              <%= for {status, label, icon} <- timeline_steps() do %>
                <div class="flex flex-col items-center gap-3">
                  <div class={[
                    "size-10 rounded-full flex items-center justify-center z-10 transition-colors duration-500",
                    if(status_is_reached?(@job.status, status),
                      do: "bg-primary text-white",
                      else:
                        "bg-white dark:bg-zinc-900 border-2 border-zinc-100 dark:border-zinc-800 text-zinc-300 dark:text-zinc-600"
                    )
                  ]}>
                    <.icon name={icon} class="size-5" />
                  </div>
                  <span class={[
                    "text-[10px] font-bold uppercase tracking-wider",
                    if(status_is_reached?(@job.status, status),
                      do: "text-zinc-900 dark:text-white",
                      else: "text-zinc-400"
                    )
                  ]}>
                    {label}
                  </span>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <%= if @job.status == "en_route" and @job.technician && @job.service_lat && @job.service_lng do %>
          <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden shadow-sm">
            <div class="p-4 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between bg-zinc-50/50 dark:bg-zinc-800/20">
              <h3 class="text-sm font-bold text-zinc-900 dark:text-white flex items-center gap-2">
                <.icon name="hero-map" class="size-4 text-primary" /> Live Technician Tracking
              </h3>
              <span class="relative flex h-2.5 w-2.5">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75">
                </span>
                <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-primary"></span>
              </span>
            </div>
            <div
              id="live-map"
              phx-hook="Map"
              class="w-full h-64 z-0"
              data-lat={@job.service_lat}
              data-lng={@job.service_lng}
              data-technicians={Jason.encode!([serialize_tech(@job.technician)])}
              data-jobs={Jason.encode!([serialize_job(@job)])}
              phx-update="ignore"
            >
            </div>
          </div>
        <% end %>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="md:col-span-2 space-y-6">
            <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6 space-y-6">
              <div>
                <h3 class="text-sm font-bold text-zinc-400 uppercase tracking-wider mb-2">
                  Description
                </h3>
                <p class="text-zinc-700 dark:text-zinc-300">
                  {@job.description || "No description provided."}
                </p>
              </div>

              <%= if @job.status == "completed" and @job.work_performed do %>
                <div class="pt-6 border-t border-zinc-100 dark:border-zinc-800">
                  <h3 class="text-sm font-bold text-zinc-400 uppercase tracking-wider mb-2">
                    Work Performed
                  </h3>
                  <div class="prose prose-sm dark:prose-invert max-w-none whitespace-pre-wrap text-zinc-700 dark:text-zinc-300">
                    {@job.work_performed}
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="space-y-6">
            <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6">
              <h3 class="text-sm font-bold text-zinc-400 uppercase tracking-wider mb-4">
                Service Info
              </h3>

              <div class="space-y-4">
                <div>
                  <label class="block text-xs text-zinc-500 mb-1">Scheduled Date</label>
                  <p class="text-sm font-bold text-zinc-900 dark:text-white">
                    <%= if @job.scheduled_date do %>
                      {Calendar.strftime(@job.scheduled_date, "%B %d, %Y")}
                    <% else %>
                      To be scheduled
                    <% end %>
                  </p>
                </div>

                <div>
                  <label class="block text-xs text-zinc-500 mb-1">Technician</label>
                  <p class="text-sm font-bold text-zinc-900 dark:text-white">
                    <%= if @job.technician do %>
                      {@job.technician.name}
                    <% else %>
                      Pending assignment
                    <% end %>
                  </p>
                </div>

                <%= if @job.technician && @job.status == "en_route" do %>
                  <div class="mt-4 p-3 rounded-xl bg-primary/5 border border-primary/10">
                    <p class="text-xs text-primary font-medium flex items-center gap-2">
                      <.icon name="hero-truck" class="size-4" /> Technician is on the way!
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  defp timeline_steps do
    [
      {"pending", "Scheduled", "hero-calendar"},
      {"en_route", "En Route", "hero-truck"},
      {"arrived", "Arrived", "hero-user-circle"},
      {"in_progress", "Working", "hero-wrench-screwdriver"},
      {"completed", "Done", "hero-check-circle"}
    ]
  end

  defp status_is_reached?(current_status, step_status) do
    order = ["pending", "en_route", "arrived", "in_progress", "completed"]
    current_idx = Enum.find_index(order, &(&1 == current_status)) || 0
    step_idx = Enum.find_index(order, &(&1 == step_status)) || 0
    current_idx >= step_idx
  end
end
