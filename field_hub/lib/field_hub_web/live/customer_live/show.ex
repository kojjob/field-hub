defmodule FieldHubWeb.CustomerLive.Show do
  use FieldHubWeb, :live_view

  alias FieldHub.CRM

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    org_id = current_user.organization_id

    socket = assign(socket, :current_organization, %FieldHub.Accounts.Organization{id: org_id})
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    customer = CRM.get_customer!(socket.assigns.current_organization.id, id)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:customer, customer)}
  end

  @impl true
  def handle_info({FieldHubWeb.CustomerLive.FormComponent, {:saved, customer}}, socket) do
    {:noreply, assign(socket, :customer, customer)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-8 sm:px-6 lg:px-8">
      <.header>
        Customer {@customer.name}
        <:subtitle>This is a customer record from your database.</:subtitle>
        <:actions>
          <.link patch={~p"/customers/#{@customer}/edit"} phx-click={JS.push_focus()}>
            <.button>Edit customer</.button>
          </.link>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@customer.name}</:item>
        <:item title="Email">{@customer.email}</:item>
        <:item title="Phone">{@customer.phone}</:item>
        <:item title="Address">
          {FieldHub.CRM.Customer.full_address(@customer)}
        </:item>
      </.list>

      <.back navigate={~p"/customers"}>Back to customers</.back>

      <.modal :if={@live_action == :edit} id="customer-modal" show on_cancel={JS.patch(~p"/customers/#{@customer}")}>
        <.live_component
          module={FieldHubWeb.CustomerLive.FormComponent}
          id={@customer.id}
          title={@page_title}
          action={@live_action}
          customer={@customer}
          current_organization={@current_organization}
          patch={~p"/customers/#{@customer}"}
        />
      </.modal>
    </div>
    """
  end

  defp page_title(:show), do: "Show Customer"
  defp page_title(:edit), do: "Edit Customer"
end
