defmodule FieldHubWeb.Live.Sidebar do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     # Default state, could receive from session if implemented
     |> assign(:sidebar_collapsed, false)
     |> attach_hook(:sidebar_toggle, :handle_event, &handle_event/3)}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    # Simple toggle for now.
    # To persist: push_event to update cookie via JS, or use session store if available.
    new_state = !socket.assigns.sidebar_collapsed
    {:halt, assign(socket, :sidebar_collapsed, new_state)}
  end

  # Fallback for other events
  def handle_event(_event, _params, socket), do: {:cont, socket}
end
