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

    socket = assign(socket, :current_organization, %FieldHub.Accounts.Organization{id: org_id})
    {:ok, stream(socket, :technicians, [])}
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
    |> stream(:technicians, Dispatch.list_technicians(socket.assigns.current_organization.id), reset: true)
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-8 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-base font-semibold leading-6 text-zinc-900 dark:text-zinc-100">Technicians</h1>
          <p class="mt-2 text-sm text-zinc-700 dark:text-zinc-300">
            A list of all the technicians in your organization including their name, status, and expertise.
          </p>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
          <.link patch={~p"/technicians/new"}>
            <button type="button" class="block rounded-md bg-indigo-600 px-3 py-2 text-center text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
              New Technician
            </button>
          </.link>
        </div>
      </div>
      <div class="mt-8 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            <table class="min-w-full divide-y divide-zinc-300 dark:divide-zinc-700">
              <thead>
                <tr>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100 sm:pl-0">Name</th>
                  <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">Status</th>
                  <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">Skills</th>
                  <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">Contact</th>
                  <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                    <span class="sr-only">Edit</span>
                  </th>
                </tr>
              </thead>
              <tbody phx-update="stream" id="technicians" class="divide-y divide-zinc-200 dark:divide-zinc-800">
                <tr :for={{id, technician} <- @streams.technicians} id={id} class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/50">
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-zinc-900 dark:text-zinc-100 sm:pl-0">
                    <div class="flex items-center gap-x-3">
                      <div class="h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold text-white" style={"background-color: #{technician.color || "#6366f1"}"}>
                        {String.slice(technician.name, 0, 2) |> String.upcase()}
                      </div>
                      {technician.name}
                    </div>
                  </td>
                  <td class="whitespace-nowrap px-3 py-4 text-sm text-zinc-500 dark:text-zinc-400">
                    <span class={[
                      "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
                      technician.status == "available" && "bg-green-50 text-green-700 ring-green-600/20 dark:bg-green-900/30 dark:text-green-400 dark:ring-green-400/20",
                      technician.status == "on_job" && "bg-blue-50 text-blue-700 ring-blue-600/20 dark:bg-blue-900/30 dark:text-blue-400 dark:ring-blue-400/20",
                      technician.status == "offline" && "bg-gray-50 text-gray-700 ring-gray-600/20 dark:bg-gray-900/30 dark:text-gray-400 dark:ring-gray-400/20",
                      technician.status == "off_duty" && "bg-zinc-50 text-zinc-700 ring-zinc-600/20 dark:bg-zinc-900/30 dark:text-zinc-400 dark:ring-zinc-400/20"
                    ]}>
                      {technician.status |> String.replace("_", " ") |> String.capitalize()}
                    </span>
                  </td>
                  <td class="whitespace-nowrap px-3 py-4 text-sm text-zinc-500 dark:text-zinc-400">
                    <div class="flex gap-1 flex-wrap">
                      <span :for={skill <- technician.skills || []} class="inline-flex items-center rounded-sm bg-zinc-100 px-1.5 py-0.5 text-xs font-medium text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300">
                        {skill}
                      </span>
                    </div>
                  </td>
                  <td class="whitespace-nowrap px-3 py-4 text-sm text-zinc-500 dark:text-zinc-400">
                    <div>{technician.email}</div>
                    <div class="text-xs">{technician.phone}</div>
                  </td>
                  <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                    <div class="flex items-center justify-end gap-2">
                      <.link patch={~p"/technicians/#{technician}/edit"} class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300">
                        Edit<span class="sr-only">, {technician.name}</span>
                      </.link>
                      <.link
                        phx-click={JS.push("delete", value: %{id: technician.id}) |> hide("##{id}")}
                        data-confirm="Are you sure?"
                        class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                      >
                        Delete
                      </.link>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <.modal :if={@live_action in [:new, :edit]} id="technician-modal" show on_cancel={JS.patch(~p"/technicians")}>
        <.live_component
          module={FieldHubWeb.TechnicianLive.FormComponent}
          id={@technician.id || :new}
          title={@page_title}
          action={@live_action}
          technician={@technician}
          current_organization={@current_organization}
          patch={~p"/technicians"}
        />
      </.modal>
    </div>
    """
  end
end
