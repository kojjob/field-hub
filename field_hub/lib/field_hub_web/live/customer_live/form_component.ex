defmodule FieldHubWeb.CustomerLive.FormComponent do
  use FieldHubWeb, :live_component

  alias FieldHub.CRM

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="customer-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-8"
      >
        <div class="space-y-6">
          <!-- Contact Info Section -->
          <div>
            <h3 class="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4 border-b border-slate-200 dark:border-slate-700 pb-2">
              Contact Information
            </h3>
            <div class="grid grid-cols-1 gap-5">
              <.input
                field={@form[:name]}
                type="text"
                label="Customer Name"
                placeholder="e.g. Acme Inc. or John Doe"
                class="w-full rounded-lg border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 focus:border-primary focus:ring-primary sm:text-sm p-3 transition-shadow shadow-sm"
              />
              <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <.input
                  field={@form[:email]}
                  type="email"
                  label="Email Address"
                  placeholder="name@example.com"
                  class="w-full rounded-lg border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 focus:border-primary focus:ring-primary sm:text-sm p-3 transition-shadow shadow-sm"
                />
                <.input
                  field={@form[:phone]}
                  type="tel"
                  label="Phone Number"
                  placeholder="(555) 123-4567"
                  class="w-full rounded-lg border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 focus:border-primary focus:ring-primary sm:text-sm p-3 transition-shadow shadow-sm"
                />
              </div>
            </div>
          </div>
          
    <!-- Address Section -->
          <div>
            <h3 class="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4 border-b border-slate-200 dark:border-slate-700 pb-2">
              Service Address
            </h3>
            <div class="grid grid-cols-1 gap-5">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                <div class="md:col-span-2">
                  <.input
                    field={@form[:address_line1]}
                    type="text"
                    label="Street Address"
                    placeholder="123 Main St"
                    class="w-full rounded-lg border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 focus:border-primary focus:ring-primary sm:text-sm p-3 transition-shadow shadow-sm"
                  />
                </div>
                <.input
                  field={@form[:address_line2]}
                  type="text"
                  label="Unit/Apt"
                  placeholder="Unit B"
                  class="w-full rounded-lg border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 focus:border-primary focus:ring-primary sm:text-sm p-3 transition-shadow shadow-sm"
                />
              </div>

              <div class="grid grid-cols-2 md:grid-cols-3 gap-5">
                <.input
                  field={@form[:city]}
                  type="text"
                  label="City"
                  class="w-full rounded-lg border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 focus:border-primary focus:ring-primary sm:text-sm p-3 transition-shadow shadow-sm"
                />
                <.input
                  field={@form[:state]}
                  type="text"
                  label="State"
                  class="w-full rounded-lg border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 focus:border-primary focus:ring-primary sm:text-sm p-3 transition-shadow shadow-sm"
                />
                <div class="col-span-2 md:col-span-1">
                  <.input
                    field={@form[:zip]}
                    type="text"
                    label="ZIP Code"
                    class="w-full rounded-lg border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 focus:border-primary focus:ring-primary sm:text-sm p-3 transition-shadow shadow-sm"
                  />
                </div>
              </div>
            </div>
          </div>
          
    <!-- Access Info Section -->
          <div class="bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700 rounded-2xl p-5 relative overflow-hidden group">
            <div class="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity pointer-events-none">
              <.icon
                name="hero-lock-closed"
                class="w-24 h-24 text-slate-400 dark:text-slate-500 -rotate-12"
              />
            </div>

            <div class="relative z-10">
              <div class="flex items-center gap-2 mb-4">
                <div class="p-2 bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-100 dark:border-slate-700 text-primary">
                  <.icon name="hero-key" class="w-4 h-4" />
                </div>
                <h3 class="text-sm font-bold text-slate-900 dark:text-white">
                  Access & Security
                </h3>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <.input
                  field={@form[:gate_code]}
                  type="text"
                  label="Gate / Door Code"
                  placeholder="e.g. #1234"
                  class="w-full rounded-xl border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 focus:border-primary focus:ring-primary sm:text-sm p-3.5 transition-shadow shadow-sm font-mono text-center tracking-widest text-primary font-bold"
                />
                <.input
                  field={@form[:special_instructions]}
                  type="textarea"
                  label="Technician Notes"
                  placeholder="Key location, dog warning, etc."
                  class="w-full rounded-xl border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 focus:border-primary focus:ring-primary sm:text-sm p-3.5 transition-shadow shadow-sm min-h-[80px]"
                />
              </div>
            </div>
          </div>
        </div>

        <:actions>
          <.button
            phx-disable-with="Saving..."
            class="w-full py-3 text-base font-bold bg-primary hover:bg-primary/90 shadow-lg shadow-primary/20 rounded-xl transition-all text-white"
          >
            Save Customer
          </.button>
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
