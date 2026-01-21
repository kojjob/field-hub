defmodule FieldHubWeb.Components.PushNotificationHandler do
  use FieldHubWeb, :live_component
  alias FieldHub.Notifications.Push
  require Logger

  @impl true
  def mount(socket) do
    {:ok, assign(socket, permission: "unknown", dismissed: false)}
  end

  @impl true
  def update(assigns, socket) do
    config = Application.get_env(:web_push_encryption, :vapid_details) || []
    public_key = config[:public_key]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(vapid_key: public_key)}
  end

  @impl true
  def render(assigns) do
    show_banner =
      assigns[:permission] == "default" and not assigns[:dismissed] and assigns[:vapid_key]

    assigns = assign(assigns, :show_banner, show_banner)

    ~H"""
    <div>
      <%= if @vapid_key do %>
        <div
          id="push-notification-handler"
          phx-hook="PushNotifications"
          data-vapid-key={@vapid_key}
          class="hidden"
        >
        </div>
      <% else %>
        <div id="push-notification-handler" class="hidden"></div>
      <% end %>

      <%= if @show_banner do %>
        <div class="fixed bottom-4 right-4 z-50 bg-white dark:bg-zinc-800 shadow-lg rounded-lg p-4 border border-zinc-200 dark:border-zinc-700 max-w-sm transition-all duration-300 animate-in slide-in-from-bottom-2">
          <div class="flex items-start gap-3">
            <div class="p-2 bg-blue-50 dark:bg-blue-900/20 rounded-full text-blue-600 dark:text-blue-400">
              <.icon name="hero-bell-solid" class="w-5 h-5" />
            </div>
            <div class="flex-1">
              <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                Enable Notifications
              </h3>
              <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                Get real-time updates for new jobs and assignments.
              </p>
              <div class="mt-3 flex gap-2">
                <button
                  phx-click="request_permission"
                  phx-target={@myself}
                  class="text-xs bg-blue-600 hover:bg-blue-700 text-white font-medium px-3 py-1.5 rounded-md transition-colors"
                >
                  Enable
                </button>
                <button
                  phx-click="dismiss_banner"
                  phx-target={@myself}
                  class="text-xs text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200 font-medium px-3 py-1.5 transition-colors"
                >
                  Later
                </button>
              </div>
            </div>
            <button
              phx-click="dismiss_banner"
              phx-target={@myself}
              class="text-zinc-400 hover:text-zinc-500"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("permission_status", %{"status" => status}, socket) do
    {:noreply, assign(socket, permission: status)}
  end

  @impl true
  def handle_event("request_permission", _, socket) do
    # Trigger JS hook
    {:noreply, push_event(socket, "request_permission", %{})}
  end

  @impl true
  def handle_event("dismiss_banner", _, socket) do
    {:noreply, assign(socket, dismissed: true)}
  end

  @impl true
  def handle_event("save_subscription", params, socket) do
    if socket.assigns[:user_id] do
      case Push.subscribe(socket.assigns.user_id, params) do
        {:ok, _sub} ->
          Logger.info("Push subscription saved for user #{socket.assigns.user_id}")
          {:noreply, assign(socket, permission: "granted")}

        {:error, changeset} ->
          Logger.warning("Failed to save push subscription: #{inspect(changeset.errors)}")
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end
end
