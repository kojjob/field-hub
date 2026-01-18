defmodule FieldHubWeb.JobLive.Show do
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs
  alias FieldHub.Dispatch.Broadcaster

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    org_id = current_user.organization_id

    socket =
      socket
      |> assign(:current_organization, %FieldHub.Accounts.Organization{id: org_id})
      |> assign(:current_user, current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    org_id = socket.assigns.current_organization.id

    if connected?(socket) do
      Broadcaster.subscribe_to_org(org_id)
    end

    job = Jobs.get_job!(org_id, id) |> FieldHub.Repo.preload([:customer, :technician])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:job, job)}
  end

  # Real-time updates
  @impl true
  def handle_info({:job_updated, updated_job}, socket) do
    if updated_job.id == socket.assigns.job.id do
      job =
        Jobs.get_job!(socket.assigns.current_organization.id, updated_job.id)
        |> FieldHub.Repo.preload([:customer, :technician])

      {:noreply, assign(socket, :job, job)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({FieldHubWeb.JobLive.FormComponent, {:saved, job}}, socket) do
    # The saved job might not have preloads, so reload.
    handle_info({:job_updated, job}, socket)
  end

  # Catch-all for other messages we might subscribe to but don't care about here
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Job {@job.number}
      <:subtitle>
        <span class={[
          "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
          status_color(@job.status)
        ]}>
          {String.capitalize(@job.status)}
        </span>
      </:subtitle>
      <:actions>
        <.link patch={~p"/jobs/#{@job}/edit"} phx-click={JS.push_focus()}>
          <.button>Edit job</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Title">{@job.title}</:item>
      <:item title="Description">{@job.description}</:item>
      <:item title="Type">{String.capitalize(@job.job_type)}</:item>
      <:item title="Priority">{String.capitalize(@job.priority)}</:item>

      <:item title="Scheduled Date">
        {if @job.scheduled_date, do: @job.scheduled_date, else: "Unscheduled"}
      </:item>

      <:item title="Customer">
        <%= if @job.customer do %>
          {@job.customer.name} ({@job.customer.phone})
        <% else %>
          -
        <% end %>
      </:item>

      <:item title="Technician">
        <%= if @job.technician do %>
          <span class="flex items-center gap-2">
            <span class="w-3 h-3 rounded-full" style={"background-color: #{@job.technician.color}"}>
            </span>
            {@job.technician.name}
          </span>
        <% else %>
          Unassigned
        <% end %>
      </:item>
    </.list>

    <.back navigate={~p"/jobs"}>Back to jobs</.back>

    <.modal :if={@live_action == :edit} id="job-modal" show on_cancel={JS.patch(~p"/jobs/#{@job}")}>
      <.live_component
        module={FieldHubWeb.JobLive.FormComponent}
        id={@job.id}
        title={@page_title}
        action={@live_action}
        job={@job}
        current_organization={@current_organization}
        current_user={@current_user}
        patch={~p"/jobs/#{@job}"}
      />
    </.modal>
    """
  end

  defp page_title(:show), do: "Show Job"
  defp page_title(:edit), do: "Edit Job"

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
