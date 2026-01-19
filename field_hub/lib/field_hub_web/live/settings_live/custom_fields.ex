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
      |> assign(:current_nav, :custom_fields)
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
    <div class="flex h-[calc(100vh-4rem)] overflow-hidden">
      <!-- Main Content Area -->
      <div class={[
        "flex-1 flex flex-col min-w-0 transition-all duration-300 overflow-y-auto",
        @live_action in [:new, :edit] && "lg:mr-[480px]"
      ]}>
        <div class="space-y-10 p-6 pb-20">
          <!-- Page Heading (matches dashboard) -->
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
                System
              </p>
              <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
                Custom Fields
              </h2>
              <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 max-w-lg">
                Extend your data model with custom fields tailored to your {@current_organization.name} operations.
              </p>
            </div>
            <div class="flex flex-wrap items-center gap-3">
              <.link navigate={~p"/dashboard"}>
                <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
                  <.icon name="hero-arrow-left" class="size-4" /> Back
                </button>
              </.link>
              <button
                type="button"
                phx-click={JS.patch(~p"/settings/custom-fields/new?target=#{@active_tab}")}
                class="bg-primary hover:brightness-110 text-white px-6 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
              >
                <.icon name="hero-plus" class="size-5" /> Add Field
              </button>
            </div>
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-12 gap-8">
            <div class="xl:col-span-8 space-y-8">
              <!-- Tabs Navigation -->
              <div class="flex p-1.5 bg-zinc-100 dark:bg-zinc-800/50 rounded-2xl border border-zinc-200 dark:border-zinc-700/50">
                <%= for {tab, label, icon} <- [
                  {"job", @task_label, "hero-briefcase"},
                  {"customer", @client_label, "hero-building-office"},
                  {"technician", @worker_label, "hero-user-group"}
                ] do %>
                  <button
                    phx-click="change_tab"
                    phx-value-tab={tab}
                    class={[
                      "flex-1 flex items-center justify-center gap-2 py-3 text-xs font-black uppercase tracking-widest transition-all rounded-xl",
                      @active_tab == tab &&
                        "bg-white dark:bg-zinc-800 text-primary shadow-sm ring-1 ring-zinc-200 dark:ring-zinc-700",
                      @active_tab != tab &&
                        "text-zinc-500 hover:text-zinc-900 dark:hover:text-zinc-300"
                    ]}
                  >
                    <.icon name={icon} class="size-4" />
                    {label}s
                  </button>
                <% end %>
              </div>
              
    <!-- Field List -->
              <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/50 flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <div class="size-8 rounded-lg bg-primary/10 flex items-center justify-center">
                      <.icon name="hero-adjustments-vertical" class="size-4 text-primary" />
                    </div>
                    <h3 class="text-sm font-black text-zinc-900 dark:text-white uppercase tracking-wider">
                      Defined Fields
                    </h3>
                  </div>
                  <span class="text-[10px] font-black text-zinc-400 tracking-widest uppercase">
                    {@active_tab |> String.capitalize()} Entity
                  </span>
                </div>

                <%= if Enum.empty?(@fields) do %>
                  <div class="py-24 text-center">
                    <div class="size-20 rounded-full bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mx-auto mb-6">
                      <.icon name="hero-document-plus" class="size-10 text-zinc-400" />
                    </div>
                    <h3 class="text-xl font-black text-zinc-900 dark:text-white tracking-tight">
                      No custom fields defined
                    </h3>
                    <p class="text-sm font-bold text-zinc-500 mt-2 uppercase tracking-wide max-w-xs mx-auto">
                      Add fields to capture specific details for your {@active_tab}s.
                    </p>
                    <button
                      phx-click={JS.patch(~p"/settings/custom-fields/new?target=#{@active_tab}")}
                      class="mt-8 px-6 py-2.5 rounded-xl border border-zinc-200 dark:border-zinc-700 text-sm font-bold text-zinc-600 dark:text-zinc-400 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-all border-b-2"
                    >
                      Create first field
                    </button>
                  </div>
                <% else %>
                  <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
                    <%= for field <- @fields do %>
                      <div class="group flex items-center justify-between p-6 hover:bg-zinc-50 dark:hover:bg-zinc-800/30 transition-all">
                        <div class="flex items-center gap-6">
                          <div class="size-14 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center text-zinc-400 group-hover:text-primary transition-all border border-transparent group-hover:border-primary/20 shadow-sm relative overflow-hidden">
                            <div class="absolute inset-0 bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity">
                            </div>
                            <.icon name={get_field_icon(field.type)} class="size-7 relative z-10" />
                          </div>
                          <div>
                            <div class="flex items-center gap-3 mb-1.5">
                              <h4 class="font-black text-zinc-900 dark:text-white text-lg tracking-tight">
                                {field.name}
                              </h4>
                              <%= if field.required do %>
                                <span class="text-[9px] font-black bg-red-50 dark:bg-red-500/10 text-red-500 px-2 py-0.5 rounded-full uppercase tracking-tighter border border-red-100 dark:border-red-500/20">
                                  Required
                                </span>
                              <% end %>
                            </div>
                            <div class="flex items-center gap-4">
                              <span class="text-[10px] font-black font-mono bg-zinc-100 dark:bg-zinc-800 text-zinc-500 px-2 py-0.5 rounded-md border border-zinc-200 dark:border-zinc-700 uppercase tracking-widest">
                                {field.key}
                              </span>
                              <span class="text-[11px] font-bold text-zinc-400 uppercase tracking-widest">
                                {field.type} field
                                <%= if field.type == "select" && field.options do %>
                                  &bull; {length(field.options)} options
                                <% end %>
                              </span>
                            </div>
                          </div>
                        </div>

                        <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-all transform translate-x-4 group-hover:translate-x-0">
                          <button
                            phx-click="delete_field"
                            phx-value-id={field.id}
                            data-confirm="Permanently delete this custom field? This cannot be undone."
                            class="size-11 rounded-xl bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-500 hover:text-red-500 hover:border-red-500/30 flex items-center justify-center transition-all shadow-sm"
                          >
                            <.icon name="hero-trash" class="size-5" />
                          </button>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

            <div class="xl:col-span-4 space-y-6">
              <div class="bg-white dark:bg-zinc-900 p-8 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm sticky top-8">
                <div class="flex items-center gap-3 mb-6">
                  <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                    <.icon name="hero-information-circle" class="text-primary size-6" />
                  </div>
                  <div>
                    <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                      Field Guide
                    </h3>
                    <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                      Tips for better data
                    </p>
                  </div>
                </div>

                <div class="space-y-6">
                  <div class="p-5 bg-amber-50/50 dark:bg-amber-900/10 rounded-2xl border border-amber-100 dark:border-amber-900/20">
                    <h4 class="text-xs font-black text-amber-700 dark:text-amber-500 uppercase tracking-widest mb-2 flex items-center gap-2">
                      <.icon name="hero-exclamation-triangle" class="size-4" /> Usage Warning
                    </h4>
                    <p class="text-[11px] font-bold text-amber-600/80 dark:text-amber-500/70 leading-relaxed uppercase tracking-wider">
                      Deleting a field will also remove any data stored in it for existing records.
                    </p>
                  </div>

                  <div class="space-y-4">
                    <div class="flex gap-4">
                      <div class="size-8 rounded-lg bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center shrink-0">
                        <.icon name="hero-key" class="size-4 text-zinc-500" />
                      </div>
                      <div>
                        <h5 class="text-xs font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest">
                          Unique Keys
                        </h5>
                        <p class="text-[11px] font-bold text-zinc-500 dark:text-zinc-500 mt-1 uppercase tracking-wider">
                          Use snake_case for system identifiers (e.g., serial_number).
                        </p>
                      </div>
                    </div>

                    <div class="flex gap-4">
                      <div class="size-8 rounded-lg bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center shrink-0">
                        <.icon name="hero-swatch" class="size-4 text-zinc-500" />
                      </div>
                      <div>
                        <h5 class="text-xs font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest">
                          Field Types
                        </h5>
                        <p class="text-[11px] font-bold text-zinc-500 dark:text-zinc-500 mt-1 uppercase tracking-wider">
                          Choose the type that best matches your data format.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Slide-in Form Panel -->
      <div
        :if={@live_action in [:new, :edit]}
        class="fixed right-0 top-0 bottom-0 w-[480px] bg-white dark:bg-zinc-900 border-l border-zinc-200 dark:border-zinc-700 shadow-2xl z-50 flex flex-col animate-in slide-in-from-right duration-300"
      >
        <!-- Form Panel Header -->
        <div class="p-6 border-b border-zinc-200 dark:border-zinc-700 bg-zinc-50/50 dark:bg-zinc-800/20 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-black text-zinc-900 dark:text-white tracking-tighter">
              Define Custom Field
            </h2>
            <p class="text-sm font-bold text-zinc-500 mt-1 uppercase tracking-wide">
              Adding attribute to {@active_tab} model
            </p>
          </div>
          <button
            phx-click={JS.patch(~p"/settings/custom-fields?tab=#{@active_tab}")}
            class="size-8 rounded-lg hover:bg-zinc-100 dark:hover:bg-zinc-800 flex items-center justify-center text-zinc-400 hover:text-zinc-600 transition-all"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>
        
    <!-- Form Content -->
        <div class="flex-1 overflow-y-auto p-8">
          <.form
            for={@form}
            id="custom-field-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-8"
          >
            <div class="grid grid-cols-1 gap-8">
              <div class="space-y-2">
                <label class="block text-sm font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest">
                  Field Label
                </label>
                <input
                  type="text"
                  name="custom_field_definition[name]"
                  value={@form[:name].value}
                  class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium"
                  placeholder="e.g. Serial Number"
                  required
                />
                <.error :for={msg <- @form[:name].errors}>{translate_error(msg)}</.error>
              </div>

              <div class="space-y-2">
                <label class="block text-sm font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest">
                  System Key
                </label>
                <input
                  type="text"
                  name="custom_field_definition[key]"
                  value={@form[:key].value}
                  class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-mono text-sm uppercase"
                  placeholder="e.g. serial_number"
                  required
                />
                <.error :for={msg <- @form[:key].errors}>{translate_error(msg)}</.error>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-8 items-start">
              <div class="space-y-2">
                <label class="block text-sm font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest">
                  Field Type
                </label>
                <select
                  name="custom_field_definition[type]"
                  class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium"
                >
                  {Phoenix.HTML.Form.options_for_select(
                    [
                      {"Text Input", "text"},
                      {"Number", "number"},
                      {"Date Picker", "date"},
                      {"Checkbox (Yes/No)", "boolean"},
                      {"Dropdown Menu", "select"}
                    ],
                    @form[:type].value
                  )}
                </select>
              </div>

              <div class="flex items-center gap-3">
                <div class="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    name="custom_field_definition[required]"
                    value="true"
                    checked={@form[:required].value == true}
                    class="sr-only peer"
                    id="field-required-toggle"
                  />
                  <div class="w-11 h-6 bg-zinc-200 peer-focus:outline-none rounded-full peer dark:bg-zinc-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-zinc-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-zinc-600 peer-checked:bg-primary">
                  </div>
                  <label
                    for="field-required-toggle"
                    class="ml-3 text-sm font-black text-zinc-700 dark:text-zinc-300 uppercase tracking-widest"
                  >
                    Mandatory
                  </label>
                </div>
              </div>
            </div>

            <%= if Ecto.Changeset.get_field(@form.source, :type) == "select" do %>
              <div class="bg-zinc-50 dark:bg-zinc-950 p-6 rounded-[24px] border-2 border-dashed border-zinc-200 dark:border-zinc-800">
                <label class="block text-xs font-black text-zinc-400 uppercase tracking-widest mb-3">
                  Dropdown Options
                </label>
                <input
                  name="custom_field_definition[options_string]"
                  value={Enum.join(Ecto.Changeset.get_field(@form.source, :options) || [], ", ")}
                  class="w-full px-4 py-3 border border-zinc-200 dark:border-zinc-700 rounded-xl bg-white dark:bg-zinc-900 focus:ring-2 focus:ring-primary/30 focus:border-primary outline-none font-medium mb-3"
                  placeholder="Option 1, Option 2, Option 3"
                />
                <p class="text-[10px] font-bold text-zinc-500 uppercase tracking-wider">
                  Separate options with commas.
                </p>
              </div>
            <% end %>
            
    <!-- Hidden fields -->
            <input type="hidden" name="custom_field_definition[target]" value={@form[:target].value} />
            <input
              type="hidden"
              name="custom_field_definition[organization_id]"
              value={@form[:organization_id].value}
            />

            <div class="flex justify-end gap-3 pt-4">
              <button
                type="button"
                phx-click={JS.patch(~p"/settings/custom-fields?tab=#{@active_tab}")}
                class="px-6 py-3 rounded-xl text-sm font-bold text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-10 py-3 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
              >
                Create Field
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
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
