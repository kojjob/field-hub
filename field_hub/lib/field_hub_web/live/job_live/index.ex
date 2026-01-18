defmodule FieldHubWeb.JobLive.Index do
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs
  alias FieldHub.Jobs.Job
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
      |> assign(:current_user, current_user)

    {:ok, stream(socket, :jobs, load_jobs(socket))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Job")
    |> assign(:job, Jobs.get_job!(socket.assigns.current_organization.id, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Job")
    |> assign(:job, %Job{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Jobs")
    |> assign(:job, nil)
  end

  @impl true
  def handle_info({:job_created, job}, socket) do
    # Preload associations for display
    job = FieldHub.Repo.preload(job, [:customer, :technician])
    {:noreply, stream_insert(socket, :jobs, job, at: 0)}
  end

  @impl true
  def handle_info({:job_updated, job}, socket) do
    # Preload associations for display
    job = FieldHub.Repo.preload(job, [:customer, :technician])
    {:noreply, stream_insert(socket, :jobs, job)}
  end

  @impl true
  def handle_info({FieldHubWeb.JobLive.FormComponent, {:saved, job}}, socket) do
    # Preload associations for display
    job = FieldHub.Repo.preload(job, [:customer, :technician])
    {:noreply, stream_insert(socket, :jobs, job)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    job = Jobs.get_job!(socket.assigns.current_organization.id, id)
    {:ok, _} = Jobs.delete_job(job)

    {:noreply, stream_delete(socket, :jobs, job)}
  end

  defp load_jobs(socket) do
    Jobs.list_jobs(socket.assigns.current_organization.id)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-2xl font-semibold text-gray-900">Jobs</h1>
          <p class="mt-2 text-sm text-gray-700">
            Manage your service jobs, work orders, and schedules.
          </p>
        </div>
        <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
          <.link patch={~p"/jobs/new"}>
            <.button>New Job</.button>
          </.link>
        </div>
      </div>

      <div class="mt-8 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            <.table
              id="jobs"
              rows={@streams.jobs}
              row_click={fn {_id, job} -> JS.navigate(~p"/jobs/#{job}") end}
            >
              <:col :let={{_id, job}} label="Details">
                <div class="flex items-center gap-x-3">
                  <div class="flex-auto">
                    <div class="font-semibold text-gray-900"><%= job.number %></div>
                    <div class="text-sm text-gray-500"><%= job.title %></div>
                  </div>
                </div>
              </:col>
              <:col :let={{_id, job}} label="Customer">
                <%= if job.customer do %>
                  <div class="font-medium text-gray-900"><%= job.customer.name %></div>
                  <div class="text-sm text-gray-500"><%= job.customer.email %></div>
                <% else %>
                  <span class="text-gray-400 italic">No customer</span>
                <% end %>
              </:col>
              <:col :let={{_id, job}} label="Status">
                <span class={["inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset", status_color(job.status)]}>
                  <%= String.capitalize(job.status) %>
                </span>
              </:col>
              <:col :let={{_id, job}} label="Date">
                <%= if job.scheduled_date do %>
                  <%= job.scheduled_date %>
                <% else %>
                  <span class="text-gray-400">Unscheduled</span>
                <% end %>
              </:col>
              <:action :let={{_id, job}}>
                <div class="sr-only">
                  <.link navigate={~p"/jobs/#{job}"}>Show</.link>
                </div>
                <.link patch={~p"/jobs/#{job}/edit"}>Edit</.link>
              </:action>
              <:action :let={{id, job}}>
                <.link
                  phx-click={JS.push("delete", value: %{id: job.id}) |> hide("##{id}")}
                  data-confirm="Are you sure?"
                >
                  Delete
                </.link>
              </:action>
            </.table>
          </div>
        </div>
      </div>

      <.modal :if={@live_action in [:new, :edit]} id="job-modal" show on_cancel={JS.patch(~p"/jobs")}>
        <.live_component
          module={FieldHubWeb.JobLive.FormComponent}
          id={@job.id || :new}
          title={@page_title}
          action={@live_action}
          job={@job}
          current_organization={@current_organization}
          current_user={@current_user}
          patch={~p"/jobs"}
        />
      </.modal>
    </div>
    """
  end

  defp status_color("unscheduled"), do: "bg-gray-50 text-gray-600 ring-gray-500/10"
  defp status_color("scheduled"), do: "bg-blue-50 text-blue-700 ring-blue-700/10"
  defp status_color("dispatched"), do: "bg-indigo-50 text-indigo-700 ring-indigo-700/10"
  defp status_color("en_route"), do: "bg-purple-50 text-purple-700 ring-purple-700/10"
  defp status_color("on_site"), do: "bg-yellow-50 text-yellow-800 ring-yellow-600/20"
  defp status_color("in_progress"), do: "bg-green-50 text-green-700 ring-green-600/20"
  defp status_color("completed"), do: "bg-emerald-50 text-emerald-700 ring-emerald-600/20"
  defp status_color("cancelled"), do: "bg-red-50 text-red-700 ring-red-600/10"
  defp status_color(_), do: "bg-gray-50 text-gray-600 ring-gray-500/10"
end
