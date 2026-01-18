defmodule FieldHubWeb.JobLive.FormComponent do
  use FieldHubWeb, :live_component

  alias FieldHub.Jobs
  alias FieldHub.CRM

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
          <.input field={@form[:title]} type="text" label="Job Title" placeholder="e.g. AC Repair for Smith Residence" />

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

          <.input field={@form[:description]} type="textarea" label="Description" class="min-h-[120px]" placeholder="Detailed description of the work required..." />

          <.input
            field={@form[:customer_id]}
            type="select"
            label="Customer"
            prompt="Select a customer"
            options={@customers}
          />
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." class="w-full bg-primary hover:bg-primary/90 text-white font-bold py-3 rounded-xl shadow-lg shadow-primary/20 transition-all">
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

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:customers, customers)
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
