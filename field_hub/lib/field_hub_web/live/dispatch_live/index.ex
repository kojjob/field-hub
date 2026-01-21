defmodule FieldHubWeb.DispatchLive.Index do
  @moduledoc """
  Dispatch Board LiveView - Calendar view for job scheduling and technician management.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs
  alias FieldHub.Dispatch
  alias FieldHub.Dispatch.Broadcaster
  alias FieldHubWeb.Components.DispatchMap
  import Ecto.Query
  alias FieldHub.Repo

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    current_organization = FieldHub.Accounts.get_organization!(user.organization_id)

    if connected?(socket) do
      Broadcaster.subscribe_to_org(current_organization.id)
    end

    today = Date.utc_today()

    socket =
      socket
      |> assign(:current_organization, current_organization)
      |> assign(:current_nav, :dispatch)
      |> assign(:current_user, user)
      |> assign(:selected_date, today)
      |> assign(:view_mode, :day)
      |> assign(:selected_job, nil)
      |> assign(:technician_filter, nil)
      |> load_data()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :page_title, "Dispatch Board")}
  end

  defp load_data(socket) do
    org_id = socket.assigns.current_organization.id
    selected_date = socket.assigns.selected_date
    tech_filter_id = socket.assigns.technician_filter

    # Load technicians with active jobs
    base_query =
      Dispatch.list_technicians(org_id)
      |> Repo.preload(
        jobs:
          from(j in FieldHub.Jobs.Job,
            where: j.status == "in_progress",
            order_by: [desc: j.updated_at],
            limit: 1,
            preload: [:customer]
          )
      )

    technicians =
      if tech_filter_id do
        Enum.filter(base_query, fn t -> t.id == tech_filter_id end)
      else
        base_query
      end

    # Load scheduled jobs for the selected date
    scheduled_jobs = Jobs.list_jobs_for_date(org_id, selected_date)

    # Prepare map data
    map_technicians =
      Enum.map(technicians, fn t ->
        %{
          id: t.id,
          name: t.name,
          status: t.status,
          color: t.color,
          current_lat: t.current_lat,
          current_lng: t.current_lng
        }
      end)

    map_jobs =
      Enum.map(scheduled_jobs, fn j ->
        %{
          id: j.id,
          number: j.number,
          title: j.title,
          status: j.status,
          service_lat: j.service_lat,
          service_lng: j.service_lng
        }
      end)

    # Pre-process jobs into a map for fast lookup
    scheduled_jobs_by_slot =
      Enum.group_by(scheduled_jobs, fn job ->
        {job.technician_id, job.scheduled_start && job.scheduled_start.hour}
      end)

    # Load unassigned jobs (no technician or no scheduled date)
    unassigned_jobs = Jobs.list_unassigned_jobs(org_id)
    unassigned_jobs_count = length(unassigned_jobs)

    socket =
      socket
      |> stream(:unassigned_jobs, unassigned_jobs, reset: true)
      |> assign(:unassigned_jobs_count, unassigned_jobs_count)
      |> assign(:technicians, technicians)
      |> assign(:scheduled_jobs, scheduled_jobs)
      |> assign(:scheduled_jobs_by_slot, scheduled_jobs_by_slot)
      |> assign(:map_technicians, map_technicians)
      |> assign(:map_jobs, map_jobs)
      |> assign(:time_slots, time_slots())

    if socket.assigns.view_mode == :map do
      push_event(socket, "update_map_data", %{technicians: map_technicians, jobs: map_jobs})
    else
      socket
    end
  end

  @impl true
  def handle_event("prev_day", _params, socket) do
    new_date = Date.add(socket.assigns.selected_date, -1)
    socket = socket |> assign(:selected_date, new_date) |> load_data()
    {:noreply, socket}
  end

  @impl true
  def handle_event("next_day", _params, socket) do
    new_date = Date.add(socket.assigns.selected_date, 1)
    socket = socket |> assign(:selected_date, new_date) |> load_data()
    {:noreply, socket}
  end

  @impl true
  def handle_event("today", _params, socket) do
    socket = socket |> assign(:selected_date, Date.utc_today()) |> load_data()
    {:noreply, socket}
  end

  @impl true
  def handle_event("set_view_mode", %{"mode" => mode}, socket) do
    # Pure LiveView - no JavaScript hooks needed!
    {:noreply, assign(socket, :view_mode, String.to_existing_atom(mode))}
  end

  @impl true
  def handle_event(
        "assign_job",
        %{"job_id" => job_id, "technician_id" => tech_id} = params,
        socket
      ) do
    org_id = socket.assigns.current_organization.id
    job = Jobs.get_job!(org_id, job_id)

    # Build update params
    update_params = %{
      "technician_id" => tech_id,
      "scheduled_date" => Date.to_string(socket.assigns.selected_date)
    }

    # Add scheduled time if hour is provided
    update_params =
      if params["hour"] do
        hour_val = params["hour"]
        hour = if is_integer(hour_val), do: hour_val, else: String.to_integer(hour_val)
        Map.put(update_params, "scheduled_start", Time.new!(hour, 0, 0) |> Time.to_string())
      else
        update_params
      end

    case Jobs.update_job(job, update_params) do
      {:ok, _updated_job} ->
        {:noreply, socket |> put_flash(:info, "Job assigned successfully") |> load_data()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to assign job")}
    end
  end

  @impl true
  def handle_event(
        "assign_job_from_select",
        %{"job_id" => job_id, "technician_id" => tech_id},
        socket
      ) do
    org_id = socket.assigns.current_organization.id
    job = Jobs.get_job!(org_id, job_id)

    # Handle empty string as unassign
    tech_id_val = if tech_id == "", do: nil, else: tech_id

    update_params = %{
      "technician_id" => tech_id_val,
      "scheduled_date" =>
        if(tech_id_val, do: Date.to_string(socket.assigns.selected_date), else: nil)
    }

    case Jobs.update_job(job, update_params) do
      {:ok, updated_job} ->
        # Reload job with preloads for the slideout
        updated_job =
          Jobs.get_job!(org_id, updated_job.id) |> FieldHub.Repo.preload([:customer, :technician])

        message = if tech_id_val, do: "Job assigned successfully", else: "Job unassigned"

        {:noreply,
         socket |> assign(:selected_job, updated_job) |> put_flash(:info, message) |> load_data()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update assignment")}
    end
  end

  @impl true
  def handle_event("unassign_job", %{"job_id" => job_id}, socket) do
    org_id = socket.assigns.current_organization.id
    job = Jobs.get_job!(org_id, job_id)

    case Jobs.update_job(job, %{
           "technician_id" => nil,
           "scheduled_date" => nil,
           "scheduled_start" => nil
         }) do
      {:ok, _updated_job} ->
        {:noreply, socket |> put_flash(:info, "Job unassigned") |> load_data()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to unassign job")}
    end
  end

  @impl true
  def handle_event("change_status", %{"job_id" => job_id, "status" => status}, socket) do
    org_id = socket.assigns.current_organization.id
    job = Jobs.get_job!(org_id, job_id)

    case Jobs.update_job(job, %{"status" => status}) do
      {:ok, _updated_job} ->
        {:noreply, socket |> put_flash(:info, "Status updated to #{status}") |> load_data()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update status")}
    end
  end

  @impl true
  def handle_event("quick_dispatch", %{"job_id" => job_id}, socket) do
    org_id = socket.assigns.current_organization.id
    job = Jobs.get_job!(org_id, job_id)

    # Find first available technician
    available_tech =
      Dispatch.list_technicians(org_id)
      |> Enum.find(fn t -> t.status == "available" end)

    case available_tech do
      nil ->
        {:noreply, put_flash(socket, :error, "No available technicians")}

      tech ->
        update_params = %{
          "technician_id" => tech.id,
          "scheduled_date" => Date.to_string(socket.assigns.selected_date),
          "status" => "scheduled"
        }

        case Jobs.update_job(job, update_params) do
          {:ok, _updated_job} ->
            {:noreply,
             socket |> put_flash(:info, "Job dispatched to #{tech.name}") |> load_data()}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to dispatch job")}
        end
    end
  end

  @impl true
  def handle_event("show_job_details", %{"job_id" => job_id}, socket) do
    org_id = socket.assigns.current_organization.id
    job = Jobs.get_job!(org_id, job_id) |> FieldHub.Repo.preload([:customer, :technician])

    {:noreply, assign(socket, :selected_job, job)}
  end

  @impl true
  def handle_event(
        "update_tech_status",
        %{"technician_id" => tech_id, "status" => status},
        socket
      ) do
    org_id = socket.assigns.current_organization.id
    technician = Dispatch.get_technician!(org_id, tech_id)

    case Dispatch.update_technician(technician, %{status: status}) do
      {:ok, _tech} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update status")}
    end
  end

  @impl true
  def handle_event("view_tech_schedule", %{"tech_id" => tech_id}, socket) do
    {:noreply,
     socket
     |> assign(:technician_filter, String.to_integer(tech_id))
     |> load_data()}
  end

  @impl true
  def handle_event("clear_tech_filter", _params, socket) do
    {:noreply,
     socket
     |> assign(:technician_filter, nil)
     |> load_data()}
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    case key do
      "n" -> {:noreply, push_navigate(socket, to: ~p"/jobs/new")}
      "Escape" -> handle_event("close_job_details", nil, socket)
      "ArrowLeft" -> handle_event("prev_day", nil, socket)
      "ArrowRight" -> handle_event("next_day", nil, socket)
      "t" -> handle_event("today", nil, socket)
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_job_details", _params, socket) do
    {:noreply, assign(socket, :selected_job, nil)}
  end

  @impl true
  def handle_info({:job_created, _job}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info({:job_updated, _job}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info({:technician_updated, _tech}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  # Time slot helpers
  defp time_slots do
    # Generate time slots from 7am to 7pm
    for hour <- 7..19 do
      %{
        hour: hour,
        label: format_hour(hour),
        time: Time.new!(hour, 0, 0)
      }
    end
  end

  defp format_hour(hour) when hour < 12, do: "#{hour}:00 AM"
  defp format_hour(12), do: "12:00 PM"
  defp format_hour(hour), do: "#{hour - 12}:00 PM"

  defp format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  defp format_day_of_week(date) do
    Calendar.strftime(date, "%A")
  end

  defp jobs_for_technician_at_hour(jobs_map, technician_id, hour) do
    Map.get(jobs_map, {technician_id, hour}, [])
  end

  defp job_duration_class(job) do
    duration = job.estimated_duration_minutes || 60

    cond do
      duration <= 30 -> "h-8"
      duration <= 60 -> "h-16"
      duration <= 90 -> "h-24"
      duration <= 120 -> "h-32"
      true -> "h-40"
    end
  end

  defp status_color(status) do
    case status do
      "unscheduled" ->
        "bg-zinc-100 border-zinc-200 dark:bg-zinc-800 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400"

      "scheduled" ->
        "bg-teal-50 border-teal-200 dark:bg-teal-900/30 dark:border-teal-800/50 text-teal-700 dark:text-teal-300"

      "en_route" ->
        "bg-amber-50 border-amber-200 dark:bg-amber-900/30 dark:border-amber-800/50 text-amber-700 dark:text-amber-300"

      "on_site" ->
        "bg-purple-50 border-purple-200 dark:bg-purple-900/30 dark:border-purple-800/50 text-purple-700 dark:text-purple-300"

      "in_progress" ->
        "bg-blue-50 border-blue-200 dark:bg-blue-900/30 dark:border-blue-800/50 text-blue-700 dark:text-blue-300"

      "completed" ->
        "bg-emerald-50 border-emerald-200 dark:bg-emerald-900/30 dark:border-emerald-800/50 text-emerald-700 dark:text-emerald-300"

      "cancelled" ->
        "bg-red-50 border-red-200 dark:bg-red-900/30 dark:border-red-800/50 text-red-700 dark:text-red-300"

      _ ->
        "bg-zinc-100 border-zinc-200 dark:bg-zinc-800 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400"
    end
  end

  defp priority_indicator(priority) do
    case priority do
      "urgent" -> "border-l-4 border-l-red-500"
      "high" -> "border-l-4 border-l-amber-500"
      "normal" -> "border-l-4 border-l-teal-500"
      "low" -> "border-l-4 border-l-zinc-300 dark:border-l-zinc-600"
      _ -> ""
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-[calc(100vh-140px)] flex flex-col" phx-window-keydown="keydown">
      <div class="flex items-center justify-between mb-4">
        <div>
          <p class="text-sm text-zinc-500 dark:text-zinc-400 font-bold">
            {format_day_of_week(@selected_date)}, {format_date(@selected_date)}
          </p>
        </div>

        <div class="flex items-center gap-4">
          <!-- View Toggle -->
          <div class="flex rounded-xl bg-zinc-100 dark:bg-zinc-800 p-1 border border-zinc-200 dark:border-zinc-700">
            <button
              phx-click="set_view_mode"
              phx-value-mode="day"
              class={[
                "px-4 py-1.5 text-xs font-black rounded-lg transition-all",
                @view_mode == :day && "bg-white dark:bg-zinc-700 text-primary shadow-sm",
                @view_mode != :day && "text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300"
              ]}
            >
              Day
            </button>
            <button
              phx-click="set_view_mode"
              phx-value-mode="map"
              class={[
                "px-4 py-1.5 text-xs font-black rounded-lg transition-all",
                @view_mode == :map && "bg-white dark:bg-zinc-700 text-primary shadow-sm",
                @view_mode != :map && "text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300"
              ]}
            >
              Map
            </button>
          </div>
          
    <!-- Date Navigation -->
          <div class="flex items-center gap-2">
            <button
              phx-click="prev_day"
              class="p-2 rounded-xl border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-800 text-zinc-500 transition-colors"
            >
              <.icon name="hero-chevron-left" class="size-5" />
            </button>
            <button
              phx-click="today"
              class="px-4 py-2 text-xs font-black border border-zinc-200 dark:border-zinc-700 rounded-xl hover:bg-zinc-50 dark:hover:bg-zinc-800 text-zinc-700 dark:text-zinc-300 transition-colors"
            >
              Today
            </button>
            <button
              phx-click="next_day"
              class="p-2 rounded-xl border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-800 text-zinc-500 transition-colors"
            >
              <.icon name="hero-chevron-right" class="size-5" />
            </button>
          </div>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="flex-1 flex overflow-hidden rounded-[24px] border border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 shadow-sm">
        <!-- Unassigned Jobs Sidebar -->
        <div class="w-72 bg-zinc-50 dark:bg-zinc-900/50 border-r border-zinc-200 dark:border-zinc-800 overflow-y-auto p-4">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-xs font-black text-zinc-900 dark:text-white uppercase tracking-widest flex items-center gap-2">
              Unassigned
              <span class="bg-primary text-white px-2 py-0.5 rounded-lg text-[10px] font-bold">
                {@unassigned_jobs_count}
              </span>
            </h2>
          </div>

          <%= if @unassigned_jobs_count == 0 do %>
            <div
              id="unassigned-jobs-empty"
              class="text-sm text-zinc-400 dark:text-zinc-500 text-center py-10 italic"
            >
              No unassigned jobs
            </div>
          <% else %>
            <div
              id="unassigned-jobs"
              class="space-y-3"
              phx-hook="DragDrop"
              data-group="jobs"
              data-type="source"
              phx-update="stream"
            >
              <%= for {dom_id, job} <- @streams.unassigned_jobs do %>
                <div
                  id={dom_id}
                  class={"drag-handle group p-3 bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm cursor-grab hover:shadow-md hover:border-primary/30 transition-all #{priority_indicator(job.priority)}"}
                  data-job-id={job.id}
                >
                  <div class="flex items-start justify-between gap-2">
                    <div class="flex-1 min-w-0" phx-click="show_job_details" phx-value-job_id={job.id}>
                      <div class="font-bold text-sm text-zinc-900 dark:text-white truncate group-hover:text-primary transition-colors">
                        {job.title}
                      </div>
                      <div class="text-[11px] text-zinc-500 dark:text-zinc-400 font-medium truncate">
                        {if job.customer, do: job.customer.name, else: "No Customer"}
                      </div>
                    </div>
                    <button
                      phx-click="quick_dispatch"
                      phx-value-job_id={job.id}
                      class="shrink-0 p-1.5 rounded-lg hover:bg-primary/10 dark:hover:bg-primary/20 text-primary transition-colors"
                      title="Quick dispatch"
                    >
                      <.icon name="hero-bolt" class="size-4" />
                    </button>
                  </div>
                  <div class="mt-3 flex items-center justify-between">
                    <div class="flex items-center gap-1.5">
                      <span class={"inline-block w-1.5 h-1.5 rounded-full #{if job.priority == "urgent", do: "bg-red-500", else: "bg-zinc-400"}"}>
                      </span>
                      <span class="text-[10px] font-bold text-zinc-400 uppercase tracking-wider">
                        {job.priority}
                      </span>
                    </div>
                    <span class="text-[10px] font-bold text-zinc-400">
                      #{"#{job.id}" |> String.slice(-4..-1)}
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Calendar Grid or Map -->
        <div class="flex-1 overflow-auto relative bg-zinc-50/50 dark:bg-zinc-900/50 scrollbar-hide">
          <%= if @view_mode == :map do %>
            <!-- Pure LiveView Map Component - No JavaScript hooks needed! -->
            <DispatchMap.render
              technicians={@map_technicians}
              jobs={@map_jobs}
              class="absolute inset-0"
            />
          <% else %>
            <div class="min-w-max">
              <!-- Technician Headers -->
              <div class="flex sticky top-0 bg-white dark:bg-zinc-900 z-20 border-b border-zinc-200 dark:border-zinc-800">
                <div class="w-20 shrink-0 border-r border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-800/50">
                </div>
                <%= for tech <- @technicians do %>
                  <div class="w-56 shrink-0 border-r border-zinc-200 dark:border-zinc-800 p-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="size-8 rounded-full flex items-center justify-center text-white text-[10px] font-black shadow-lg shadow-primary/10"
                        style={"background-color: #{tech.color}"}
                      >
                        {initials(tech.name)}
                      </div>
                      <div>
                        <span class="font-bold text-sm text-zinc-900 dark:text-white block truncate">
                          {tech.name}
                        </span>
                        <div class="flex items-center gap-1.5 mt-0.5">
                          <div class={"size-1.5 rounded-full #{tech_status_dot(tech.status)}"}></div>
                          <span class="text-[10px] font-bold text-zinc-400 uppercase tracking-widest">
                            {String.replace(tech.status, "_", " ")}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
              
    <!-- Time Slots -->
              <%= for slot <- time_slots() do %>
                <div class="flex border-b border-zinc-100 dark:border-zinc-800 group hover:bg-zinc-50 dark:hover:bg-zinc-800/20 transition-colors">
                  <!-- Time Label -->
                  <div class="w-20 shrink-0 border-r border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-800/50 p-4 text-[10px] font-black text-zinc-400 text-right sticky left-0 z-10">
                    {slot.label}
                  </div>
                  
    <!-- Technician Columns -->
                  <%= for tech <- @technicians do %>
                    <div
                      id={"slot-#{tech.id}-#{slot.hour}"}
                      class="w-56 shrink-0 border-r border-zinc-100 dark:border-zinc-800 p-2 min-h-[80px] relative transition-colors group-hover:bg-white/50 dark:group-hover:bg-zinc-800/40"
                      phx-hook="DragDrop"
                      data-group="jobs"
                      data-type="target"
                      data-technician-id={tech.id}
                      data-hour={slot.hour}
                    >
                      <%= for job <- jobs_for_technician_at_hour(@scheduled_jobs_by_slot, tech.id, slot.hour) do %>
                        <div
                          class={"drag-handle #{job_duration_class(job)} #{status_color(job.status)} #{priority_indicator(job.priority)} w-full rounded-xl p-2 border shadow-sm cursor-grab hover:shadow-md transition-all active:scale-95 z-10"}
                          data-job-id={job.id}
                          phx-click="show_job_details"
                          phx-value-job_id={job.id}
                        >
                          <div class="font-bold truncate text-[13px]">{job.title}</div>
                          <div class="opacity-70 truncate text-[11px] font-medium mt-0.5">
                            {if job.customer, do: job.customer.name, else: "No Customer"}
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Technician Status Sidebar (Right) -->
        <div class="w-80 bg-white dark:bg-zinc-900 border-l border-zinc-200 dark:border-zinc-800 flex flex-col shrink-0">
          <div class="p-5 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between bg-zinc-50/50 dark:bg-zinc-800/30">
            <h2 class="text-xs font-black text-zinc-900 dark:text-white uppercase tracking-widest">
              Team Availability
            </h2>
            <%= if @technician_filter do %>
              <button
                phx-click="clear_tech_filter"
                class="text-[10px] font-black text-primary hover:text-primary/80 uppercase tracking-widest"
              >
                Clear
              </button>
            <% end %>
          </div>
          <div class="flex-1 overflow-y-auto p-4 space-y-4">
            <%= for tech <- @technicians do %>
              <div
                class={"group bg-white dark:bg-zinc-800 rounded-[20px] p-4 border border-zinc-200 dark:border-zinc-700 hover:border-primary/30 cursor-pointer transition-all shadow-sm hover:shadow-md #{if @technician_filter == tech.id, do: "ring-2 ring-primary ring-offset-2 dark:ring-offset-zinc-900"}"}
                phx-click="view_tech_schedule"
                phx-value-tech_id={tech.id}
              >
                <div class="flex items-center gap-4 mb-3">
                  <div
                    class="size-10 rounded-full flex items-center justify-center text-white text-xs font-black shadow-lg shadow-primary/10"
                    style={"background-color: #{tech.color}"}
                  >
                    {initials(tech.name)}
                  </div>
                  <div>
                    <div class="font-bold text-sm text-zinc-900 dark:text-white group-hover:text-primary transition-colors">
                      {tech.name}
                    </div>
                    <div class="flex items-center gap-2 mt-1">
                      <div class={"size-1.5 rounded-full #{tech_status_dot(tech.status)}"}></div>
                      <span class={"text-[10px] font-black px-2 py-0.5 rounded-lg uppercase tracking-wider #{tech_status_color(tech.status)}"}>
                        {String.replace(tech.status, "_", " ")}
                      </span>
                    </div>
                  </div>
                </div>
                
    <!-- Current Active Job -->
                <%= if tech.status == "on_job" || tech.status == "traveling" do %>
                  <%= if active_job = List.first(tech.jobs) do %>
                    <div class="mt-3 text-[11px] bg-zinc-50 dark:bg-zinc-900/50 rounded-xl p-3 border border-zinc-100 dark:border-zinc-800">
                      <div class="text-zinc-400 dark:text-zinc-500 font-bold uppercase tracking-tighter mb-1">
                        Current Task
                      </div>
                      <div class="font-bold text-zinc-900 dark:text-white truncate">
                        {active_job.title}
                      </div>
                      <div class="text-zinc-500 dark:text-zinc-400 truncate mt-0.5">
                        {if active_job.customer, do: active_job.customer.name, else: "No Customer"}
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      
    <!-- Job Details Slideout Panel -->
      <%= if @selected_job do %>
        <div
          class="fixed inset-0 bg-zinc-900/40 backdrop-blur-sm z-40 transition-opacity"
          phx-click="close_job_details"
        >
        </div>
        <div class="fixed right-0 top-0 h-full w-[450px] bg-white dark:bg-zinc-900 shadow-2xl z-50 overflow-y-auto animate-in slide-in-from-right duration-300">
          <div class="p-6 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between bg-zinc-50/50 dark:bg-zinc-800/30">
            <h2 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
              Job Insights
            </h2>
            <button
              phx-click="close_job_details"
              class="p-2 rounded-xl hover:bg-zinc-100 dark:hover:bg-zinc-800 text-zinc-400 transition-colors"
            >
              <.icon name="hero-x-mark" class="size-6" />
            </button>
          </div>

          <div class="p-8 space-y-8">
            <!-- Job Title & Priority -->
            <div>
              <div class="flex items-center gap-2 mb-4">
                <span class={"px-3 py-1 rounded-lg text-[10px] font-black uppercase tracking-widest border #{priority_badge(@selected_job.priority)}"}>
                  {@selected_job.priority}
                </span>
                <span class={"px-3 py-1 rounded-lg text-[10px] font-black uppercase tracking-widest border #{status_badge(@selected_job.status)}"}>
                  {@selected_job.status}
                </span>
              </div>
              <h3 class="text-2xl font-black text-zinc-900 dark:text-white tracking-tighter leading-tight">
                {@selected_job.title}
              </h3>
              <p class="text-[14px] leading-relaxed text-zinc-500 dark:text-zinc-400 mt-3 italic">
                "{@selected_job.description}"
              </p>
            </div>

            <div class="grid grid-cols-1 gap-4">
              <!-- Customer Info -->
              <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-[24px] p-5 border border-zinc-100 dark:border-zinc-800">
                <div class="flex items-center gap-3 mb-3">
                  <div class="size-9 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
                    <.icon name="hero-user" class="size-5" />
                  </div>
                  <h4 class="text-xs font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-widest">
                    Customer
                  </h4>
                </div>
                <p class="text-lg font-bold text-zinc-900 dark:text-white">
                  {if @selected_job.customer, do: @selected_job.customer.name, else: "No Customer"}
                </p>
                <%= if @selected_job.customer && @selected_job.customer.phone do %>
                  <p class="text-sm text-zinc-500 dark:text-zinc-400 font-medium mt-1 flex items-center gap-2">
                    <.icon name="hero-phone" class="size-4" />
                    {@selected_job.customer.phone}
                  </p>
                <% end %>
              </div>
              
    <!-- Schedule Info -->
              <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-[24px] p-5 border border-zinc-100 dark:border-zinc-800">
                <div class="flex items-center gap-3 mb-3">
                  <div class="size-9 rounded-xl bg-amber-600/10 flex items-center justify-center text-amber-600">
                    <.icon name="hero-clock" class="size-5" />
                  </div>
                  <h4 class="text-xs font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-widest">
                    Schedule
                  </h4>
                </div>
                <%= if @selected_job.scheduled_date do %>
                  <p class="text-lg font-bold text-zinc-900 dark:text-white">
                    {format_date(@selected_job.scheduled_date)}
                  </p>
                  <%= if @selected_job.scheduled_start do %>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400 font-medium mt-1">
                      Expected start:
                      <span class="text-zinc-900 dark:text-white">
                        {format_time(@selected_job.scheduled_start)}
                      </span>
                    </p>
                  <% end %>
                <% else %>
                  <p class="text-zinc-500 italic font-medium">Not yet scheduled</p>
                <% end %>
              </div>
              
    <!-- Technician Info -->
              <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-[24px] p-5 border border-zinc-100 dark:border-zinc-800">
                <div class="flex items-center gap-3 mb-3">
                  <div class="size-9 rounded-xl bg-emerald-600/10 flex items-center justify-center text-emerald-600">
                    <.icon name="hero-bolt" class="size-5" />
                  </div>
                  <h4 class="text-xs font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-widest">
                    Assign Technician
                  </h4>
                </div>

                <form phx-change="assign_job_from_select" class="space-y-3">
                  <input type="hidden" name="job_id" value={@selected_job.id} />
                  <select
                    name="technician_id"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 text-sm font-bold text-zinc-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-primary transition-all"
                  >
                    <option value="">— Unassigned —</option>
                    <%= for tech <- @technicians do %>
                      <option
                        value={tech.id}
                        selected={@selected_job.technician_id == tech.id}
                      >
                        {tech.name} ({String.replace(tech.status, "_", " ")})
                      </option>
                    <% end %>
                  </select>
                </form>

                <%= if @selected_job.technician do %>
                  <div class="flex items-center gap-3 mt-3 p-3 bg-white dark:bg-zinc-900 rounded-xl border border-zinc-200 dark:border-zinc-700">
                    <div
                      class="size-8 rounded-full flex items-center justify-center text-white text-xs font-black shadow-lg shadow-primary/10"
                      style={"background-color: #{@selected_job.technician.color}"}
                    >
                      {initials(@selected_job.technician.name)}
                    </div>
                    <span class="text-sm font-bold text-zinc-900 dark:text-white">
                      {@selected_job.technician.name}
                    </span>
                  </div>
                <% end %>
              </div>
            </div>
            
    <!-- Quick Actions -->
            <div class="pt-8 border-t border-zinc-200 dark:border-zinc-800 space-y-4">
              <h4 class="text-xs font-black text-zinc-900 dark:text-white uppercase tracking-[0.2em]">
                Management Actions
              </h4>
              
    <!-- Status Change Buttons -->
              <div class="grid grid-cols-2 gap-3">
                <%= if @selected_job.status != "en_route" do %>
                  <button
                    phx-click="change_status"
                    phx-value-job_id={@selected_job.id}
                    phx-value-status="en_route"
                    class="px-4 py-3 bg-amber-50 dark:bg-amber-900/20 text-amber-600 dark:text-amber-400 rounded-xl text-xs font-black uppercase tracking-widest hover:bg-amber-100 transition-all border border-amber-200 dark:border-amber-800/50"
                  >
                    Set En Route
                  </button>
                <% end %>
                <%= if @selected_job.status != "on_site" do %>
                  <button
                    phx-click="change_status"
                    phx-value-job_id={@selected_job.id}
                    phx-value-status="on_site"
                    class="px-4 py-3 bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 rounded-xl text-xs font-black uppercase tracking-widest hover:bg-purple-100 transition-all border border-purple-200 dark:border-purple-800/50"
                  >
                    Set On Site
                  </button>
                <% end %>
                <%= if @selected_job.status != "in_progress" do %>
                  <button
                    phx-click="change_status"
                    phx-value-job_id={@selected_job.id}
                    phx-value-status="in_progress"
                    class="px-4 py-3 bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 rounded-xl text-xs font-black uppercase tracking-widest hover:bg-blue-100 transition-all border border-blue-200 dark:border-blue-800/50"
                  >
                    Start Implementation
                  </button>
                <% end %>
                <%= if @selected_job.status != "completed" do %>
                  <button
                    phx-click="change_status"
                    phx-value-job_id={@selected_job.id}
                    phx-value-status="completed"
                    class="px-4 py-3 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 rounded-xl text-xs font-black uppercase tracking-widest hover:bg-emerald-100 transition-all border border-emerald-200 dark:border-emerald-800/50"
                  >
                    Complete Job
                  </button>
                <% end %>
              </div>
              
    <!-- Unassign Button -->
              <%= if @selected_job.technician_id do %>
                <button
                  phx-click="unassign_job"
                  phx-value-job_id={@selected_job.id}
                  class="w-full px-4 py-3 border-2 border-dashed border-zinc-200 dark:border-zinc-800 text-zinc-400 hover:text-red-500 hover:border-red-500/50 rounded-xl text-xs font-black uppercase tracking-widest transition-all mt-4"
                >
                  Withdraw Assignment
                </button>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Badge helpers for slideout panel
  defp priority_badge(priority) do
    case priority do
      "urgent" ->
        "bg-red-50 text-red-600 border-red-200 dark:bg-red-900/20 dark:text-red-400 dark:border-red-900/50"

      "high" ->
        "bg-amber-50 text-amber-600 border-amber-200 dark:bg-amber-900/20 dark:text-amber-400 dark:border-amber-900/50"

      "normal" ->
        "bg-teal-50 text-teal-600 border-teal-200 dark:bg-teal-900/20 dark:text-teal-400 dark:border-teal-900/50"

      "low" ->
        "bg-zinc-50 text-zinc-600 border-zinc-200 dark:bg-zinc-800 dark:text-zinc-400 dark:border-zinc-700"

      _ ->
        "bg-zinc-50 text-zinc-600 border-zinc-200"
    end
  end

  defp status_badge(status) do
    case status do
      "unscheduled" ->
        "bg-zinc-50 text-zinc-600 border-zinc-200 dark:bg-zinc-800 dark:text-zinc-400 dark:border-zinc-700"

      "scheduled" ->
        "bg-teal-50 text-teal-600 border-teal-200 dark:bg-teal-900/20 dark:text-teal-400 dark:border-teal-900/50"

      "en_route" ->
        "bg-amber-50 text-amber-600 border-amber-200 dark:bg-amber-900/20 dark:text-amber-400 dark:border-amber-900/50"

      "on_site" ->
        "bg-purple-50 text-purple-600 border-purple-200 dark:bg-purple-900/20 dark:text-purple-400 dark:border-purple-900/50"

      "in_progress" ->
        "bg-blue-50 text-blue-600 border-blue-200 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-900/50"

      "completed" ->
        "bg-emerald-50 text-emerald-600 border-emerald-200 dark:bg-emerald-900/20 dark:text-emerald-400 dark:border-emerald-900/50"

      "cancelled" ->
        "bg-red-50 text-red-600 border-red-200 dark:bg-red-900/20 dark:text-red-400 dark:border-red-900/50"

      _ ->
        "bg-zinc-50 text-zinc-600 border-zinc-200"
    end
  end

  defp format_time(%Time{} = time) do
    Calendar.strftime(time, "%I:%M %p")
  end

  defp format_time(_), do: ""

  defp tech_status_color(status) do
    case status do
      "available" -> "bg-emerald-50 text-emerald-600 dark:bg-emerald-900/20 dark:text-emerald-400"
      "on_job" -> "bg-primary/10 text-primary dark:bg-primary/20 dark:text-primary"
      "traveling" -> "bg-amber-50 text-amber-600 dark:bg-amber-900/20 dark:text-amber-400"
      "break" -> "bg-purple-50 text-purple-600 dark:bg-purple-900/20 dark:text-purple-400"
      "off_duty" -> "bg-zinc-50 text-zinc-400 dark:bg-zinc-800 dark:text-zinc-500"
      _ -> "bg-zinc-50 text-zinc-400"
    end
  end

  defp tech_status_dot(status) do
    case status do
      "available" -> "bg-emerald-500"
      "on_job" -> "bg-primary"
      "traveling" -> "bg-amber-500"
      "break" -> "bg-purple-500"
      "off_duty" -> "bg-zinc-400"
      _ -> "bg-zinc-400"
    end
  end

  defp initials(name) do
    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.at(&1, 0))
    |> Enum.join("")
    |> String.upcase()
  end
end
