defmodule FieldHubWeb.DispatchLive.Index do
  @moduledoc """
  Dispatch Board LiveView - Calendar view for job scheduling and technician management.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs
  alias FieldHub.Dispatch
  alias FieldHub.Dispatch.Broadcaster
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
    base_query = Dispatch.list_technicians(org_id)
      |> Repo.preload(jobs: from(j in FieldHub.Jobs.Job, where: j.status == "in_progress", order_by: [desc: j.updated_at], limit: 1, preload: [:customer]))

    technicians =
      if tech_filter_id do
        Enum.filter(base_query, fn t -> t.id == tech_filter_id end)
      else
        base_query
      end

    # Load scheduled jobs for the selected date
    scheduled_jobs = Jobs.list_jobs_for_date(org_id, selected_date)

    # Prepare map data
    map_technicians = Enum.map(technicians, fn t ->
      %{
        id: t.id,
        name: t.name,
        status: t.status,
        color: t.color,
        current_lat: t.current_lat,
        current_lng: t.current_lng
      }
    end)

    map_jobs = Enum.map(scheduled_jobs, fn j ->
      %{
        id: j.id,
        number: j.number,
        title: j.title,
        status: j.status,
        service_lat: j.service_lat,
        service_lng: j.service_lng
      }
    end)

    # Load unassigned jobs (no technician or no scheduled date)
    unassigned_jobs = Jobs.list_unassigned_jobs(org_id)

    socket =
      socket
      |> assign(:unassigned_jobs, unassigned_jobs)
      |> assign(:technicians, technicians)
      |> assign(:scheduled_jobs, scheduled_jobs)
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
    {:noreply, assign(socket, :view_mode, String.to_existing_atom(mode))}
  end

  @impl true
  def handle_event("assign_job", %{"job_id" => job_id, "technician_id" => tech_id} = params, socket) do
    org_id = socket.assigns.current_organization.id
    job = Jobs.get_job!(org_id, job_id)

    # Build update params
    update_params = %{
      "technician_id" => tech_id,
      "scheduled_date" => Date.to_string(socket.assigns.selected_date)
    }

    # Add scheduled time if hour is provided
    update_params = if params["hour"] do
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
  def handle_event("unassign_job", %{"job_id" => job_id}, socket) do
    org_id = socket.assigns.current_organization.id
    job = Jobs.get_job!(org_id, job_id)

    case Jobs.update_job(job, %{"technician_id" => nil, "scheduled_date" => nil, "scheduled_start" => nil}) do
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
    available_tech = Dispatch.list_technicians(org_id)
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
            {:noreply, socket |> put_flash(:info, "Job dispatched to #{tech.name}") |> load_data()}
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
  def handle_event("update_tech_status", %{"technician_id" => tech_id, "status" => status}, socket) do
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

  defp jobs_for_technician_at_hour(jobs, technician_id, hour) do
    jobs
    |> Enum.filter(fn job ->
      job.technician_id == technician_id &&
        job.scheduled_start &&
        job.scheduled_start.hour == hour
    end)
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
      "unscheduled" -> "bg-gray-100 border-gray-300"
      "scheduled" -> "bg-blue-100 border-blue-300"
      "en_route" -> "bg-yellow-100 border-yellow-300"
      "on_site" -> "bg-purple-100 border-purple-300"
      "in_progress" -> "bg-indigo-100 border-indigo-300"
      "completed" -> "bg-green-100 border-green-300"
      "cancelled" -> "bg-red-100 border-red-300"
      _ -> "bg-gray-100 border-gray-300"
    end
  end

  defp priority_indicator(priority) do
    case priority do
      "urgent" -> "border-l-4 border-l-red-500"
      "high" -> "border-l-4 border-l-orange-500"
      "normal" -> "border-l-4 border-l-blue-500"
      "low" -> "border-l-4 border-l-gray-500"
      _ -> ""
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col" phx-window-keydown="keydown">
      <!-- Header -->
      <div class="bg-white border-b px-4 py-3 flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-semibold text-gray-900">Dispatch Board</h1>
          <p class="text-sm text-gray-500">{format_day_of_week(@selected_date)}, {format_date(@selected_date)}</p>
        </div>

        <div class="flex items-center gap-2">
          <!-- View Toggle -->
          <div class="flex rounded-lg border border-gray-300 p-1">
            <button
              phx-click="set_view_mode"
              phx-value-mode="day"
              class={"px-3 py-1 text-sm rounded #{if @view_mode == :day, do: "bg-primary text-white", else: "text-gray-600 hover:bg-gray-100"}"}
            >
              Day
            </button>
            <button
              phx-click="set_view_mode"
              phx-value-mode="map"
              class={"px-3 py-1 text-sm rounded #{if @view_mode == :map, do: "bg-primary text-white", else: "text-gray-600 hover:bg-gray-100"}"}
            >
              Map
            </button>
          </div>

          <!-- Date Navigation -->
          <div class="flex items-center gap-1">
            <button phx-click="prev_day" class="p-2 rounded hover:bg-gray-100">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <button phx-click="today" class="px-3 py-1 text-sm border rounded hover:bg-gray-100">
              Today
            </button>
            <button phx-click="next_day" class="p-2 rounded hover:bg-gray-100">
              Next
            </button>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="flex-1 flex overflow-hidden">
        <!-- Unassigned Jobs Sidebar -->
        <div class="w-64 bg-gray-50 border-r overflow-y-auto p-3">
          <h2 class="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
            <span class="bg-orange-100 text-orange-800 px-2 py-0.5 rounded text-xs">
              {length(@unassigned_jobs)}
            </span>
            Unassigned
          </h2>

          <div id="unassigned-jobs" class="space-y-2" phx-hook="DragDrop" data-group="jobs" data-type="source">
            <%= for job <- @unassigned_jobs do %>
              <div
                class={"drag-handle p-2 bg-white rounded-lg border shadow-sm cursor-grab hover:shadow-md transition-shadow #{priority_indicator(job.priority)}"}
                data-job-id={job.id}
              >
                <div class="flex items-start justify-between gap-1">
                  <div class="flex-1 min-w-0" phx-click="show_job_details" phx-value-job_id={job.id}>
                    <div class="font-medium text-sm text-gray-900 truncate">{job.title}</div>
                    <div class="text-xs text-gray-500">{job.customer.name}</div>
                  </div>
                  <button
                    phx-click="quick_dispatch"
                    phx-value-job_id={job.id}
                    class="shrink-0 p-1 rounded hover:bg-blue-100 text-blue-600"
                    title="Quick dispatch"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
                    </svg>
                  </button>
                </div>
                <div class="mt-1 flex items-center gap-1">
                  <span class={"inline-block w-2 h-2 rounded-full #{if job.priority == "urgent", do: "bg-red-500", else: "bg-gray-400"}"}></span>
                  <span class="text-xs text-gray-400 capitalize">{job.priority}</span>
                </div>
              </div>
            <% end %>

            <%= if Enum.empty?(@unassigned_jobs) do %>
              <p class="text-sm text-gray-400 text-center py-4">No unassigned jobs</p>
            <% end %>
          </div>
        </div>

        <!-- Calendar Grid or Map -->
        <div class="flex-1 overflow-auto relative">
          <%= if @view_mode == :map do %>
            <div
              id="map-view"
              class="absolute inset-0 z-0 bg-gray-100"
              phx-hook="Map"
              phx-update="ignore"
              data-lat="37.7749"
              data-lng="-122.4194"
              data-technicians={Jason.encode!(@map_technicians)}
              data-jobs={Jason.encode!(@map_jobs)}
            ></div>
          <% else %>
            <div class="min-w-max">
              <!-- Technician Headers -->
              <div class="flex sticky top-0 bg-white z-10 border-b">
                <div class="w-20 shrink-0 border-r bg-gray-50"></div>
                <%= for tech <- @technicians do %>
                  <div class="w-48 shrink-0 border-r p-2">
                    <div class="flex items-center gap-2">
                      <div class="w-3 h-3 rounded-full" style={"background-color: #{tech.color}"}></div>
                      <span class="font-medium text-sm">{tech.name}</span>
                    </div>
                    <div class="text-xs text-gray-500 capitalize">{tech.status}</div>
                  </div>
                <% end %>
              </div>

              <!-- Time Slots -->
              <%= for slot <- time_slots() do %>
                <div class="flex border-b hover:bg-gray-50/50">
                  <!-- Time Label -->
                  <div class="w-20 shrink-0 border-r bg-gray-50 p-2 text-xs text-gray-500 text-right">
                    {slot.label}
                  </div>

                  <!-- Technician Columns -->
                  <%= for tech <- @technicians do %>
                    <div
                      id={"slot-#{tech.id}-#{slot.hour}"}
                      class="w-48 shrink-0 border-r p-1 min-h-[60px] relative"
                      phx-hook="DragDrop"
                      data-group="jobs"
                      data-type="target"
                      data-technician-id={tech.id}
                      data-hour={slot.hour}
                    >
                      <%= for job <- jobs_for_technician_at_hour(@scheduled_jobs, tech.id, slot.hour) do %>
                        <div
                          class={"drag-handle #{job_duration_class(job)} #{status_color(job.status)} #{priority_indicator(job.priority)} w-full rounded p-1 border text-xs cursor-grab hover:shadow-md transition-shadow"}
                          data-job-id={job.id}
                          phx-click="show_job_details"
                          phx-value-job_id={job.id}
                        >
                          <div class="font-medium truncate">{job.title}</div>
                          <div class="text-gray-600 truncate">{job.customer.name}</div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        <!-- Technician Status Sidebar -->
      <div class="w-72 bg-white border-l flex flex-col shrink-0">
        <div class="p-4 border-b flex items-center justify-between">
          <h2 class="font-semibold text-gray-800">Technician Status</h2>
          <%= if @technician_filter do %>
            <button phx-click="clear_tech_filter" class="text-xs text-blue-600 hover:text-blue-800 font-medium">
              Clear Filter
            </button>
          <% end %>
        </div>
        <div class="flex-1 overflow-y-auto p-4 space-y-4">
          <%= for tech <- @technicians do %>
            <div
              class={"bg-gray-50 rounded-lg p-3 border hover:bg-gray-100 cursor-pointer transition-colors #{if @technician_filter == tech.id, do: "ring-2 ring-primary ring-offset-2"}"}
              phx-click="view_tech_schedule"
              phx-value-tech_id={tech.id}
            >
              <div class="flex items-center gap-3 mb-2">
                <div class="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold" style={"background-color: #{tech.color}"}>
                  {initials(tech.name)}
                </div>
                <div>
                  <div class="font-medium text-sm">{tech.name}</div>
                  <div class="flex items-center gap-1.5 mt-0.5">
                    <div class={"w-2 h-2 rounded-full #{tech_status_dot(tech.status)}"}></div>
                    <span class={"text-xs px-1.5 py-0.5 rounded #{tech_status_color(tech.status)}"}>
                      {String.replace(tech.status, "_", " ")}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Current Active Job -->
              <%= if tech.status == "on_job" || tech.status == "traveling" do %>
                <%= if active_job = List.first(tech.jobs) do %>
                  <div class="mt-2 text-xs bg-white rounded p-2 border shadow-sm">
                    <div class="text-gray-500 mb-0.5">Current Job:</div>
                    <div class="font-medium truncate">{active_job.title}</div>
                    <div class="text-gray-500 truncate">{active_job.customer.name}</div>
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
        <div class="fixed inset-0 bg-black/20 z-40" phx-click="close_job_details"></div>
        <div class="fixed right-0 top-0 h-full w-96 bg-white shadow-xl z-50 overflow-y-auto">
          <div class="p-4 border-b flex items-center justify-between">
            <h2 class="text-lg font-semibold">Job Details</h2>
            <button phx-click="close_job_details" class="p-1 rounded hover:bg-gray-100">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <div class="p-4 space-y-4">
            <!-- Job Title & Priority -->
            <div>
              <div class="flex items-center gap-2 mb-1">
                <span class={"inline-block px-2 py-0.5 rounded text-xs font-medium #{priority_badge(@selected_job.priority)}"}>
                  {@selected_job.priority}
                </span>
                <span class={"inline-block px-2 py-0.5 rounded text-xs #{status_badge(@selected_job.status)}"}>
                  {@selected_job.status}
                </span>
              </div>
              <h3 class="text-xl font-semibold">{@selected_job.title}</h3>
              <p class="text-gray-600 mt-1">{@selected_job.description}</p>
            </div>

            <!-- Customer Info -->
            <div class="bg-gray-50 rounded-lg p-3">
              <h4 class="text-sm font-medium text-gray-500 mb-1">Customer</h4>
              <p class="font-medium">{@selected_job.customer.name}</p>
              <%= if @selected_job.customer.phone do %>
                <p class="text-sm text-gray-600">{@selected_job.customer.phone}</p>
              <% end %>
            </div>

            <!-- Schedule Info -->
            <div class="bg-gray-50 rounded-lg p-3">
              <h4 class="text-sm font-medium text-gray-500 mb-1">Schedule</h4>
              <%= if @selected_job.scheduled_date do %>
                <p class="font-medium">{format_date(@selected_job.scheduled_date)}</p>
                <%= if @selected_job.scheduled_start do %>
                  <p class="text-sm text-gray-600">
                    Starts at {format_time(@selected_job.scheduled_start)}
                  </p>
                <% end %>
              <% else %>
                <p class="text-gray-500 italic">Not scheduled</p>
              <% end %>
            </div>

            <!-- Technician Info -->
            <div class="bg-gray-50 rounded-lg p-3">
              <h4 class="text-sm font-medium text-gray-500 mb-1">Technician</h4>
              <%= if @selected_job.technician do %>
                <div class="flex items-center gap-2">
                  <div class="w-3 h-3 rounded-full" style={"background-color: #{@selected_job.technician.color}"}></div>
                  <span class="font-medium">{@selected_job.technician.name}</span>
                </div>
              <% else %>
                <p class="text-gray-500 italic">Unassigned</p>
              <% end %>
            </div>

            <!-- Quick Actions -->
            <div class="pt-4 border-t space-y-2">
              <h4 class="text-sm font-medium text-gray-700">Quick Actions</h4>

              <!-- Status Change Buttons -->
              <div class="flex flex-wrap gap-2">
                <%= if @selected_job.status != "en_route" do %>
                  <button
                    phx-click="change_status"
                    phx-value-job_id={@selected_job.id}
                    phx-value-status="en_route"
                    class="px-3 py-1 bg-yellow-100 text-yellow-800 rounded text-sm hover:bg-yellow-200"
                  >
                    → En Route
                  </button>
                <% end %>
                <%= if @selected_job.status != "on_site" do %>
                  <button
                    phx-click="change_status"
                    phx-value-job_id={@selected_job.id}
                    phx-value-status="on_site"
                    class="px-3 py-1 bg-purple-100 text-purple-800 rounded text-sm hover:bg-purple-200"
                  >
                    → On Site
                  </button>
                <% end %>
                <%= if @selected_job.status != "in_progress" do %>
                  <button
                    phx-click="change_status"
                    phx-value-job_id={@selected_job.id}
                    phx-value-status="in_progress"
                    class="px-3 py-1 bg-indigo-100 text-indigo-800 rounded text-sm hover:bg-indigo-200"
                  >
                    → In Progress
                  </button>
                <% end %>
                <%= if @selected_job.status != "completed" do %>
                  <button
                    phx-click="change_status"
                    phx-value-job_id={@selected_job.id}
                    phx-value-status="completed"
                    class="px-3 py-1 bg-green-100 text-green-800 rounded text-sm hover:bg-green-200"
                  >
                    ✓ Complete
                  </button>
                <% end %>
              </div>

              <!-- Unassign Button -->
              <%= if @selected_job.technician_id do %>
                <button
                  phx-click="unassign_job"
                  phx-value-job_id={@selected_job.id}
                  class="w-full px-3 py-2 border border-red-300 text-red-700 rounded text-sm hover:bg-red-50"
                >
                  Unassign from Technician
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
      "urgent" -> "bg-red-100 text-red-800"
      "high" -> "bg-orange-100 text-orange-800"
      "normal" -> "bg-blue-100 text-blue-800"
      "low" -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp status_badge(status) do
    case status do
      "unscheduled" -> "bg-gray-100 text-gray-800"
      "scheduled" -> "bg-blue-100 text-blue-800"
      "en_route" -> "bg-yellow-100 text-yellow-800"
      "on_site" -> "bg-purple-100 text-purple-800"
      "in_progress" -> "bg-indigo-100 text-indigo-800"
      "completed" -> "bg-green-100 text-green-800"
      "cancelled" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp format_time(%Time{} = time) do
    Calendar.strftime(time, "%I:%M %p")
  end
  defp format_time(_), do: ""

  defp tech_status_color(status) do
    case status do
      "available" -> "bg-green-100 text-green-800"
      "on_job" -> "bg-blue-100 text-blue-800"
      "traveling" -> "bg-yellow-100 text-yellow-800"
      "break" -> "bg-orange-100 text-orange-800"
      "off_duty" -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp tech_status_dot(status) do
    case status do
      "available" -> "bg-green-500"
      "on_job" -> "bg-blue-500"
      "traveling" -> "bg-yellow-500"
      "break" -> "bg-orange-500"
      "off_duty" -> "bg-gray-400"
      _ -> "bg-gray-400"
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
