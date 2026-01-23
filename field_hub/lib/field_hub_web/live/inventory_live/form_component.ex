defmodule FieldHubWeb.InventoryLive.FormComponent do
  use FieldHubWeb, :live_component

  alias FieldHub.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Manage part details and inventory levels</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="part-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <.input field={@form[:name]} type="text" label="Part Name" required />
          <.input field={@form[:sku]} type="text" label="SKU" placeholder="Optional" />
          <.input field={@form[:description]} type="textarea" label="Description" rows={3} />

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:unit_price]} type="number" label="Unit Price ($)" step="0.01" min="0" required />
            <.input
              field={@form[:category]}
              type="select"
              label="Category"
              options={[
                {"Material", "material"},
                {"Equipment", "equipment"},
                {"Tool", "tool"},
                {"Supply", "supply"},
                {"Consumable", "consumable"}
              ]}
            />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:quantity_on_hand]} type="number" label="Quantity on Hand" min="0" />
            <.input field={@form[:reorder_point]} type="number" label="Reorder Point" min="0" />
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." class="w-full">
            Save Part
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{part: part} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_part(part))
     end)}
  end

  @impl true
  def handle_event("validate", %{"part" => part_params}, socket) do
    changeset = Inventory.change_part(socket.assigns.part, part_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"part" => part_params}, socket) do
    save_part(socket, socket.assigns.action, part_params)
  end

  defp save_part(socket, :edit, part_params) do
    case Inventory.update_part(socket.assigns.part, part_params) do
      {:ok, part} ->
        notify_parent({:saved, part})

        {:noreply,
         socket
         |> put_flash(:info, "Part updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_part(socket, :new, part_params) do
    case Inventory.create_part(socket.assigns.org_id, part_params) do
      {:ok, part} ->
        notify_parent({:saved, part})

        {:noreply,
         socket
         |> put_flash(:info, "Part created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
