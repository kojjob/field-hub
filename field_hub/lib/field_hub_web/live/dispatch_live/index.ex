defmodule FieldHubWeb.DispatchLive.Index do
  @moduledoc """
  Dispatch Board LiveView - Calendar view for job scheduling and technician management.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs
  alias FieldHub.Dispatch
  alias FieldHub.Dispatch.Broadcaster

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

    # Load technicians
    technicians = Dispatch.list_technicians(org_id)

    # Load scheduled jobs for the selected date
    scheduled_jobs = Jobs.list_jobs_for_date(org_id, selected_date)

    # Load unassigned jobs (no technician or no scheduled date)
    unassigned_jobs = Jobs.list_unassigned_jobs(org_id)

    socket
    |> assign(:technicians, technicians)
    |> assign(:scheduled_jobs, scheduled_jobs)
    |> assign(:unassigned_jobs, unassigned_jobs)
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
  def handle_info({:job_created, _job}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info({:job_updated, _job}, socket) do
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
    <div class="h-full flex flex-col">
      <!-- Header -->
      <div class="bg-white border-b px-4 py-3 flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-semibold text-gray-900">Dispatch Board</h1>
          <p class="text-sm text-gray-500">{format_day_of_week(@selected_date)}, {format_date(@selected_date)}</p>
        </div>

        <div class="flex items-center gap-2">
          <!-- View Toggle -->
          <div class="flex rounded-lg border border-gray-300 p-1">
            <button class={"px-3 py-1 text-sm rounded #{if @view_mode == :day, do: "bg-primary text-white", else: "text-gray-600 hover:bg-gray-100"}"}>
              Day
            </button>
            <button class={"px-3 py-1 text-sm rounded #{if @view_mode == :week, do: "bg-primary text-white", else: "text-gray-600 hover:bg-gray-100"}"} disabled>
              Week
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

          <div class="space-y-2">
            <%= for job <- @unassigned_jobs do %>
              <div class={"p-2 bg-white rounded-lg border shadow-sm cursor-pointer hover:shadow-md transition-shadow #{priority_indicator(job.priority)}"}>
                <div class="font-medium text-sm text-gray-900 truncate">{job.title}</div>
                <div class="text-xs text-gray-500">{job.customer.name}</div>
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

        <!-- Calendar Grid -->
        <div class="flex-1 overflow-auto">
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
                  <div class="w-48 shrink-0 border-r p-1 min-h-[60px] relative">
                    <%= for job <- jobs_for_technician_at_hour(@scheduled_jobs, tech.id, slot.hour) do %>
                      <div class={"#{job_duration_class(job)} #{status_color(job.status)} #{priority_indicator(job.priority)} w-full rounded p-1 border text-xs cursor-pointer hover:shadow-md transition-shadow"}>
                        <div class="font-medium truncate">{job.title}</div>
                        <div class="text-gray-600 truncate">{job.customer.name}</div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
