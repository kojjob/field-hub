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
        class="hidden bg-amber-500/10 dark:bg-amber-500/20 border border-amber-500/30 rounded-xl p-3 flex items-center gap-3"
      >
        <div class="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></div>
        <p class="text-sm text-amber-700 dark:text-amber-400 font-medium">
          You're offline. Changes will sync when connected.
        </p>
      </div>

      <%!-- Pending Sync Banner --%>
      <div
        id="pending-sync-banner"
        class="hidden bg-blue-500/10 dark:bg-blue-500/20 border border-blue-500/30 rounded-xl p-3 flex items-center justify-between"
      >
        <div class="flex items-center gap-3">
          <.icon name="hero-arrow-path" class="w-5 h-5 text-blue-500 animate-spin" />
          <p class="text-sm text-blue-700 dark:text-blue-400 font-medium">
            <span data-pending-badge class="font-bold">0</span> pending updates
          </p>
        </div>
        <button data-sync-trigger class="text-xs font-semibold text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300">
          Sync Now
        </button>
      </div>

      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-zinc-900 dark:text-white">Today's Jobs</h1>
        <div class="flex items-center gap-3">
          <%!-- Network Status Indicator --%>
          <div id="tech-network-status" phx-hook="OfflineIndicator" class="flex items-center gap-1.5">
            <div data-indicator class="w-2 h-2 rounded-full bg-emerald-500"></div>
            <span data-text class="text-xs text-zinc-500 dark:text-zinc-400">Online</span>
          </div>
          <button
            phx-click="refresh"
            class="text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-white p-2 active:scale-95 transition-all rounded-xl hover:bg-zinc-100 dark:hover:bg-zinc-800"
          >
            <.icon name="hero-arrow-path" class="w-5 h-5" />
          </button>
          <div class="text-sm text-zinc-500 dark:text-zinc-400">{Calendar.strftime(Date.utc_today(), "%a, %b %d")}</div>
        </div>
      </div>

      <%= if Enum.empty?(@jobs) do %>
        <div class="text-center py-10 bg-zinc-50 dark:bg-zinc-900 rounded-2xl border border-dashed border-zinc-300 dark:border-zinc-700">
          <.icon name="hero-calendar" class="w-12 h-12 text-zinc-400 dark:text-zinc-500 mx-auto mb-2" />
          <p class="text-zinc-600 dark:text-zinc-300 font-medium">No jobs assigned for today.</p>
          <p class="text-zinc-400 dark:text-zinc-500 text-sm mt-1">Enjoy your day off!</p>
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
    <div class="bg-white dark:bg-zinc-900 rounded-xl shadow-sm border border-zinc-200 dark:border-zinc-800 p-4 active:bg-zinc-50 dark:active:bg-zinc-800 transition-colors">
      <div class="flex justify-between items-start mb-2">
        <div class="flex-1 min-w-0 mr-2">
          <h3 class="font-semibold text-zinc-900 dark:text-white truncate">{@job.title}</h3>
          <p class="text-sm text-zinc-500 dark:text-zinc-400 truncate">{@job.customer.name}</p>
        </div>
        <span class={[
          "px-2.5 py-1 rounded-lg text-xs font-bold shrink-0",
          status_color(@job.status)
        ]}>
          {String.capitalize(@job.status)}
        </span>
      </div>

      <div class="flex flex-col gap-2.5 text-sm text-zinc-600 dark:text-zinc-400 mt-3">
        <div class="flex items-center gap-2">
          <.icon name="hero-clock" class="w-4 h-4 text-zinc-400 dark:text-zinc-500 shrink-0" />
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
          <.icon name="hero-map-pin" class="w-4 h-4 text-zinc-400 dark:text-zinc-500 shrink-0" />
          <span class="truncate">
            {@job.service_address || @job.customer.address_line1 || "No address provided"}
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp status_color("scheduled"), do: "bg-blue-100 dark:bg-blue-500/20 text-blue-800 dark:text-blue-400"
  defp status_color("in_progress"), do: "bg-emerald-100 dark:bg-emerald-500/20 text-emerald-800 dark:text-emerald-400"
  defp status_color("completed"), do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300"
  defp status_color("cancelled"), do: "bg-red-100 dark:bg-red-500/20 text-red-800 dark:text-red-400"
  defp status_color(_), do: "bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400"

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
