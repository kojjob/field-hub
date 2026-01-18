defmodule FieldHubWeb.SettingsLive.CustomFields do
  @moduledoc """
  Settings page for defining custom data fields for various entities.
  """
  use FieldHubWeb, :live_view
  alias FieldHub.Config.CustomFields
  alias FieldHub.Config.CustomFieldDefinition
  alias FieldHub.Config.Terminology

  def mount(_params, _session, socket) do
    org = socket.assigns.current_organization

    # Get labels for tabs from terminology
    worker_label = Terminology.get_label(org, :worker, :singular)
    client_label = Terminology.get_label(org, :client, :singular)
    task_label = Terminology.get_label(org, :task, :singular)

    socket =
      socket
      |> assign(:active_tab, "job")
      |> assign(:page_title, "Custom Fields")
      |> assign(:worker_label, worker_label)
      |> assign(:client_label, client_label)
      |> assign(:task_label, task_label)
      |> assign_fields()

    {:ok, socket}
  end

  defp assign_fields(socket) do
    fields =
      CustomFields.list_definitions(
        socket.assigns.current_organization,
        socket.assigns.active_tab
      )

    assign(socket, :fields, fields)
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <div class="mb-8 flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-zinc-900 dark:text-white tracking-tight">
            Custom Fields
          </h1>
          <p class="mt-2 text-zinc-600 dark:text-zinc-400">
            Extend your data model with custom fields tailored to your {@current_organization.name} operations.
          </p>
        </div>
        <div>
          <.button
            patch={~p"/settings/custom-fields/new?target=#{@active_tab}"}
            variant="primary"
            class="gap-2 shadow-lg shadow-primary/20"
          >
            <.icon name="hero-plus" class="size-4" /> Add Field
          </.button>
        </div>
      </div>

    <!-- Tabs -->
      <div class="flex p-1 bg-zinc-100 dark:bg-zinc-800/50 rounded-2xl mb-8 border border-zinc-200 dark:border-zinc-700/50">
        <%= for {tab, label, icon} <- [
          {"job", @task_label, "hero-briefcase"},
          {"customer", @client_label, "hero-building-office"},
          {"technician", @worker_label, "hero-user-group"}
        ] do %>
          <button
            phx-click="change_tab"
            phx-value-tab={tab}
            class={[
              "flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-bold transition-all rounded-xl",
              @active_tab == tab && "bg-white dark:bg-zinc-800 text-primary shadow-sm",
              @active_tab != tab && "text-zinc-500 hover:text-zinc-900 dark:hover:text-zinc-300"
            ]}
          >
            <.icon name={icon} class="size-4" />
            {label}s
          </button>
        <% end %>
      </div>

    <!-- Field List -->
      <div class="bg-white dark:bg-zinc-800/50 rounded-[24px] shadow-sm border border-zinc-200 dark:border-zinc-700/50 overflow-hidden">
        <%= if Enum.empty?(@fields) do %>
          <div class="py-20 text-center">
            <div class="size-20 rounded-full bg-zinc-50 dark:bg-zinc-900 flex items-center justify-center mx-auto mb-6">
              <.icon name="hero-document-plus" class="size-10 text-zinc-300" />
            </div>
            <h3 class="text-zinc-900 dark:text-white font-bold text-lg">No custom fields yet</h3>
            <p class="text-zinc-500 max-w-sm mx-auto mt-2">
              Add fields to capture specific details for your {@active_tab}s that aren't available by default.
            </p>
            <.button
              patch={~p"/settings/custom-fields/new?target=#{@active_tab}"}
              variant="outline"
              class="mt-8"
            >
              Click to add your first field
            </.button>
          </div>
        <% else %>
          <div class="divide-y divide-zinc-100 dark:divide-zinc-700/50">
            <%= for field <- @fields do %>
              <div class="group flex items-center justify-between p-6 hover:bg-primary/5 dark:hover:bg-primary/10 transition-all">
                <div class="flex items-center gap-5">
                  <div class="size-12 rounded-2xl bg-zinc-100 dark:bg-zinc-900 flex items-center justify-center text-zinc-400 group-hover:bg-white dark:group-hover:bg-zinc-800 group-hover:text-primary transition-colors border border-transparent group-hover:border-zinc-200 dark:group-hover:border-zinc-700 shadow-sm">
                    <.icon name={get_field_icon(field.type)} class="size-6" />
                  </div>
                  <div>
                    <div class="flex items-center gap-2 mb-1">
                      <h4 class="font-bold text-zinc-900 dark:text-white">{field.name}</h4>
                      <%= if field.required do %>
                        <span class="text-[10px] font-bold bg-red-100 dark:bg-red-900/30 text-red-600 px-1.5 py-0.5 rounded-full uppercase tracking-tighter">
                          Required
                        </span>
                      <% end %>
                    </div>
                    <div class="flex items-center gap-3">
                      <span class="text-xs font-mono bg-zinc-100 dark:bg-zinc-900 text-zinc-500 px-1.5 py-0.5 rounded inline-block">
                        {field.key}
                      </span>
                      <span class="text-xs text-zinc-400 capitalize">{field.type} field</span>
                      <%= if field.type == "select" && field.options do %>
                        <span class="text-xs text-zinc-400">
                          &middot; {length(field.options)} options
                        </span>
                      <% end %>
                    </div>
                  </div>
                </div>

                <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    phx-click="delete_field"
                    phx-value-id={field.id}
                    data-confirm="Permanently delete this custom field?"
                    class="p-2.5 rounded-xl hover:bg-red-50 dark:hover:bg-red-900/20 text-zinc-400 hover:text-red-500 transition-all"
                  >
                    <.icon name="hero-trash" class="size-5" />
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="mt-8 p-6 bg-amber-50 dark:bg-amber-900/10 border border-amber-200 dark:border-amber-900/30 rounded-[24px] flex gap-4">
        <.icon
          name="hero-exclamation-triangle"
          class="size-6 text-amber-600 dark:text-amber-500 shrink-0"
        />
        <div>
          <h5 class="text-sm font-bold text-amber-900 dark:text-amber-400">Important Note</h5>
          <p class="text-xs text-amber-800/80 dark:text-amber-500/70 mt-1 leading-relaxed">
            Custom fields are globally available to your team. Deleting a field will also remove any data stored in it for existing records. Proceed with caution.
          </p>
        </div>
      </div>
    </div>

    <!-- Field Modal -->
    <%= if @live_action in [:new, :edit] do %>
      <div
        class="fixed inset-0 bg-zinc-950/20 dark:bg-zinc-950/60 backdrop-blur-sm flex items-center justify-center z-50 p-4"
        phx-click={JS.patch(~p"/settings/custom-fields?tab=#{@active_tab}")}
      >
        <div
          class="bg-white dark:bg-zinc-900 rounded-[32px] shadow-2xl border border-zinc-200 dark:border-zinc-800 w-full max-w-xl overflow-hidden"
          phx-click-away={JS.patch(~p"/settings/custom-fields?tab=#{@active_tab}")}
        >
          <div class="px-8 pt-8 pb-6 bg-zinc-50/50 dark:bg-zinc-950/50 border-b border-zinc-100 dark:border-zinc-800">
            <h3 class="text-2xl font-bold text-zinc-900 dark:text-white">New Custom Field</h3>
            <p class="text-sm text-zinc-500 mt-1">Add a new attribute to your {@active_tab} model.</p>
          </div>

          <.form
            for={@form}
            id="custom-field-form"
            phx-change="validate"
            phx-submit="save"
            class="p-8 space-y-6"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <.input
                field={@form[:name]}
                label="Field Label"
                placeholder="e.g. Serial Number"
                class="input-bordered"
              />
              <.input
                field={@form[:key]}
                label="System Key"
                placeholder="e.g. serial_number"
                class="input-bordered"
              />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-end">
              <.input
                field={@form[:type]}
                type="select"
                label="Field Type"
                options={[
                  {"Text Input", "text"},
                  {"Number", "number"},
                  {"Date Picker", "date"},
                  {"Checkbox (Yes/No)", "boolean"},
                  {"Dropdown Menu", "select"}
                ]}
                class="select-bordered"
              />
              <div class="flex items-center h-12">
                <.input field={@form[:required]} type="checkbox" label="Make this field mandatory" />
              </div>
            </div>

            <%= if Ecto.Changeset.get_field(@form.source, :type) == "select" do %>
              <div class="bg-zinc-50 dark:bg-zinc-950 p-6 rounded-2xl border-2 border-dashed border-zinc-200 dark:border-zinc-800">
                <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300 mb-2">
                  Dropdown Options
                </label>
                <p class="text-xs text-zinc-500 mb-4">
                  Enter options separated by commas (e.g. Small, Medium, Large)
                </p>
                <input
                  name="custom_field_definition[options_string]"
                  value={Enum.join(Ecto.Changeset.get_field(@form.source, :options) || [], ", ")}
                  class="w-full px-4 py-3 border border-zinc-300 dark:border-zinc-700 rounded-xl bg-white dark:bg-zinc-800 focus:ring-2 focus:ring-primary outline-none"
                  placeholder="Option 1, Option 2, Option 3"
                />
              </div>
            <% end %>

    <!-- Hidden fields -->
            <.input field={@form[:target]} type="hidden" />
            <.input field={@form[:organization_id]} type="hidden" />

            <div class="flex justify-end gap-3 pt-6 border-t border-zinc-100 dark:border-zinc-800">
              <button
                type="button"
                phx-click={JS.patch(~p"/settings/custom-fields?tab=#{@active_tab}")}
                class="px-5 py-2.5 text-sm font-semibold text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-white"
              >
                Cancel
              </button>
              <.button
                type="submit"
                variant="primary"
                phx-disable-with="Saving..."
                class="px-8 shadow-lg shadow-primary/20"
              >
                Create Field
              </.button>
            </div>
          </.form>
        </div>
      </div>
    <% end %>
    """
  end

  defp get_field_icon("text"), do: "hero-pencil"
  defp get_field_icon("number"), do: "hero-hashtag"
  defp get_field_icon("date"), do: "hero-calendar"
  defp get_field_icon("boolean"), do: "hero-check-circle"
  defp get_field_icon("select"), do: "hero-chevron-down"
  defp get_field_icon(_), do: "hero-variable"

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
        |> Enum.reject(&(&1 == ""))

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
