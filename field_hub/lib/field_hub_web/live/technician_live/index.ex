defmodule FieldHubWeb.TechnicianLive.Index do
  use FieldHubWeb, :live_view

  alias FieldHub.Dispatch
  alias FieldHub.Dispatch.Technician

  alias FieldHub.Dispatch.Broadcaster

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    org_id = current_user.organization_id

    if connected?(socket) do
      Broadcaster.subscribe_to_org(org_id)
    end

    socket =
      socket
      |> assign(:current_organization, %FieldHub.Accounts.Organization{id: org_id})
      |> assign(:current_nav, :technicians)
      |> assign(:search, "")

    technicians = load_technicians(socket)
    {:ok, socket |> assign(:has_technicians, technicians != []) |> stream(:technicians, technicians)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Technician")
    |> assign(:technician, Dispatch.get_technician!(socket.assigns.current_organization.id, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Technician")
    |> assign(:technician, %Technician{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Technicians")
    |> assign(:technician, nil)
    technicians = load_technicians(socket)

    socket
    |> assign(:page_title, "Technicians")
    |> assign(:technician, nil)
    |> assign(:has_technicians, technicians != [])
    |> stream(:technicians, technicians, reset: true)
  end

  defp load_technicians(socket) do
    org_id = socket.assigns.current_organization.id
    search = socket.assigns.search

    if search == "" do
      Dispatch.list_technicians(org_id)
    else
      Dispatch.search_technicians(org_id, search)
    end
  end

  @impl true
  def handle_info({FieldHubWeb.TechnicianLive.FormComponent, {:saved, technician}}, socket) do
    {:noreply, stream_insert(socket, :technicians, technician)}
  end

  def handle_info({:technician_created, technician}, socket) do
    {:noreply, stream_insert(socket, :technicians, technician)}
  end

  def handle_info({:technician_updated, technician}, socket) do
    {:noreply, stream_insert(socket, :technicians, technician)}
  end

  def handle_info({:technician_status_updated, technician}, socket) do
    {:noreply, stream_insert(socket, :technicians, technician)}
  end

  def handle_info({:technician_archived, technician}, socket) do
    {:noreply, stream_delete(socket, :technicians, technician)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    technician = Dispatch.get_technician!(socket.assigns.current_organization.id, id)
    {:ok, _} = Dispatch.archive_technician(technician)

    {:noreply, stream_delete(socket, :technicians, technician)}
  end

  def handle_event("search", %{"search" => search}, socket) do
    socket = assign(socket, :search, search)
    technicians = load_technicians(socket)
    {:noreply,
     socket
     |> assign(:has_technicians, technicians != [])
     |> stream(:technicians, technicians, reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""

      <div class="flex h-[calc(100vh-4rem)] overflow-hidden relative">
      <!-- Main Content Area -->
      <div class={[
        "flex-1 flex flex-col min-w-0 transition-all duration-300",
        @live_action in [:new, :edit] && "lg:mr-[480px]"
      ]}>
        <div class="px-6 py-4 bg-white dark:bg-zinc-900 border-b border-zinc-200 dark:border-zinc-800">
          <div class="flex items-center justify-between gap-4">
            <form phx-change="search" id="search-form" class="flex-1 max-w-lg">
              <div class="relative">
                <.icon
                  name="hero-magnifying-glass"
                  class="absolute left-4 top-1/2 -tranzinc-y-1/2 text-zinc-400 size-5"
                />
                <input
                  type="text"
                  name="search"
                  value={@search}
                  placeholder="Search by name, email, or skills..."
                  phx-debounce="300"
                  class="w-full pl-12 pr-4 py-2 bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-200 dark:border-zinc-700 rounded-xl text-sm font-medium text-zinc-700 dark:text-zinc-200 placeholder:text-zinc-400 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all font-dashboard"
                />
              </div>
            </form>

            <div class="flex items-center gap-3">
              <button class="flex items-center gap-2 px-3 py-2 text-xs font-bold text-zinc-600 dark:text-zinc-300 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-xl hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all">
                <.icon name="hero-arrow-down-tray" class="size-4" /> Export
              </button>
              <.link patch={~p"/technicians/new"}>
                <button class="flex items-center gap-2 px-4 py-2 text-sm font-bold text-white bg-primary rounded-xl shadow-lg shadow-primary/20 hover:brightness-110 transition-all">
                  <.icon name="hero-plus" class="size-4" /> Add Technician
                </button>
              </.link>
            </div>
          </div>
        </div>

    <!-- Content Area -->
      <div class="flex-1 overflow-auto bg-zinc-50/50 dark:bg-zinc-900/50 p-6">
        <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
          <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
            <thead class="bg-zinc-50 dark:bg-zinc-800/50">
              <tr>
                <th
                  scope="col"
                  class="py-4 pl-6 pr-3 text-left text-[11px] font-black uppercase tracking-widest text-zinc-400"
                >
                  Technician
                </th>
                <th
                  scope="col"
                  class="px-3 py-4 text-left text-[11px] font-black uppercase tracking-widest text-zinc-400"
                >
                  Status
                </th>
                <th
                  scope="col"
                  class="px-3 py-4 text-left text-[11px] font-black uppercase tracking-widest text-zinc-400"
                >
                  Expertise / Skills
                </th>
                <th
                  scope="col"
                  class="px-3 py-4 text-left text-[11px] font-black uppercase tracking-widest text-zinc-400"
                >
                  Contact Details
                </th>
                <th scope="col" class="relative py-4 pl-3 pr-6 text-right">
                  <span class="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody
              phx-update="stream"
              id="technicians"
              class="divide-y divide-zinc-100 dark:divide-zinc-800"
            >
              <tr
                :for={{id, technician} <- @streams.technicians}
                id={id}
                class="group hover:bg-primary/5 dark:hover:bg-primary/10 transition-colors"
              >
                <td class="whitespace-nowrap py-5 pl-6 pr-3">
                  <div class="flex items-center gap-4">
                    <div
                      class="size-10 rounded-full flex items-center justify-center text-xs font-black text-white shadow-lg shadow-zinc-500/10"
                      style={"background-color: #{technician.color || "#6366f1"}"}
                    >
                      {String.slice(technician.name, 0, 2) |> String.upcase()}
                    </div>
                    <div>
                      <div class="text-sm font-bold text-zinc-900 dark:text-white group-hover:text-primary transition-colors">
                        {technician.name}
                      </div>
                      <div class="text-[10px] font-bold text-zinc-400 uppercase tracking-tighter">
                        ID: #{"#{technician.id}" |> String.slice(-4..-1)}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="whitespace-nowrap px-3 py-5">
                  <span class={[
                    "inline-flex items-center rounded-lg px-2.5 py-1 text-[10px] font-black uppercase tracking-wider border",
                    technician.status == "available" &&
                      "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-900/20 dark:text-emerald-400 dark:border-emerald-800/50",
                    technician.status == "on_job" &&
                      "bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800/50",
                    technician.status == "offline" &&
                      "bg-zinc-50 text-zinc-600 border-zinc-200 dark:bg-zinc-800 dark:text-zinc-400 dark:border-zinc-700",
                    technician.status == "off_duty" &&
                      "bg-zinc-50 text-zinc-600 border-zinc-200 dark:bg-zinc-800 dark:text-zinc-400 dark:border-zinc-700"
                  ]}>
                    {technician.status |> String.replace("_", " ") |> String.capitalize()}
                  </span>
                </td>
                <td class="px-3 py-5">
                  <div class="flex gap-1.5 flex-wrap max-w-[200px]">
                    <%= for skill <- technician.skills || [] do %>
                      <span class="inline-flex items-center rounded-md bg-zinc-100 dark:bg-zinc-800 px-2 py-0.5 text-[10px] font-bold text-zinc-600 dark:text-zinc-300 uppercase tracking-tight">
                        {skill}
                      </span>
                    <% end %>
                  </div>
                </td>
                <td class="whitespace-nowrap px-3 py-5">
                  <div class="flex flex-col gap-1">
                    <div class="flex items-center gap-1.5 text-sm font-medium text-zinc-700 dark:text-zinc-300">
                      <.icon name="hero-envelope" class="size-3.5 text-zinc-400" />
                      {technician.email}
                    </div>
                    <div class="flex items-center gap-1.5 text-xs text-zinc-400 font-medium">
                      <.icon name="hero-phone" class="size-3.5" />
                      {technician.phone}
                    </div>
                  </div>
                </td>
                <td class="relative whitespace-nowrap py-5 pl-3 pr-6 text-right">
                  <div class="flex items-center justify-end gap-2">
                    <.link
                      patch={~p"/technicians/#{technician}/edit"}
                      phx-hook="StopPropagation"
                      class="p-2 rounded-xl hover:bg-white dark:hover:bg-zinc-800 hover:text-primary dark:text-zinc-400 dark:hover:text-primary transition-all"
                    >
                      <.icon name="hero-pencil-square" class="size-5" />
                    </.link>
                    <.link
                      phx-click={JS.push("delete", value: %{id: technician.id}) |> hide("##{id}")}
                      phx-hook="StopPropagation"
                      data-confirm="Are you sure you want to retire this technician?"
                      class="p-2 rounded-xl hover:bg-white dark:hover:bg-zinc-800 hover:text-red-600 dark:text-zinc-400 dark:hover:text-red-400 transition-all"
                    >
                      <.icon name="hero-trash" class="size-5" />
                    </.link>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
          <%= if not @has_technicians do %>
            <div class="flex flex-col items-center justify-center py-20 bg-white dark:bg-zinc-900">
              <div class="size-16 rounded-2xl bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center mb-4">
                <.icon name="hero-magnifying-glass" class="size-8 text-zinc-300 dark:text-zinc-600" />
              </div>
              <h3 class="text-sm font-bold text-zinc-900 dark:text-white mb-1">No technicians found</h3>
              <p class="text-xs text-zinc-500 dark:text-zinc-400">Try adjusting your search terms</p>
            </div>
          <% end %>
      </div>
      </div>
    </div>

      <!-- Slide-over Panel -->
      <div
        :if={@live_action in [:new, :edit]}
        class="fixed top-16 bottom-0 right-0 w-[480px] bg-white dark:bg-zinc-900 border-l border-zinc-200 dark:border-zinc-800 shadow-2xl z-40 animate-in slide-in-from-right duration-300"
      >
        <div class="h-full flex flex-col">
          <!-- Slide-over Header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-zinc-200 dark:border-zinc-800">
            <h2 class="text-lg font-bold text-zinc-900 dark:text-white">
              <%= if @live_action == :new, do: "New Technician", else: "Edit Technician" %>
            </h2>
            <.link patch={~p"/technicians"} class="p-2 -mr-2 text-zinc-400 hover:text-zinc-500 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-lg transition-colors">
              <.icon name="hero-x-mark" class="size-5" />
            </.link>
          </div>

          <!-- Slide-over Content -->
          <div class="flex-1 overflow-y-auto p-6">
            <.live_component
              module={FieldHubWeb.TechnicianLive.FormComponent}
              id={@technician.id || :new}
              title={@page_title}
              action={@live_action}
              technician={@technician}
              current_organization={@current_organization}
              patch={~p"/technicians"}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
