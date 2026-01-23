defmodule FieldHubWeb.JobLive.FormComponent do
  use FieldHubWeb, :live_component

  alias FieldHub.Jobs
  alias FieldHub.CRM
  alias FieldHub.Dispatch
  alias FieldHub.Locations
  alias FieldHub.Inventory

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

          <!-- Parts & Materials Section (only for existing jobs) -->
          <%= if @action == :edit && @job.id do %>
            <div class="border-t border-zinc-200 dark:border-zinc-700 pt-4 mt-4">
              <div class="flex items-center justify-between mb-3">
                <h4 class="text-xs font-bold text-zinc-500 uppercase tracking-widest">
                  Parts & Materials
                </h4>
                <span class="text-sm font-bold text-primary">
                  Total: {format_money(@parts_total)}
                </span>
              </div>

              <!-- Add Part Form -->
              <div class="bg-zinc-50 dark:bg-zinc-800 rounded-xl p-4 mb-4">
                <div class="grid grid-cols-12 gap-3">
                  <div class="col-span-6">
                    <label class="block text-xs font-bold text-zinc-500 uppercase tracking-wide mb-1">
                      Select Part
                    </label>
                    <select
                      name="add_part_id"
                      id="add-part-select"
                      phx-target={@myself}
                      class="w-full px-3 py-2 bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-700 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    >
                      <option value="">Choose a part...</option>
                      <%= for {name, id} <- @available_parts do %>
                        <option value={id}>{name}</option>
                      <% end %>
                    </select>
                  </div>
                  <div class="col-span-3">
                    <label class="block text-xs font-bold text-zinc-500 uppercase tracking-wide mb-1">
                      Qty
                    </label>
                    <input
                      type="number"
                      name="add_part_qty"
                      id="add-part-qty"
                      value="1"
                      min="1"
                      class="w-full px-3 py-2 bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-700 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    />
                  </div>
                  <div class="col-span-3 flex items-end">
                    <button
                      type="button"
                      phx-click="add_part"
                      phx-target={@myself}
                      class="w-full px-4 py-2 bg-primary text-white font-bold text-sm rounded-lg hover:bg-primary/90 transition-all flex items-center justify-center gap-1"
                    >
                      <.icon name="hero-plus" class="size-4" /> Add
                    </button>
                  </div>
                </div>
              </div>

              <!-- Parts List -->
              <%= if @job_parts == [] do %>
                <div class="text-center py-6 text-zinc-400">
                  <.icon name="hero-cube" class="size-8 mx-auto mb-2" />
                  <p class="text-sm">No parts added yet</p>
                </div>
              <% else %>
                <div class="space-y-2">
                  <%= for jp <- @job_parts do %>
                    <div class="flex items-center justify-between p-3 bg-white dark:bg-zinc-900 border border-zinc-100 dark:border-zinc-800 rounded-lg">
                      <div class="flex items-center gap-3">
                        <div class="size-10 rounded-lg bg-cyan-500/10 flex items-center justify-center">
                          <.icon name="hero-cube" class="size-5 text-cyan-600" />
                        </div>
                        <div>
                          <p class="font-bold text-sm text-zinc-900 dark:text-white">
                            {jp.part.name}
                          </p>
                          <p class="text-xs text-zinc-500">
                            {jp.quantity_used} × {format_money(jp.unit_price_at_time)}
                          </p>
                        </div>
                      </div>
                      <div class="flex items-center gap-4">
                        <span class="font-bold text-sm text-zinc-900 dark:text-white">
                          {format_money(Decimal.mult(jp.unit_price_at_time, jp.quantity_used))}
                        </span>
                        <button
                          type="button"
                          phx-click="remove_part"
                          phx-value-id={jp.id}
                          phx-target={@myself}
                          class="p-1.5 text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
                        >
                          <.icon name="hero-trash" class="size-4" />
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
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

    # Load available parts for the parts selector
    available_parts =
      Inventory.list_parts(assigns.current_organization.id)
      |> Enum.map(&{"#{&1.name} (#{format_money(&1.unit_price)})", &1.id})

    # Load parts already on this job (if editing)
    {job_parts, parts_total} =
      if job.id do
        parts = Inventory.list_job_parts(job.id)
        total = Inventory.job_parts_total(job.id)
        {parts, total}
      else
        {[], Decimal.new(0)}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:customers, customers)
     |> assign(:technicians, technicians)
     |> assign(:countries, Locations.countries())
     |> assign(:us_states, Locations.us_states())
     |> assign(:available_parts, available_parts)
     |> assign(:job_parts, job_parts)
     |> assign(:parts_total, parts_total)
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

  @impl true
  def handle_event("add_part", params, socket) do
    part_id = params["add_part_id"] || params["value"]["add_part_id"]
    qty = params["add_part_qty"] || params["value"]["add_part_qty"] || "1"

    if part_id && part_id != "" do
      quantity = String.to_integer(qty)
      job_id = socket.assigns.job.id

      case Inventory.add_part_to_job(job_id, part_id, quantity) do
        {:ok, _} ->
          # Reload parts list
          job_parts = Inventory.list_job_parts(job_id)
          parts_total = Inventory.job_parts_total(job_id)

          {:noreply,
           socket
           |> assign(:job_parts, job_parts)
           |> assign(:parts_total, parts_total)
           |> put_flash(:info, "Part added")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not add part")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please select a part")}
    end
  end

  @impl true
  def handle_event("remove_part", %{"id" => job_part_id}, socket) do
    case Inventory.remove_part_from_job(job_part_id) do
      {:ok, _} ->
        job_parts = Inventory.list_job_parts(socket.assigns.job.id)
        parts_total = Inventory.job_parts_total(socket.assigns.job.id)

        {:noreply,
         socket
         |> assign(:job_parts, job_parts)
         |> assign(:parts_total, parts_total)
         |> put_flash(:info, "Part removed")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not remove part")}
    end
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

  defp format_money(nil), do: "$0.00"
  defp format_money(%Decimal{} = amount), do: "$#{Decimal.round(amount, 2)}"
  defp format_money(amount) when is_number(amount), do: "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"
end
