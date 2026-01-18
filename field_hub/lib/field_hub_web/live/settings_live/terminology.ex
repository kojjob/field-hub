defmodule FieldHubWeb.SettingsLive.Terminology do
  @moduledoc """
  Settings page for configuring organization terminology.
  Allows organizations to customize labels for workers, clients, and tasks.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Config.Terminology

  @impl true
  def mount(_params, _session, socket) do
    org = socket.assigns.current_organization

    socket =
      socket
      |> assign(:page_title, "Terminology Settings")
      |> assign(:presets, Terminology.available_presets())
      |> assign(:form, to_form(org.terminology || Terminology.defaults()))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">Terminology Settings</h1>
        <p class="mt-2 text-gray-600">
          Customize the labels used throughout the application to match your industry.
        </p>
      </div>

      <!-- Industry Presets -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Quick Presets</h2>
        <p class="text-sm text-gray-500 mb-4">Select a preset to quickly configure terminology for your industry.</p>
        <div class="flex flex-wrap gap-2">
          <%= for preset <- @presets do %>
            <button
              type="button"
              phx-click="apply_preset"
              phx-value-preset={preset}
              class="px-4 py-2 bg-gray-100 hover:bg-indigo-100 hover:text-indigo-700 rounded-lg text-sm font-medium transition-colors"
            >
              <%= preset |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize() %>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Custom Labels Form -->
      <.form for={@form} phx-submit="save" phx-change="validate" class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Custom Labels</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Worker Label (Singular)</label>
            <input
              type="text"
              name="terminology[worker_label]"
              value={@form.params["worker_label"] || @form.source["worker_label"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Technician"
            />
            <p class="mt-1 text-xs text-gray-400">e.g., Technician, Caregiver, Driver</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Worker Label (Plural)</label>
            <input
              type="text"
              name="terminology[worker_label_plural]"
              value={@form.params["worker_label_plural"] || @form.source["worker_label_plural"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Technicians"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Client Label (Singular)</label>
            <input
              type="text"
              name="terminology[client_label]"
              value={@form.params["client_label"] || @form.source["client_label"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Customer"
            />
            <p class="mt-1 text-xs text-gray-400">e.g., Customer, Patient, Property</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Client Label (Plural)</label>
            <input
              type="text"
              name="terminology[client_label_plural]"
              value={@form.params["client_label_plural"] || @form.source["client_label_plural"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Customers"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Task Label (Singular)</label>
            <input
              type="text"
              name="terminology[task_label]"
              value={@form.params["task_label"] || @form.source["task_label"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Job"
            />
            <p class="mt-1 text-xs text-gray-400">e.g., Job, Visit, Delivery, Inspection</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Task Label (Plural)</label>
            <input
              type="text"
              name="terminology[task_label_plural]"
              value={@form.params["task_label_plural"] || @form.source["task_label_plural"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Jobs"
            />
          </div>

          <div class="md:col-span-2">
            <label class="block text-sm font-medium text-gray-700 mb-1">Dispatch Label</label>
            <input
              type="text"
              name="terminology[dispatch_label]"
              value={@form.params["dispatch_label"] || @form.source["dispatch_label"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              placeholder="Dispatch"
            />
            <p class="mt-1 text-xs text-gray-400">e.g., Dispatch, Schedule, Route</p>
          </div>
        </div>

        <div class="mt-6 flex justify-end gap-3">
          <.link navigate={~p"/dashboard"} class="px-4 py-2 text-gray-700 hover:text-gray-900">
            Cancel
          </.link>
          <button
            type="submit"
            class="px-6 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors"
          >
            Save Changes
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"terminology" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  @impl true
  def handle_event("apply_preset", %{"preset" => preset_name}, socket) do
    preset = Terminology.preset(String.to_existing_atom(preset_name))
    {:noreply, assign(socket, :form, to_form(preset))}
  end

  @impl true
  def handle_event("save", %{"terminology" => params}, socket) do
    org = socket.assigns.current_organization

    case Accounts.update_organization(org, %{terminology: params}) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Terminology updated successfully!")
         |> push_navigate(to: ~p"/settings/terminology")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update terminology.")}
    end
  end
end
