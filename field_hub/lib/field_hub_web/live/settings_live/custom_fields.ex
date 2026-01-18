defmodule FieldHubWeb.SettingsLive.CustomFields do
  use FieldHubWeb, :live_view
  alias FieldHub.Config.CustomFields
  alias FieldHub.Config.CustomFieldDefinition

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to updates if needed
    end

    socket =
      socket
      |> assign(:active_tab, "job")
      |> assign(:page_title, "Custom Fields")
      |> assign_fields()

    {:ok, socket}
  end



  defp assign_fields(socket) do
    fields = CustomFields.list_definitions(
      socket.assigns.current_organization,
      socket.assigns.active_tab
    )
    assign(socket, :fields, fields)
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <div class="md:flex md:items-center md:justify-between mb-6">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 dark:text-white sm:truncate sm:text-3xl sm:tracking-tight">
            Custom Fields
          </h2>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            Define custom data fields for your jobs, customers, and technicians.
          </p>
        </div>
        <div class="mt-4 flex md:ml-4 md:mt-0">
          <.link patch={~p"/settings/custom-fields/new?target=#{@active_tab}"} class="ml-3 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
            Add Field
          </.link>
        </div>
      </div>

      <!-- Tabs -->
      <div class="border-b border-gray-200 dark:border-gray-700 mb-6">
        <nav class="-mb-px flex space-x-8" aria-label="Tabs">
          <%= for tab <- ["job", "customer", "technician"] do %>
            <button
              phx-click="change_tab"
              phx-value-tab={tab}
              class={"#{if @active_tab == tab, do: "border-indigo-500 text-indigo-600 dark:text-indigo-400", else: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400"} whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium capitalize"}
            >
              <%= tab %> Fields
            </button>
          <% end %>
        </nav>
      </div>

      <!-- Field List -->
      <div class="bg-white dark:bg-gray-800 shadow sm:rounded-md">
        <ul role="list" class="divide-y divide-gray-100 dark:divide-gray-700">
          <%= if Enum.empty?(@fields) do %>
            <div class="text-center py-12">
              <p class="text-sm text-gray-500 dark:text-gray-400">No custom fields defined for <%= @active_tab %>s.</p>
            </div>
          <% else %>
            <%= for field <- @fields do %>
              <li class="flex items-center justify-between gap-x-6 py-5 px-6 hover:bg-gray-50 dark:hover:bg-gray-700/50">
                <div class="min-w-0">
                  <div class="flex items-start gap-x-3">
                    <p class="text-sm font-semibold leading-6 text-gray-900 dark:text-white"><%= field.name %></p>
                    <p class={"rounded-md whitespace-nowrap mt-0.5 px-1.5 py-0.5 text-xs font-medium ring-1 ring-inset #{if field.required, do: "text-red-700 bg-red-50 ring-red-600/10 dark:text-red-400 dark:bg-red-400/10", else: "text-gray-600 bg-gray-50 ring-gray-500/10 dark:text-gray-400 dark:bg-gray-400/10"}"}>
                      <%= if field.required, do: "Required", else: "Optional" %>
                    </p>
                  </div>
                  <div class="mt-1 flex items-center gap-x-2 text-xs leading-5 text-gray-500 dark:text-gray-400">
                    <p class="font-mono bg-gray-100 dark:bg-gray-700 px-1 py-0.5 rounded"><%= field.key %></p>
                    <p>&middot;</p>
                    <p class="capitalize"><%= field.type %></p>
                  </div>
                </div>
                <div class="flex flex-none items-center gap-x-4">
                  <button phx-click="delete_field" phx-value-id={field.id} data-confirm="Are you sure?" class="text-sm font-semibold leading-6 text-red-600 hover:text-red-500">
                    Delete
                  </button>
                </div>
              </li>
            <% end %>
          <% end %>
        </ul>
      </div>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="custom-field-modal"
      show
      on_cancel={JS.patch(~p"/settings/custom-fields?tab=#{@active_tab}")}
    >
      <.header>
        <%= @page_title %>
        <:subtitle>Add a new custom field for <%= @active_tab %>s.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="custom-field-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Field Label" placeholder="e.g. Gate Code" />
        <.input field={@form[:key]} label="Database Key" placeholder="e.g. gate_code" />
        <.input
          field={@form[:type]}
          type="select"
          label="Data Type"
          options={[
            {"Text", "text"},
            {"Number", "number"},
            {"Date", "date"},
            {"Checkbox (True/False)", "boolean"},
            {"Select Dropdown", "select"}
          ]}
        />

        <%= if Ecto.Changeset.get_field(@form.source, :type) == "select" do %>
           <.input
             field={@form[:options]}
             label="Options (comma separated)"
             value={Enum.join(Ecto.Changeset.get_field(@form.source, :options) || [], ", ")}
             name="custom_field_definition[options_string]"
             placeholder="Option A, Option B, Option C"
           />
        <% end %>

        <.input field={@form[:required]} type="checkbox" label="Required Field" />

        <!-- Hidden fields -->
        <.input field={@form[:target]} type="hidden" />
        <.input field={@form[:organization_id]} type="hidden" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Field</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply,
     socket
     |> assign(:active_tab, tab)
     |> assign_fields()}
  end

  def handle_event("delete_field", %{"id" => id}, socket) do
    field = CustomFields.get_definition!(id)
    {:ok, _} = CustomFields.delete_definition(field)

    {:noreply,
     socket
     |> put_flash(:info, "Field deleted successfully")
     |> assign_fields()}
  end

  def handle_event("validate", %{"custom_field_definition" => params}, socket) do
    params = handle_options_string(params)
    changeset =
      socket.assigns.item
      |> CustomFields.change_definition(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"custom_field_definition" => params}, socket) do
    params = handle_options_string(params)

    case CustomFields.create_definition(params) do
      {:ok, _field} ->
        {:noreply,
         socket
         |> put_flash(:info, "Field created successfully")
         |> push_patch(to: ~p"/settings/custom-fields?tab=#{params["target"]}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_options_string(params) do
    if options_string = params["options_string"] do
      options =
        options_string
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(& &1 == "")

      Map.put(params, "options", options)
    else
      params
    end
  end

  def handle_params(params, _url, socket) do
    tab = params["tab"] || socket.assigns.active_tab || "job"

    socket =
      socket
      |> assign(:active_tab, tab)
      |> apply_action(socket.assigns.live_action, params)
      |> assign_fields()

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Custom Fields")
    |> assign(:item, nil)
  end

  defp apply_action(socket, :new, params) do
    target = params["target"] || "job"
    org_id = socket.assigns.current_organization.id

    item = %CustomFieldDefinition{
      target: target,
      type: "text",
      organization_id: org_id
    }
    changeset = CustomFields.change_definition(item)

    socket
    |> assign(:page_title, "New Custom Field")
    |> assign(:item, item)
    |> assign(:form, to_form(changeset))
  end
end
