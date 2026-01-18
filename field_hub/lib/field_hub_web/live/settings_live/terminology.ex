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
      |> assign(:form, to_form(org.terminology || Terminology.defaults(), as: "terminology"))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-zinc-900 dark:text-white tracking-tight">
          Terminology Settings
        </h1>
        <p class="mt-2 text-zinc-600 dark:text-zinc-400">
          Customize the labels used throughout the application to match your industry's language.
        </p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <div class="lg:col-span-8">
          <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
            <!-- Workers Section -->
            <div class="bg-white dark:bg-zinc-800/50 rounded-2xl shadow-sm border border-zinc-200 dark:border-zinc-700/50 p-6 overflow-hidden relative">
              <div class="absolute top-0 left-0 w-1 h-full bg-blue-500"></div>
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-white mb-6 flex items-center gap-2">
                <.icon name="hero-user-group" class="size-5 text-blue-500" /> Worker Labels
              </h2>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <.input
                  field={@form[:worker_label]}
                  label="Singular"
                  placeholder="Technician"
                  class="input-bordered"
                />
                <.input
                  field={@form[:worker_label_plural]}
                  label="Plural"
                  placeholder="Technicians"
                  class="input-bordered"
                />
              </div>
              <p class="mt-4 text-xs text-zinc-500 italic">
                Examples: Technician, Instructor, Caregiver, Driver, Specialist.
              </p>
            </div>

    <!-- Clients Section -->
            <div class="bg-white dark:bg-zinc-800/50 rounded-2xl shadow-sm border border-zinc-200 dark:border-zinc-700/50 p-6 overflow-hidden relative">
              <div class="absolute top-0 left-0 w-1 h-full bg-emerald-500"></div>
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-white mb-6 flex items-center gap-2">
                <.icon name="hero-building-office" class="size-5 text-emerald-500" /> Client Labels
              </h2>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <.input
                  field={@form[:client_label]}
                  label="Singular"
                  placeholder="Customer"
                  class="input-bordered"
                />
                <.input
                  field={@form[:client_label_plural]}
                  label="Plural"
                  placeholder="Customers"
                  class="input-bordered"
                />
              </div>
              <p class="mt-4 text-xs text-zinc-500 italic">
                Examples: Customer, Patient, Property, Resident, Site.
              </p>
            </div>

    <!-- Tasks Section -->
            <div class="bg-white dark:bg-zinc-800/50 rounded-2xl shadow-sm border border-zinc-200 dark:border-zinc-700/50 p-6 overflow-hidden relative">
              <div class="absolute top-0 left-0 w-1 h-full bg-amber-500"></div>
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-white mb-6 flex items-center gap-2">
                <.icon name="hero-briefcase" class="size-5 text-amber-500" /> Task Labels
              </h2>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <.input
                  field={@form[:task_label]}
                  label="Singular"
                  placeholder="Job"
                  class="input-bordered"
                />
                <.input
                  field={@form[:task_label_plural]}
                  label="Plural"
                  placeholder="Jobs"
                  class="input-bordered"
                />
              </div>
              <div class="mt-6">
                <.input
                  field={@form[:dispatch_label]}
                  label="Dispatch / Board Label"
                  placeholder="Dispatch"
                  class="input-bordered"
                />
              </div>
              <p class="mt-4 text-xs text-zinc-500 italic">
                Examples: Job, Visit, Appointment, Delivery, Inspection, Session.
              </p>
            </div>

            <div class="flex justify-end gap-3 pt-4">
              <.button navigate={~p"/dashboard"} class="btn-ghost">
                Cancel
              </.button>
              <.button type="submit" variant="primary" class="px-8" phx-disable-with="Saving...">
                Save Terminology
              </.button>
            </div>
          </.form>
        </div>

        <div class="lg:col-span-4 space-y-6">
          <div class="bg-white dark:bg-zinc-800 rounded-2xl shadow-sm border border-zinc-200 dark:border-zinc-700/50 p-6">
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-white mb-4 flex items-center gap-2">
              <.icon name="hero-bolt" class="size-5 text-primary" /> Quick Presets
            </h2>
            <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-6">
              Apply industry-standard terminology with one click.
            </p>

            <div class="grid grid-cols-1 gap-2">
              <%= for preset <- @presets do %>
                <button
                  type="button"
                  phx-click="apply_preset"
                  phx-value-preset={preset}
                  class="flex items-center justify-between px-4 py-3 rounded-xl border border-zinc-100 dark:border-zinc-700 hover:border-primary hover:bg-primary/5 dark:hover:bg-primary/10 transition-all group text-left"
                >
                  <span class="text-sm font-medium text-zinc-700 dark:text-zinc-300 group-hover:text-primary">
                    {preset |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()}
                  </span>
                  <.icon
                    name="hero-chevron-right"
                    class="size-4 text-zinc-400 group-hover:text-primary transition-transform group-hover:translate-x-0.5"
                  />
                </button>
              <% end %>
            </div>
          </div>

          <div class="bg-primary/5 border border-primary/10 rounded-2xl p-6">
            <div class="flex gap-3">
              <.icon name="hero-information-circle" class="size-6 text-primary shrink-0" />
              <div>
                <h3 class="text-sm font-bold text-zinc-900 dark:text-primary">
                  Why change this?
                </h3>
                <p class="text-xs text-zinc-600 dark:text-primary/80 mt-1 leading-relaxed">
                  Using industry-specific terms makes your team feel at home and simplifies training. These labels will be updated across all menus, forms, and headers.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
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
