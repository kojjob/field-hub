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
    <div
      id="offline-sync-container"
      phx-hook="OfflineSync"
      class="max-w-md mx-auto p-4 space-y-6 pb-24"
    >
      <%!-- Offline Banner --%>
      <div
        id="offline-banner"
        class="hidden bg-amber-500/10 border border-amber-500/30 rounded-xl p-3 flex items-center gap-3"
      >
        <div class="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></div>
        <p class="text-sm text-amber-700 font-medium">
          You're offline. Changes will sync when connected.
        </p>
      </div>

      <%!-- Pending Sync Banner --%>
      <div
        id="pending-sync-banner"
        class="hidden bg-blue-500/10 border border-blue-500/30 rounded-xl p-3 flex items-center justify-between"
      >
        <div class="flex items-center gap-3">
          <.icon name="hero-arrow-path" class="w-5 h-5 text-blue-500 animate-spin" />
          <p class="text-sm text-blue-700 font-medium">
            <span data-pending-badge class="font-bold">0</span> pending updates
          </p>
        </div>
        <button data-sync-trigger class="text-xs font-semibold text-blue-600 hover:text-blue-800">
          Sync Now
        </button>
      </div>

      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Today's Jobs</h1>
        <div class="flex items-center gap-3">
          <%!-- Network Status Indicator --%>
          <div id="tech-network-status" phx-hook="OfflineIndicator" class="flex items-center gap-1.5">
            <div data-indicator class="w-2 h-2 rounded-full bg-emerald-500"></div>
            <span data-text class="text-xs text-gray-500">Online</span>
          </div>
          <button
            phx-click="refresh"
            class="text-gray-500 hover:text-gray-900 p-1 active:scale-95 transition-transform"
          >
            <.icon name="hero-arrow-path" class="w-5 h-5" />
          </button>
          <div class="text-sm text-gray-500">{Calendar.strftime(Date.utc_today(), "%a, %b %d")}</div>
        </div>
      </div>

      <%= if Enum.empty?(@jobs) do %>
        <div class="text-center py-10 bg-gray-50 rounded-2xl border border-dashed border-gray-300">
          <.icon name="hero-calendar" class="w-12 h-12 text-gray-400 mx-auto mb-2" />
          <p class="text-gray-500 font-medium">No jobs assigned for today.</p>
          <p class="text-gray-400 text-sm mt-1">Enjoy your day off!</p>
        </div>
      <% else %>
        <div class="space-y-4">
          <%= for job <- @jobs do %>
            <.link navigate={~p"/tech/jobs/#{job.id}"} class="block">
              <.job_card job={job} />
            </.link>
          <% end %>
        </div>
      <% end %>

      <%!-- PWA Install Prompt --%>
      <div
        id="pwa-install"
        phx-hook="PWAInstall"
        class="hidden fixed bottom-20 left-4 right-4 bg-teal-600 text-white rounded-xl p-4 shadow-lg"
      >
        <div class="flex items-center justify-between">
          <div>
            <p class="font-semibold">Install FieldHub</p>
            <p class="text-sm text-teal-100">Add to home screen for quick access</p>
          </div>
          <button class="bg-white text-teal-600 px-4 py-2 rounded-lg font-medium text-sm">
            Install
          </button>
        </div>
      </div>

      <div id="push-notifications" phx-hook="PushNotifications"></div>
      <div id="geolocation-tracking" phx-hook="Geolocation" data-auto-start="true"></div>
    </div>
    """
  end

  def job_card(assigns) do
    ~H"""
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 active:bg-gray-50 transition-colors">
      <div class="flex justify-between items-start mb-2">
        <div class="flex-1 min-w-0 mr-2">
          <h3 class="font-semibold text-gray-900 truncate">{@job.title}</h3>
          <p class="text-sm text-gray-500 truncate">{@job.customer.name}</p>
        </div>
        <span class={"px-2 py-1 rounded-full text-xs font-medium shrink-0 " <> status_color(@job.status)}>
          {String.capitalize(@job.status)}
        </span>
      </div>

      <div class="flex flex-col gap-2 text-sm text-gray-600 mt-3">
        <div class="flex items-center gap-2">
          <.icon name="hero-clock" class="w-4 h-4 text-gray-400 shrink-0" />
          <span>
            {if @job.scheduled_start,
              do: Calendar.strftime(@job.scheduled_start, "%H:%M"),
              else: "TBD"}
            <%= if @job.scheduled_end do %>
              - {Calendar.strftime(@job.scheduled_end, "%H:%M")}
            <% end %>
          </span>
        </div>
        <div class="flex items-center gap-2">
          <.icon name="hero-map-pin" class="w-4 h-4 text-gray-400 shrink-0" />
          <span class="truncate">
            {@job.service_address || @job.customer.address_line1 || "No address provided"}
          </span>
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
  def handle_event("update_location", %{"lat" => lat, "lng" => lng}, socket) do
    Dispatch.update_technician_location(socket.assigns.technician, lat, lng)
    {:noreply, socket}
  end

  @impl true
  def handle_event("location_error", params, socket) do
    IO.puts("Location error for technician #{socket.assigns.technician.id}: #{inspect(params)}")
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "offline_status",
        %{"online" => online, "pending_count" => pending_count},
        socket
      ) do
    # JavaScript hook notifies us of offline/online status changes
    socket =
      socket
      |> assign(:is_online, online)
      |> assign(:pending_count, pending_count)

    {:noreply, socket}
  end

  @impl true
  def handle_event("sync_complete", %{"synced" => synced, "failed" => failed}, socket) do
    message =
      cond do
        synced > 0 and failed == 0 -> "#{synced} updates synced successfully!"
        synced > 0 and failed > 0 -> "#{synced} synced, #{failed} failed. Will retry."
        true -> "Sync complete."
      end

    {:noreply, put_flash(socket, :info, message)}
  end

  @impl true
  def handle_event("show_toast", %{"message" => message, "type" => type}, socket) do
    flash_type = if type == "error", do: :error, else: :info
    {:noreply, put_flash(socket, flash_type, message)}
  end

  @impl true
  def handle_event("update_queued", _params, socket) do
    {:noreply, put_flash(socket, :info, "Action saved offline")}
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
