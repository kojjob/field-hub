defmodule FieldHubWeb.SettingsLive.Workflows do
  @moduledoc """
  Settings page for configuring organization job statuses and workflows.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Config.Workflows
  alias FieldHub.Config.Terminology

  @impl true
  def mount(_params, _session, socket) do
    org = socket.assigns.current_organization
    statuses = Workflows.get_statuses(org)

    # Get custom label for "Jobs" from terminology
    task_label_plural = Terminology.get_label(org, :task, :plural)

    socket =
      socket
      |> assign(:page_title, "Workflow Settings")
      |> assign(:statuses, statuses)
      |> assign(:presets, Workflows.industry_presets())
      |> assign(:editing_status, nil)
      |> assign(:task_label_plural, task_label_plural)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto">
      <div class="mb-8 flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-zinc-900 dark:text-white tracking-tight">
            Workflow Settings
          </h1>
          <p class="mt-2 text-zinc-600 dark:text-zinc-400 max-w-2xl">
            Define the lifecycle of your {@task_label_plural |> String.downcase()}. Customize statuses and their transitions to match your operations.
          </p>
        </div>
        <div class="flex gap-2">
          <.button type="button" phx-click="add_status" variant="outline" class="gap-2">
            <.icon name="hero-plus" class="size-4" /> Add Status
          </.button>
          <.button
            type="button"
            phx-click="save_all"
            variant="primary"
            class="gap-2 shadow-lg shadow-indigo-600/20"
          >
            <.icon name="hero-check" class="size-4" /> Save Workflow
          </.button>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <!-- Main Content -->
        <div class="lg:col-span-8 space-y-6">
          <div class="bg-white dark:bg-zinc-800/50 rounded-2xl shadow-sm border border-zinc-200 dark:border-zinc-700/50 overflow-hidden">
            <div class="p-4 border-b border-zinc-100 dark:border-zinc-700/50 bg-zinc-50/50 dark:bg-zinc-900/50 flex items-center justify-between">
              <h2 class="text-sm font-semibold text-zinc-900 dark:text-white flex items-center gap-2">
                <.icon name="hero-list-bullet" class="size-4 text-zinc-400" /> Active Phases
              </h2>
              <span class="text-[10px] font-medium text-zinc-400 tracking-wider uppercase">
                Order by sequence
              </span>
            </div>

            <div class="divide-y divide-zinc-100 dark:divide-zinc-700/50">
              <%= for {status, index} <- Enum.with_index(@statuses) do %>
                <div class="group p-4 flex items-center gap-4 hover:bg-zinc-50 dark:hover:bg-zinc-900/30 transition-colors">
                  <div class="flex flex-col items-center gap-1 text-zinc-300 dark:text-zinc-600">
                    <button
                      phx-click="move_up"
                      phx-value-index={index}
                      class="hover:text-indigo-600 disabled:opacity-30"
                      disabled={index == 0}
                    >
                      <.icon name="hero-chevron-up" class="size-4" />
                    </button>
                    <button
                      phx-click="move_down"
                      phx-value-index={index}
                      class="hover:text-indigo-600 disabled:opacity-30"
                      disabled={index == length(@statuses) - 1}
                    >
                      <.icon name="hero-chevron-down" class="size-4" />
                    </button>
                  </div>

                  <div
                    class="size-3 rounded-full shrink-0 shadow-sm"
                    style={"background-color: #{get_field(status, :color, "#6B7280")}"}
                  >
                  </div>

                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2">
                      <span class="font-semibold text-zinc-900 dark:text-white truncate">
                        {get_field(status, :label, "Status")}
                      </span>
                      <span class="px-1.5 py-0.5 rounded bg-zinc-100 dark:bg-zinc-800 text-[10px] font-mono text-zinc-500 uppercase tracking-tighter">
                        {get_field(status, :key, "")}
                      </span>
                    </div>
                  </div>

                  <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      type="button"
                      phx-click="edit_status"
                      phx-value-index={index}
                      class="p-2 text-zinc-500 hover:text-indigo-600"
                    >
                      <.icon name="hero-pencil-square" class="size-4" />
                    </button>
                    <button
                      type="button"
                      phx-click="delete_status"
                      phx-value-index={index}
                      class="p-2 text-zinc-500 hover:text-red-500"
                      data-confirm="Are you sure?"
                    >
                      <.icon name="hero-trash" class="size-4" />
                    </button>
                  </div>
                </div>
              <% end %>
            </div>

            <%= if Enum.empty?(@statuses) do %>
              <div class="p-12 text-center">
                <div class="size-16 rounded-full bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mx-auto mb-4">
                  <.icon name="hero-square-3-stack-3d" class="size-8 text-zinc-400" />
                </div>
                <h3 class="text-zinc-900 dark:text-white font-medium">No statuses defined</h3>
                <p class="text-sm text-zinc-500 mt-1">
                  Add your first status or apply a preset to get started.
                </p>
              </div>
            <% end %>
          </div>
          
    <!-- Visual Workflow Preview -->
          <div class="bg-white dark:bg-zinc-800/50 rounded-[24px] shadow-sm border border-zinc-200 dark:border-zinc-700/50 p-6 overflow-hidden">
            <h2 class="text-base font-semibold text-zinc-900 dark:text-white mb-6">
              Workflow Sequence
            </h2>
            <div class="flex items-center flex-wrap gap-y-8">
              <%= for {status, index} <- Enum.with_index(@statuses) do %>
                <div class="flex items-center">
                  <div class="relative group">
                    <div class="px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-900 shadow-sm flex items-center gap-3">
                      <div
                        class="size-2 rounded-full"
                        style={"background-color: #{get_field(status, :color, "#6B7280")}"}
                      >
                      </div>
                      <span class="text-xs font-bold text-zinc-700 dark:text-zinc-300 uppercase tracking-wider">
                        {get_field(status, :label, "Status")}
                      </span>
                    </div>
                  </div>
                  <%= if index < length(@statuses) - 1 do %>
                    <div class="w-8 h-px bg-zinc-200 dark:bg-zinc-700 relative">
                      <div class="absolute right-0 -top-[3px] border-t-4 border-b-4 border-l-4 border-t-transparent border-b-transparent border-l-zinc-200 dark:border-l-zinc-700">
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Sidebar / Presets -->
        <div class="lg:col-span-4 space-y-6">
          <div class="bg-white dark:bg-zinc-800 rounded-2xl shadow-sm border border-zinc-200 dark:border-zinc-700/50 p-6">
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-white mb-4 flex items-center gap-2">
              <.icon name="hero-sparkles" class="size-5 text-indigo-600" /> Industry Templates
            </h2>
            <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-6">
              Kickstart your workflow with these optimized presets.
            </p>

            <div class="space-y-3">
              <%= for preset <- @presets do %>
                <button
                  type="button"
                  phx-click="apply_preset"
                  phx-value-preset={preset.key |> Atom.to_string()}
                  class="w-full p-4 rounded-xl border border-zinc-100 dark:border-zinc-700 hover:border-indigo-600 hover:bg-indigo-600/5 dark:hover:bg-indigo-600/10 transition-all text-left group"
                >
                  <div class="flex items-center justify-between mb-1">
                    <span class="text-sm font-bold text-zinc-900 dark:text-white group-hover:text-indigo-600">
                      {preset.name}
                    </span>
                    <.icon
                      name="hero-arrow-path"
                      class="size-3.5 text-zinc-400 opacity-0 group-hover:opacity-100 transition-opacity"
                    />
                  </div>
                  <p class="text-xs text-zinc-500 line-clamp-1">{preset.description}</p>
                </button>
              <% end %>
            </div>
          </div>

          <div class="bg-indigo-600/5 border border-indigo-500/10 rounded-2xl p-6">
            <div class="flex gap-3">
              <.icon name="hero-light-bulb" class="size-6 text-indigo-600 shrink-0" />
              <div>
                <h3 class="text-sm font-bold text-indigo-900 dark:text-indigo-400">Pro Tip</h3>
                <p class="text-xs text-indigo-800/80 dark:text-indigo-400/80 mt-1 leading-relaxed">
                  The order of statuses defines the default progression. Status keys like
                  <span class="font-mono">completed</span>
                  or <span class="font-mono">cancelled</span>
                  are used for reporting.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Status Editor Modal -->
    <%= if @editing_status do %>
      <div
        class="fixed inset-0 bg-zinc-950/20 dark:bg-zinc-950/60 backdrop-blur-sm flex items-center justify-center z-50 p-4"
        phx-click="close_editor"
      >
        <div
          class="bg-white dark:bg-zinc-900 rounded-[32px] shadow-2xl border border-zinc-200 dark:border-zinc-800 w-full max-w-lg overflow-hidden"
          phx-click-away="close_editor"
        >
          <div class="px-8 pt-8 pb-6">
            <h3 class="text-2xl font-bold text-zinc-900 dark:text-white">
              {if @editing_status.is_new, do: "New Status", else: "Edit Status"}
            </h3>
            <p class="text-sm text-zinc-500 mt-1">Configure phase details and visual identifier.</p>
          </div>

          <form phx-submit="save_status" class="px-8 pb-8 space-y-6">
            <input type="hidden" name="index" value={@editing_status.index} />

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-semibold text-zinc-700 dark:text-zinc-300 mb-2">
                  Display Label
                </label>
                <input
                  type="text"
                  name="label"
                  value={@editing_status.label}
                  class="w-full px-4 py-3 border border-zinc-300 dark:border-zinc-700 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 focus:ring-2 focus:ring-indigo-600 outline-none transition-all"
                  placeholder="e.g. In Progress"
                  required
                />
              </div>

              <div>
                <label class="block text-sm font-semibold text-zinc-700 dark:text-zinc-300 mb-2">
                  Unique Key
                </label>
                <input
                  type="text"
                  name="key"
                  value={@editing_status.key}
                  class="w-full px-4 py-3 border border-zinc-300 dark:border-zinc-700 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 focus:ring-2 focus:ring-indigo-600 outline-none transition-all font-mono text-sm"
                  placeholder="in_progress"
                  pattern="[a-z_]+"
                  required
                />
              </div>
            </div>

            <div class="bg-zinc-50 dark:bg-zinc-950 p-6 rounded-2xl border border-zinc-200 dark:border-zinc-800">
              <label class="block text-sm font-semibold text-zinc-700 dark:text-zinc-300 mb-4">
                Status Color
              </label>
              <div class="flex items-center gap-8">
                <input
                  type="color"
                  name="color"
                  value={@editing_status.color}
                  class="h-14 w-20 rounded-xl border border-zinc-300 dark:border-zinc-700 cursor-pointer p-1 bg-white dark:bg-zinc-800"
                />
                <div class="flex-1">
                  <p class="text-[10px] text-zinc-400 mb-2 uppercase font-bold tracking-widest">
                    Live Visual
                  </p>
                  <div
                    class="px-5 py-3 rounded-xl border-2 shadow-sm flex items-center gap-3 bg-white dark:bg-zinc-800"
                    style={"border-color: #{@editing_status.color}40"}
                  >
                    <div
                      class="size-3 rounded-full shadow-sm"
                      style={"background-color: #{@editing_status.color}"}
                    >
                    </div>
                    <span
                      class="text-xs font-bold uppercase tracking-wider"
                      style={"color: #{@editing_status.color}"}
                    >
                      PREVIEW STATUS
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-3 pt-4 border-t border-zinc-100 dark:border-zinc-800">
              <button
                type="button"
                phx-click="close_editor"
                class="px-5 py-2.5 text-sm font-semibold text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-white transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-8 py-2.5 bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 font-bold rounded-xl hover:opacity-90 transition-all shadow-lg"
              >
                Save Phase
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end

  @impl true
  def handle_event("apply_preset", %{"preset" => preset_key}, socket) do
    preset = Enum.find(Workflows.industry_presets(), &(Atom.to_string(&1.key) == preset_key))

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
  def handle_event("move_up", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    if index > 0 do
      statuses = socket.assigns.statuses
      item = Enum.at(statuses, index)

      updated =
        statuses
        |> List.delete_at(index)
        |> List.insert_at(index - 1, item)

      {:noreply, assign(socket, :statuses, updated)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move_down", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    statuses = socket.assigns.statuses

    if index < length(statuses) - 1 do
      item = Enum.at(statuses, index)

      updated =
        statuses
        |> List.delete_at(index)
        |> List.insert_at(index + 1, item)

      {:noreply, assign(socket, :statuses, updated)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_all", _params, socket) do
    org = socket.assigns.current_organization

    # Convert statuses to proper format
    statuses =
      Enum.map(Enum.with_index(socket.assigns.statuses), fn {status, idx} ->
        %{
          "key" => get_field(status, :key, ""),
          "label" => get_field(status, :label, ""),
          "color" => get_field(status, :color, "#6B7280"),
          "order" => idx + 1
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
