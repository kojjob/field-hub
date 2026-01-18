defmodule FieldHubWeb.CustomerLive.FormComponent do
  use FieldHubWeb, :live_component

  alias FieldHub.CRM

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage customer records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="customer-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:email]} type="email" label="Email" />
        <.input field={@form[:phone]} type="tel" label="Phone" />

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <.input field={@form[:address_line1]} type="text" label="Address Line 1" />
          <.input field={@form[:address_line2]} type="text" label="Address Line 2" />
        </div>

        <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <div class="col-span-2">
            <.input field={@form[:city]} type="text" label="City" />
          </div>
          <.input field={@form[:state]} type="text" label="State" />
          <.input field={@form[:zip]} type="text" label="ZIP Code" />
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Customer</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{customer: customer} = assigns, socket) do
    changeset = CRM.change_customer(customer)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"customer" => customer_params}, socket) do
    changeset =
      socket.assigns.customer
      |> CRM.change_customer(customer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"customer" => customer_params}, socket) do
    save_customer(socket, socket.assigns.action, customer_params)
  end

  defp save_customer(socket, :edit, customer_params) do
    case CRM.update_customer(socket.assigns.customer, customer_params) do
      {:ok, customer} ->
        notify_parent({:saved, customer})

        {:noreply,
         socket
         |> put_flash(:info, "Customer updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_customer(socket, :new, customer_params) do
    case CRM.create_customer(socket.assigns.current_organization.id, customer_params) do
      {:ok, customer} ->
        notify_parent({:saved, customer})

        {:noreply,
         socket
         |> put_flash(:info, "Customer created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
