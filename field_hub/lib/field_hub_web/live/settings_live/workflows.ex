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
      |> assign(:current_nav, :workflows)
      |> assign(:statuses, statuses)
      |> assign(:presets, Workflows.industry_presets())
      |> assign(:editing_status, nil)
      |> assign(:task_label_plural, task_label_plural)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-4rem)] overflow-hidden">
      <!-- Main Content Area -->
      <div class={[
        "flex-1 flex flex-col min-w-0 transition-all duration-300 overflow-y-auto",
        @editing_status && "lg:mr-[480px]"
      ]}>
        <div class="space-y-10 p-6 pb-20">
          <!-- Page Heading (matches dashboard) -->
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
                System
              </p>
              <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
                Lifecycle & Workflows
              </h2>
              <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 max-w-lg">
                Define the lifecycle of your {@task_label_plural |> String.downcase()}. Customize statuses and their transitions to match your operations.
              </p>
            </div>
            <div class="flex flex-wrap items-center gap-3">
              <.link navigate={~p"/dashboard"}>
                <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
                  <.icon name="hero-arrow-left" class="size-4" /> Back
                </button>
              </.link>
              <button
                type="button"
                phx-click="add_status"
                class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2"
              >
                <.icon name="hero-plus" class="size-4" /> Add Status
              </button>
              <button
                type="button"
                phx-click="save_all"
                class="bg-primary hover:brightness-110 text-white px-6 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
              >
                <.icon name="hero-check" class="size-5" /> Save Workflow
              </button>
            </div>
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-12 gap-8">
            <!-- Main Content -->
            <div class="xl:col-span-8 space-y-8">
              <!-- Active Phases Card -->
              <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/50 flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <div class="size-8 rounded-lg bg-primary/10 flex items-center justify-center">
                      <.icon name="hero-list-bullet" class="size-4 text-primary" />
                    </div>
                    <h3 class="text-sm font-black text-zinc-900 dark:text-white uppercase tracking-wider">
                      Active Phases
                    </h3>
                  </div>
                  <span class="text-[10px] font-black text-zinc-400 tracking-widest uppercase">
                    {length(@statuses)} Total Phases
                  </span>
                </div>

                <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
                  <%= for {status, index} <- Enum.with_index(@statuses) do %>
                    <div class="group p-5 flex items-center gap-5 hover:bg-zinc-50 dark:hover:bg-zinc-800/30 transition-all">
                      <div class="flex flex-col items-center gap-1.5 text-zinc-300 dark:text-zinc-600">
                        <button
                          phx-click="move_up"
                          phx-value-index={index}
                          class="hover:text-primary disabled:opacity-30 p-1"
                          disabled={index == 0}
                        >
                          <.icon name="hero-chevron-up" class="size-4" />
                        </button>
                        <button
                          phx-click="move_down"
                          phx-value-index={index}
                          class="hover:text-primary disabled:opacity-30 p-1"
                          disabled={index == length(@statuses) - 1}
                        >
                          <.icon name="hero-chevron-down" class="size-4" />
                        </button>
                      </div>

                      <div
                        class="size-5 rounded-lg shrink-0 shadow-sm border border-black/5 dark:border-white/5"
                        style={"background-color: #{get_field(status, :color, "#6B7280")}"}
                      >
                      </div>

                      <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-3">
                          <span class="font-black text-zinc-900 dark:text-white text-lg tracking-tight">
                            {get_field(status, :label, "Status")}
                          </span>
                          <span class="px-2 py-0.5 rounded-md bg-zinc-100 dark:bg-zinc-800 text-[10px] font-black text-zinc-400 uppercase tracking-widest border border-zinc-200 dark:border-zinc-700">
                            {get_field(status, :key, "")}
                          </span>
                        </div>
                      </div>

                      <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-all transform translate-x-4 group-hover:translate-x-0">
                        <button
                          type="button"
                          phx-click="edit_status"
                          phx-value-index={index}
                          class="size-10 rounded-xl bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-500 hover:text-primary hover:border-primary/30 flex items-center justify-center transition-all shadow-sm"
                        >
                          <.icon name="hero-pencil-square" class="size-5" />
                        </button>
                        <button
                          type="button"
                          phx-click="delete_status"
                          phx-value-index={index}
                          class="size-10 rounded-xl bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-500 hover:text-red-500 hover:border-red-500/30 flex items-center justify-center transition-all shadow-sm"
                          data-confirm="Are you sure you want to delete this phase?"
                        >
                          <.icon name="hero-trash" class="size-5" />
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>

                <%= if Enum.empty?(@statuses) do %>
                  <div class="p-20 text-center">
                    <div class="size-20 rounded-full bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mx-auto mb-6">
                      <.icon name="hero-square-3-stack-3d" class="size-10 text-zinc-400" />
                    </div>
                    <h3 class="text-xl font-black text-zinc-900 dark:text-white tracking-tight">
                      No statuses defined
                    </h3>
                    <p class="text-sm font-bold text-zinc-500 mt-2 uppercase tracking-wide">
                      Add your first status or apply a template to get started.
                    </p>
                  </div>
                <% end %>
              </div>
              
    <!-- Visual Workflow Preview -->
              <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 p-8 shadow-sm">
                <div class="flex items-center gap-3 mb-8">
                  <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center">
                    <.icon name="hero-arrow-right-circle" class="size-6 text-primary" />
                  </div>
                  <div>
                    <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                      Workflow Visualization
                    </h3>
                    <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                      Progression path for {@task_label_plural |> String.downcase()}
                    </p>
                  </div>
                </div>

                <div class="flex items-center flex-wrap gap-4">
                  <%= for {status, index} <- Enum.with_index(@statuses) do %>
                    <div class="flex items-center gap-4">
                      <div class="relative flex flex-col items-center group">
                        <div
                          class="px-5 py-3 rounded-2xl border-2 bg-white dark:bg-zinc-950 shadow-lg flex items-center gap-3 transition-transform hover:scale-105"
                          style={"border-color: #{get_field(status, :color, "#6B7280")}40"}
                        >
                          <div
                            class="size-3 rounded-full"
                            style={"background-color: #{get_field(status, :color, "#6B7280")}"}
                          >
                          </div>
                          <span class="text-xs font-black text-zinc-700 dark:text-zinc-200 uppercase tracking-widest">
                            {get_field(status, :label, "Status")}
                          </span>
                        </div>
                      </div>
                      <%= if index < length(@statuses) - 1 do %>
                        <div class="flex items-center justify-center px-1">
                          <.icon
                            name="hero-chevron-right"
                            class="size-5 text-zinc-300 dark:text-zinc-700 animate-pulse"
                          />
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
            
    <!-- Sidebar / Presets -->
            <div class="xl:col-span-4 space-y-6">
              <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm sticky top-8">
                <div class="flex items-center gap-3 mb-6">
                  <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                    <.icon name="hero-sparkles" class="text-primary size-6" />
                  </div>
                  <div>
                    <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                      Industry Templates
                    </h3>
                    <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                      Optimized for your sector
                    </p>
                  </div>
                </div>

                <div class="space-y-3">
                  <%= for preset <- @presets do %>
                    <button
                      type="button"
                      phx-click="apply_preset"
                      phx-value-preset={preset.key |> Atom.to_string()}
                      class="w-full p-4 rounded-2xl border border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/50 hover:border-primary hover:bg-white dark:hover:bg-zinc-800 transition-all group shadow-sm text-left"
                    >
                      <div class="flex items-center justify-between mb-1.5">
                        <span class="text-sm font-black text-zinc-900 dark:text-white group-hover:text-primary transition-colors">
                          {preset.name}
                        </span>
                        <.icon
                          name="hero-arrow-path"
                          class="size-4 text-zinc-400 group-hover:text-primary transition-colors group-hover:rotate-180 duration-500"
                        />
                      </div>
                      <p class="text-[11px] font-bold text-zinc-500 uppercase tracking-wide leading-tight line-clamp-2">
                        {preset.description}
                      </p>
                    </button>
                  <% end %>
                </div>

                <div class="mt-8 p-6 bg-primary/5 rounded-[24px] border border-primary/10 relative overflow-hidden">
                  <div class="relative z-10 flex gap-4">
                    <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                      <.icon name="hero-light-bulb" class="size-6 text-primary" />
                    </div>
                    <div>
                      <h3 class="text-sm font-black text-zinc-900 dark:text-white tracking-tight">
                        Pro Tip
                      </h3>
                      <p class="text-[11px] font-bold text-zinc-500 dark:text-zinc-400 mt-1 leading-relaxed uppercase tracking-wider">
                        The order of statuses defines the default progression.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Slide-in Status Editor Panel -->
      <div
        :if={@editing_status}
        class="fixed right-0 top-0 bottom-0 w-[480px] bg-white dark:bg-zinc-900 border-l border-zinc-200 dark:border-zinc-700 shadow-2xl z-50 flex flex-col animate-in slide-in-from-right duration-300"
      >
        <!-- Form Panel Header -->
        <div class="p-6 border-b border-zinc-200 dark:border-zinc-700 bg-zinc-50/50 dark:bg-zinc-800/20 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-black text-zinc-900 dark:text-white tracking-tighter">
              {if @editing_status.is_new, do: "Add New Phase", else: "Modify Phase"}
            </h2>
            <p class="text-sm font-bold text-zinc-500 mt-1 uppercase tracking-wide">
              Configure progression details
            </p>
          </div>
          <button
            phx-click="close_editor"
            class="size-8 rounded-lg hover:bg-zinc-100 dark:hover:bg-zinc-800 flex items-center justify-center text-zinc-400 hover:text-zinc-600 transition-all"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>
        
    <!-- Form Content -->
        <div class="flex-1 overflow-y-auto p-8">
          <form phx-submit="save_status" class="space-y-8">
            <input type="hidden" name="index" value={@editing_status.index} />

            <div class="grid grid-cols-1 gap-8">
              <div class="space-y-2">
                <label class="block text-sm font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest">
                  Display Label
                </label>
                <input
                  type="text"
                  name="label"
                  value={@editing_status.label}
                  class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium"
                  placeholder="e.g. In Progress"
                  required
                />
              </div>

              <div class="space-y-2">
                <label class="block text-sm font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest">
                  Unique Key
                </label>
                <input
                  type="text"
                  name="key"
                  value={@editing_status.key}
                  class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-mono text-sm uppercase"
                  placeholder="in_progress"
                  pattern="[a-z_]+"
                  required
                />
              </div>
            </div>

            <div class="bg-zinc-50 dark:bg-zinc-950 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800">
              <label class="block text-sm font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest mb-6 text-center">
                Visual Identifier (Color)
              </label>
              <div class="flex flex-col items-center gap-8">
                <div class="flex flex-col items-center gap-6">
                  <input
                    type="color"
                    name="color"
                    value={@editing_status.color}
                    class="size-20 rounded-2xl border-2 border-zinc-300 dark:border-zinc-700 cursor-pointer p-1 bg-white dark:bg-zinc-800 shadow-xl"
                  />
                  <div class="flex flex-col items-center">
                    <p class="text-[10px] font-black text-zinc-400 mb-3 uppercase tracking-[0.2em]">
                      Live Preview
                    </p>
                    <div
                      class="px-6 py-3 rounded-2xl border-2 shadow-lg flex items-center gap-3 bg-white dark:bg-zinc-900"
                      style={"border-color: #{@editing_status.color}40"}
                    >
                      <div
                        class="size-3 rounded-full"
                        style={"background-color: #{@editing_status.color}"}
                      >
                      </div>
                      <span
                        class="text-xs font-black uppercase tracking-widest"
                        style={"color: #{@editing_status.color}"}
                      >
                        {(@editing_status.label != "" && @editing_status.label) || "PREVIEW"}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-3 pt-4">
              <button
                type="button"
                phx-click="close_editor"
                class="px-6 py-3 rounded-xl text-sm font-bold text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-10 py-3 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
              >
                {if @editing_status.is_new, do: "Add Phase", else: "Apply Changes"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
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
