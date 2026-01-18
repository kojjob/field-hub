defmodule FieldHubWeb.SettingsLive.Workflows do
  @moduledoc """
  Settings page for configuring organization job statuses and workflows.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Config.Workflows

  @impl true
  def mount(_params, _session, socket) do
    org = socket.assigns.current_organization
    statuses = Workflows.get_statuses(org)

    socket =
      socket
      |> assign(:page_title, "Workflow Settings")
      |> assign(:statuses, statuses)
      |> assign(:presets, Workflows.industry_presets())
      |> assign(:editing_status, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">Workflow Settings</h1>
        <p class="mt-2 text-gray-600">
          Configure job statuses and workflow transitions for your organization.
        </p>
      </div>

      <!-- Presets -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Industry Presets</h2>
        <p class="text-sm text-gray-500 mb-4">Apply a preset workflow for your industry.</p>
        <div class="flex flex-wrap gap-2">
          <%= for preset <- @presets do %>
            <button
              type="button"
              phx-click="apply_preset"
              phx-value-preset={preset.key}
              class="px-4 py-2 bg-gray-100 hover:bg-indigo-100 hover:text-indigo-700 rounded-lg text-sm font-medium transition-colors"
            >
              <%= preset.name %>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Current Statuses -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-lg font-semibold text-gray-900">Job Statuses</h2>
          <button
            type="button"
            phx-click="add_status"
            class="px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
          >
            + Add Status
          </button>
        </div>

        <div class="space-y-3">
          <%= for {status, index} <- Enum.with_index(@statuses) do %>
            <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg group">
              <div
                class="w-4 h-4 rounded-full shrink-0"
                style={"background-color: #{get_field(status, :color, "#6B7280")}"}
              ></div>
              <div class="flex-1 min-w-0">
                <div class="font-medium text-gray-900"><%= get_field(status, :label, "Status") %></div>
                <div class="text-xs text-gray-500">Key: <%= get_field(status, :key, "") %></div>
              </div>
              <div class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  type="button"
                  phx-click="edit_status"
                  phx-value-index={index}
                  class="p-1.5 text-gray-400 hover:text-gray-700 hover:bg-gray-200 rounded"
                >
                  <.icon name="hero-pencil" class="w-4 h-4" />
                </button>
                <button
                  type="button"
                  phx-click="delete_status"
                  phx-value-index={index}
                  class="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Status Editor Modal -->
      <%= if @editing_status do %>
        <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" phx-click="close_editor">
          <div class="bg-white rounded-xl shadow-xl p-6 w-full max-w-md" phx-click-away="close_editor">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">
              <%= if @editing_status.is_new, do: "Add Status", else: "Edit Status" %>
            </h3>

            <form phx-submit="save_status" class="space-y-4">
              <input type="hidden" name="index" value={@editing_status.index} />

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Label</label>
                <input
                  type="text"
                  name="label"
                  value={@editing_status.label}
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="In Progress"
                  required
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Key (system identifier)</label>
                <input
                  type="text"
                  name="key"
                  value={@editing_status.key}
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 font-mono text-sm"
                  placeholder="in_progress"
                  pattern="[a-z_]+"
                  required
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Color</label>
                <div class="flex gap-2">
                  <input
                    type="color"
                    name="color"
                    value={@editing_status.color}
                    class="h-10 w-16 rounded border border-gray-300 cursor-pointer"
                  />
                  <input
                    type="text"
                    value={@editing_status.color}
                    class="flex-1 px-3 py-2 border border-gray-300 rounded-lg bg-gray-50 font-mono text-sm"
                    readonly
                  />
                </div>
              </div>

              <div class="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  phx-click="close_editor"
                  class="px-4 py-2 text-gray-700 hover:text-gray-900"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-6 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  Save
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>

      <div class="flex justify-end gap-3">
        <.link navigate={~p"/dashboard"} class="px-4 py-2 text-gray-700 hover:text-gray-900">
          Cancel
        </.link>
        <button
          type="button"
          phx-click="save_all"
          class="px-6 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors"
        >
          Save Changes
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("apply_preset", %{"preset" => preset_key}, socket) do
    preset = Enum.find(Workflows.industry_presets(), & Atom.to_string(&1.key) == preset_key)

    if preset do
      {:noreply, assign(socket, :statuses, preset.statuses)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_status", _params, socket) do
    new_status = %{
      is_new: true,
      index: length(socket.assigns.statuses),
      key: "",
      label: "",
      color: "#6B7280"
    }
    {:noreply, assign(socket, :editing_status, new_status)}
  end

  @impl true
  def handle_event("edit_status", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    status = Enum.at(socket.assigns.statuses, index)

    editing = %{
      is_new: false,
      index: index,
      key: get_field(status, :key, ""),
      label: get_field(status, :label, ""),
      color: get_field(status, :color, "#6B7280")
    }
    {:noreply, assign(socket, :editing_status, editing)}
  end

  @impl true
  def handle_event("close_editor", _params, socket) do
    {:noreply, assign(socket, :editing_status, nil)}
  end

  @impl true
  def handle_event("save_status", params, socket) do
    index = String.to_integer(params["index"])
    statuses = socket.assigns.statuses

    new_status = %{
      "key" => params["key"],
      "label" => params["label"],
      "color" => params["color"],
      "order" => index + 1
    }

    updated_statuses =
      if index >= length(statuses) do
        statuses ++ [new_status]
      else
        List.replace_at(statuses, index, new_status)
      end

    {:noreply,
     socket
     |> assign(:statuses, updated_statuses)
     |> assign(:editing_status, nil)}
  end

  @impl true
  def handle_event("delete_status", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    updated_statuses = List.delete_at(socket.assigns.statuses, index)
    {:noreply, assign(socket, :statuses, updated_statuses)}
  end

  @impl true
  def handle_event("save_all", _params, socket) do
    org = socket.assigns.current_organization

    # Convert statuses to proper format
    statuses = Enum.map(socket.assigns.statuses, fn status ->
      %{
        "key" => get_field(status, :key, ""),
        "label" => get_field(status, :label, ""),
        "color" => get_field(status, :color, "#6B7280"),
        "order" => get_field(status, :order, 0)
      }
    end)

    case Accounts.update_organization(org, %{job_status_config: statuses}) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workflow settings saved!")
         |> push_navigate(to: ~p"/settings/workflows")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not save workflow settings.")}
    end
  end

  # Helper to get field from map with atom or string keys
  defp get_field(map, key, default) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key)) || default
  end
end
