defmodule FieldHubWeb.CustomerLive.Index do
  use FieldHubWeb, :live_view

  alias FieldHub.CRM
  alias FieldHub.CRM.Customer
  alias FieldHub.CRM.Broadcaster

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
      |> assign(:search, "")
      |> stream(:customers, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Customer")
    |> assign(:customer, CRM.get_customer!(socket.assigns.current_organization.id, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Customer")
    |> assign(:customer, %Customer{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Customers")
    |> assign(:customer, nil)
    |> load_customers(socket.assigns.search)
  end

  defp load_customers(socket, search) do
    org_id = socket.assigns.current_organization.id
    customers =
      if search == "" or is_nil(search) do
        CRM.list_customers(org_id)
      else
        CRM.search_customers(org_id, search)
      end
    stream(socket, :customers, customers, reset: true)
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> load_customers(search)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    customer = CRM.get_customer!(socket.assigns.current_organization.id, id)
    {:ok, _} = CRM.archive_customer(customer)

    {:noreply, stream_delete(socket, :customers, customer)}
  end

  @impl true
  def handle_info({FieldHubWeb.CustomerLive.FormComponent, {:saved, customer}}, socket) do
    {:noreply, stream_insert(socket, :customers, customer)}
  end

  def handle_info({:customer_created, customer}, socket) do
    {:noreply, stream_insert(socket, :customers, customer)}
  end

  def handle_info({:customer_updated, customer}, socket) do
    {:noreply, stream_insert(socket, :customers, customer)}
  end

  def handle_info({:customer_archived, customer}, socket) do
    {:noreply, stream_delete(socket, :customers, customer)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-8 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-base font-semibold leading-6 text-zinc-900 dark:text-zinc-100">Customers</h1>
          <p class="mt-2 text-sm text-zinc-700 dark:text-zinc-300">
            A list of all the customers in your organization including their contact details and address.
          </p>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
          <.link patch={~p"/customers/new"}>
            <button type="button" class="block rounded-md bg-indigo-600 px-3 py-2 text-center text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
              New Customer
            </button>
          </.link>
        </div>
      </div>

      <div class="mt-6">
        <form phx-change="search" id="search-form">
          <input type="text" name="search" value={@search} placeholder="Search customers..." class="block w-full rounded-md border-0 py-1.5 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 placeholder:text-zinc-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-zinc-800 dark:ring-zinc-700 dark:text-zinc-100 dark:placeholder:text-zinc-500" />
        </form>
      </div>

      <div class="mt-8 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            <table class="min-w-full divide-y divide-zinc-300 dark:divide-zinc-700">
              <thead>
                <tr>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100 sm:pl-0">Name</th>
                  <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">Contact</th>
                  <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">Address</th>
                  <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                    <span class="sr-only">Edit</span>
                  </th>
                </tr>
              </thead>
              <tbody phx-update="stream" id="customers" class="divide-y divide-zinc-200 dark:divide-zinc-800">
                <tr :for={{id, customer} <- @streams.customers} id={id} class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/50">
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-zinc-900 dark:text-zinc-100 sm:pl-0">
                    <.link navigate={~p"/customers/#{customer}"} class="hover:underline">
                      {customer.name}
                    </.link>
                  </td>
                  <td class="whitespace-nowrap px-3 py-4 text-sm text-zinc-500 dark:text-zinc-400">
                    <div>{customer.email}</div>
                    <div class="text-xs">{customer.phone}</div>
                  </td>
                  <td class="whitespace-nowrap px-3 py-4 text-sm text-zinc-500 dark:text-zinc-400">
                    {Customer.full_address(customer)}
                  </td>
                  <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                    <div class="flex items-center justify-end gap-2">
                      <.link patch={~p"/customers/#{customer}/edit"} class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300">
                        Edit<span class="sr-only">, {customer.name}</span>
                      </.link>
                      <.link
                        phx-click={JS.push("delete", value: %{id: customer.id}) |> hide("##{id}")}
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

      <.modal :if={@live_action in [:new, :edit]} id="customer-modal" show on_cancel={JS.patch(~p"/customers")}>
        <.live_component
          module={FieldHubWeb.CustomerLive.FormComponent}
          id={@customer.id || :new}
          title={@page_title}
          action={@live_action}
          customer={@customer}
          current_organization={@current_organization}
          patch={~p"/customers"}
        />
      </.modal>
    </div>
    """
  end
end
