defmodule FieldHubWeb.TechnicianLive.FormComponent do
  use FieldHubWeb, :live_component

  alias FieldHub.Dispatch

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="technician-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <div class="space-y-4">
          <!-- Avatar Color Selection with Label -->
          <div class="flex items-center gap-4">
            <div class="relative">
              <.input
                field={@form[:color]}
                type="color"
                label="Avatar"
                class="h-12 w-12 p-1 rounded-full overflow-hidden cursor-pointer"
              />
            </div>
            <div class="flex-1">
              <.input field={@form[:name]} type="text" label="Full Name" placeholder="e.g. Jane Doe" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@form[:email]}
              type="email"
              label="Email Address"
              placeholder="jane@example.com"
            />
            <.input
              field={@form[:phone]}
              type="tel"
              label="Phone Number"
              placeholder="+1 (555) 000-0000"
            />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@form[:hourly_rate]}
              type="number"
              step="0.01"
              label="Hourly Rate ($)"
              placeholder="0.00"
            />
          </div>

          <.input
            field={@form[:skills]}
            type="text"
            label="Skills & Expertise"
            value={if @form[:skills].value, do: Enum.join(@form[:skills].value, ", "), else: ""}
            name="technician[skills_input]"
            placeholder="e.g. Electrical, HVAC, Plumbing (comma separated)"
            class="w-full"
          />
        </div>

        <:actions>
          <.button
            phx-disable-with="Saving..."
            class="w-full bg-primary hover:bg-primary/90 text-white font-bold py-3 rounded-xl shadow-lg shadow-primary/20 transition-all"
          >
            Save Technician Record
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{technician: technician} = assigns, socket) do
    changeset = Dispatch.change_technician(technician)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"technician" => technician_params}, socket) do
    technician_params = parse_skills(technician_params)

    changeset =
      socket.assigns.technician
      |> Dispatch.change_technician(technician_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"technician" => technician_params}, socket) do
    technician_params = parse_skills(technician_params)
    save_technician(socket, socket.assigns.action, technician_params)
  end

  defp save_technician(socket, :edit, technician_params) do
    case Dispatch.update_technician(socket.assigns.technician, technician_params) do
      {:ok, technician} ->
        notify_parent({:saved, technician})

        {:noreply,
         socket
         |> put_flash(:info, "Technician updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_technician(socket, :new, technician_params) do
    case Dispatch.create_technician(socket.assigns.current_organization.id, technician_params) do
      {:ok, technician} ->
        notify_parent({:saved, technician})

        {:noreply,
         socket
         |> put_flash(:info, "Technician created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp parse_skills(params) do
    if input = params["skills_input"] do
      skills = input |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
      Map.put(params, "skills", skills)
    else
      params
    end
  end
end
