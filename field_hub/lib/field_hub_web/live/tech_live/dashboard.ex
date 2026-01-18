defmodule FieldHubWeb.TechLive.Dashboard do
  use FieldHubWeb, :live_view

  alias FieldHub.Dispatch
  alias FieldHub.Jobs

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    technician = Dispatch.get_technician_by_user_id(user.id)

    if technician do
      if connected?(socket) do
        FieldHub.Dispatch.Broadcaster.subscribe_to_tech(technician.id)
      end

      today = Date.utc_today()
      jobs = Jobs.list_jobs_for_technician(technician.id, today)

      socket =
        socket
        |> assign(:technician, technician)
        |> assign(:jobs, jobs)
        |> assign(:page_title, "My Schedule")

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Technician account not found.")
       |> redirect(to: ~p"/dashboard")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-4 space-y-6 pb-24">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Today's Jobs</h1>
        <div class="flex items-center gap-2">
           <button phx-click="refresh" class="text-gray-500 hover:text-gray-900 p-1">
             <.icon name="hero-arrow-path" class="w-5 h-5" />
           </button>
           <div class="text-sm text-gray-500"><%= Calendar.strftime(Date.utc_today(), "%a, %b %d") %></div>
        </div>
      </div>

      <%= if Enum.empty?(@jobs) do %>
        <div class="text-center py-10 bg-gray-50 rounded-lg border border-dashed border-gray-300">
          <.icon name="hero-calendar" class="w-12 h-12 text-gray-400 mx-auto mb-2" />
          <p class="text-gray-500 font-medium">No jobs assigned for today.</p>
          <p class="text-gray-400 text-sm mt-1">Enjoy your day off!</p>
        </div>
      <% else %>
        <div class="space-y-4">
          <%= for job <- @jobs do %>
            <.job_card job={job} />
          <% end %>
        </div>
      <% end %>

      <div id="push-notifications" phx-hook="PushNotifications"></div>
    </div>
    """
  end

  def job_card(assigns) do
    ~H"""
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 active:bg-gray-50 transition-colors">
      <div class="flex justify-between items-start mb-2">
        <div class="flex-1 min-w-0 mr-2">
          <h3 class="font-semibold text-gray-900 truncate"><%= @job.title %></h3>
          <p class="text-sm text-gray-500 truncate"><%= @job.customer.name %></p>
        </div>
        <span class={"px-2 py-1 rounded-full text-xs font-medium shrink-0 " <> status_color(@job.status)}>
          <%= String.capitalize(@job.status) %>
        </span>
      </div>

      <div class="flex flex-col gap-2 text-sm text-gray-600 mt-3">
        <div class="flex items-center gap-2">
          <.icon name="hero-clock" class="w-4 h-4 text-gray-400 shrink-0" />
          <span>
            <%= if @job.scheduled_start, do: Calendar.strftime(@job.scheduled_start, "%H:%M"), else: "TBD" %>
            <%= if @job.scheduled_end do %>
               - <%= Calendar.strftime(@job.scheduled_end, "%H:%M") %>
            <% end %>
          </span>
        </div>
        <div class="flex items-center gap-2">
          <.icon name="hero-map-pin" class="w-4 h-4 text-gray-400 shrink-0" />
          <span class="truncate"><%= @job.service_address || @job.customer.address_line1 || "No address provided" %></span>
        </div>
      </div>
    </div>
    """
  end

  defp status_color("scheduled"), do: "bg-blue-100 text-blue-800"
  defp status_color("in_progress"), do: "bg-green-100 text-green-800"
  defp status_color("completed"), do: "bg-gray-100 text-gray-800"
  defp status_color("cancelled"), do: "bg-red-100 text-red-800"
  defp status_color(_), do: "bg-gray-100 text-gray-600"

  @impl true
  def handle_event("refresh", _, socket) do
    {:noreply, refresh_list(socket)}
  end

  @impl true
  def handle_event("save_device_token", %{"token" => token, "type" => type}, socket) do
    Dispatch.update_technician_device_token(socket.assigns.technician, type, token)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:job_updated, _job}, socket) do
    {:noreply, refresh_list(socket)}
  end

  defp refresh_list(socket) do
    today = Date.utc_today()
    jobs = Jobs.list_jobs_for_technician(socket.assigns.technician.id, today)
    assign(socket, :jobs, jobs)
  end
end
