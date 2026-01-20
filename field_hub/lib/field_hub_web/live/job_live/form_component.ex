defmodule FieldHubWeb.JobLive.FormComponent do
  use FieldHubWeb, :live_component

  alias FieldHub.Jobs
  alias FieldHub.CRM
  alias FieldHub.Dispatch
  alias FieldHub.Locations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="job-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <div class="space-y-4">
          <.input
            field={@form[:title]}
            type="text"
            label="Job Title"
            placeholder="e.g. AC Repair for Smith Residence"
          />

          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@form[:job_type]}
              type="select"
              label="Type"
              options={[
                {"Service Call", "service_call"},
                {"Installation", "installation"},
                {"Maintenance", "maintenance"},
                {"Emergency", "emergency"},
                {"Estimate", "estimate"}
              ]}
            />
            <.input
              field={@form[:priority]}
              type="select"
              label="Priority"
              options={[
                {"Normal", "normal"},
                {"Low", "low"},
                {"High", "high"},
                {"Urgent", "urgent"}
              ]}
            />
          </div>

          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            placeholder="Detailed description of the work required..."
          />

          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@form[:customer_id]}
              type="select"
              label="Customer"
              prompt="Select a customer"
              options={@customers}
            />
            <.input
              field={@form[:technician_id]}
              type="select"
              label="Assign Technician"
              prompt="Unassigned"
              options={@technicians}
            />
          </div>

          <div class="border-t border-zinc-200 dark:border-zinc-700 pt-4 mt-4">
            <h4 class="text-xs font-bold text-zinc-500 uppercase tracking-widest mb-3">
              Scheduling
            </h4>
            <div class="grid grid-cols-3 gap-4">
              <.input
                field={@form[:scheduled_date]}
                type="date"
                label="Date"
              />
              <.input
                field={@form[:scheduled_start]}
                type="time"
                label="Start Time"
              />
              <.input
                field={@form[:estimated_duration_minutes]}
                type="number"
                label="Duration (min)"
                placeholder="60"
              />
            </div>
          </div>

          <div class="border-t border-zinc-200 dark:border-zinc-700 pt-4 mt-4">
            <h4 class="text-xs font-bold text-zinc-500 uppercase tracking-widest mb-3">
              Service Address
            </h4>
            <.input
              field={@form[:service_address]}
              type="text"
              label="Street Address"
              placeholder="123 Main Street"
            />
            <div class="grid grid-cols-2 gap-4 mt-3">
              <.input
                field={@form[:service_country]}
                type="select"
                label="Country"
                prompt="Select country"
                options={@countries}
              />
              <div>
                <%= if @form[:service_country].value == "US" || is_nil(@form[:service_country].value) do %>
                  <.input
                    field={@form[:service_state]}
                    type="select"
                    label="State"
                    prompt="Select state"
                    options={@us_states}
                  />
                <% else %>
                  <.input
                    field={@form[:service_state]}
                    type="text"
                    label="State / Province"
                    placeholder="State or Province"
                  />
                <% end %>
              </div>
            </div>
            <div class="grid grid-cols-2 gap-4 mt-3">
              <.input
                field={@form[:service_city]}
                type="text"
                label="City"
                placeholder="e.g. Austin"
              />
              <.input
                field={@form[:service_zip]}
                type="text"
                label="ZIP"
                placeholder="e.g. 78701"
                maxlength="10"
              />
            </div>
          </div>

          <div class="border-t border-zinc-200 dark:border-zinc-700 pt-4 mt-4">
            <h4 class="text-xs font-bold text-zinc-500 uppercase tracking-widest mb-3">
              Financials
            </h4>
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:quoted_amount]}
                type="number"
                label="Quoted Amount ($)"
                step="0.01"
                placeholder="0.00"
              />
              <.input
                field={@form[:actual_amount]}
                type="number"
                label="Actual Amount ($)"
                step="0.01"
                placeholder="0.00"
              />
            </div>
          </div>
        </div>

        <:actions>
          <.button
            phx-disable-with="Saving..."
            class="w-full bg-primary hover:bg-primary/90 text-white font-bold py-3 rounded-xl shadow-lg shadow-primary/20 transition-all"
          >
            Save Job Record
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{job: job} = assigns, socket) do
    changeset = Jobs.change_job(job)

    # Load customers for the select dropdown
    customers =
      CRM.list_customers(assigns.current_organization.id)
      |> Enum.map(&{&1.name, &1.id})

    # Load technicians for assignment
    technicians =
      Dispatch.list_technicians(assigns.current_organization.id)
      |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:customers, customers)
     |> assign(:technicians, technicians)
     |> assign(:customers, customers)
     |> assign(:technicians, technicians)
     |> assign(:countries, Locations.countries())
     |> assign(:us_states, Locations.us_states())
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"job" => job_params}, socket) do
    changeset =
      socket.assigns.job
      |> Jobs.change_job(job_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"job" => job_params}, socket) do
    save_job(socket, socket.assigns.action, job_params)
  end

  defp save_job(socket, :edit, job_params) do
    case Jobs.update_job(socket.assigns.job, job_params) do
      {:ok, job} ->
        notify_parent({:saved, job})

        {:noreply,
         socket
         |> put_flash(:info, "Job updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_job(socket, :new, job_params) do
    # Ensure organization_id and created_by_id are set
    job_params = Map.put(job_params, "created_by_id", socket.assigns.current_user.id)

    case Jobs.create_job(socket.assigns.current_organization.id, job_params) do
      {:ok, job} ->
        notify_parent({:saved, job})

        {:noreply,
         socket
         |> put_flash(:info, "Job created successfully")
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
