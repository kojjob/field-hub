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
      |> assign(:current_nav, :terminology)
      |> assign(:presets, Terminology.available_presets())
      |> assign(:form, to_form(org.terminology || Terminology.defaults(), as: "terminology"))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10 pb-20">
      <!-- Page Heading (matches dashboard) -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            System
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Terminology & Labels
          </h2>
          <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 max-w-lg">
            Customize the labels used throughout the application to match your industry's language.
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <.link navigate={~p"/dashboard"}>
            <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
              <.icon name="hero-arrow-left" class="size-4" /> Back to Dashboard
            </button>
          </.link>
        </div>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-12 gap-8">
        <div class="xl:col-span-8">
          <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-8">
            <!-- Workers Section -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden group">
              <div class="absolute top-0 right-0 w-24 h-24 bg-primary/5 rounded-full -mr-12 -mt-12 transition-all group-hover:bg-primary/10">
              </div>

              <div class="flex items-center gap-3 mb-8">
                <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                  <.icon name="hero-user-group" class="text-primary size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Worker Labels
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    Internal team members
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Singular Name
                  </label>
                  <input
                    type="text"
                    name="terminology[worker_label]"
                    value={@form[:worker_label].value}
                    placeholder="Technician"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium"
                  />
                </div>
                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Plural Name
                  </label>
                  <input
                    type="text"
                    name="terminology[worker_label_plural]"
                    value={@form[:worker_label_plural].value}
                    placeholder="Technicians"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium"
                  />
                </div>
              </div>
              <div class="mt-6 flex items-center gap-2 px-4 py-3 bg-zinc-50 dark:bg-zinc-800/50 rounded-xl border border-dashed border-zinc-200 dark:border-zinc-700">
                <.icon name="hero-light-bulb" class="size-4 text-zinc-400" />
                <p class="text-[11px] font-bold text-zinc-400 uppercase tracking-wide">
                  Common: Technician, Instructor, Specialist, Driver, Inspector
                </p>
              </div>
            </div>
            
    <!-- Clients Section -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden group">
              <div class="absolute top-0 right-0 w-24 h-24 bg-emerald-500/5 rounded-full -mr-12 -mt-12 transition-all group-hover:bg-emerald-500/10">
              </div>

              <div class="flex items-center gap-3 mb-8">
                <div class="size-11 rounded-xl bg-emerald-500/10 flex items-center justify-center">
                  <.icon name="hero-building-office" class="text-emerald-500 size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Client Labels
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    External project entities
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Singular Name
                  </label>
                  <input
                    type="text"
                    name="terminology[client_label]"
                    value={@form[:client_label].value}
                    placeholder="Customer"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all font-medium"
                  />
                </div>
                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Plural Name
                  </label>
                  <input
                    type="text"
                    name="terminology[client_label_plural]"
                    value={@form[:client_label_plural].value}
                    placeholder="Customers"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all font-medium"
                  />
                </div>
              </div>
              <div class="mt-6 flex items-center gap-2 px-4 py-3 bg-zinc-50 dark:bg-zinc-800/50 rounded-xl border border-dashed border-zinc-200 dark:border-zinc-700">
                <.icon name="hero-light-bulb" class="size-4 text-zinc-400" />
                <p class="text-[11px] font-bold text-zinc-400 uppercase tracking-wide">
                  Common: Customer, Client, Patient, Resident, Site, Account
                </p>
              </div>
            </div>
            
    <!-- Tasks Section -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden group">
              <div class="absolute top-0 right-0 w-24 h-24 bg-amber-500/5 rounded-full -mr-12 -mt-12 transition-all group-hover:bg-amber-500/10">
              </div>

              <div class="flex items-center gap-3 mb-8">
                <div class="size-11 rounded-xl bg-amber-500/10 flex items-center justify-center">
                  <.icon name="hero-briefcase" class="text-amber-500 size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Task Labels
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    Operational units of work
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Singular Name
                  </label>
                  <input
                    type="text"
                    name="terminology[task_label]"
                    value={@form[:task_label].value}
                    placeholder="Job"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500 transition-all font-medium"
                  />
                </div>
                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Plural Name
                  </label>
                  <input
                    type="text"
                    name="terminology[task_label_plural]"
                    value={@form[:task_label_plural].value}
                    placeholder="Jobs"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500 transition-all font-medium"
                  />
                </div>
                <div class="md:col-span-2 space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Dispatch Board Label
                  </label>
                  <input
                    type="text"
                    name="terminology[dispatch_label]"
                    value={@form[:dispatch_label].value}
                    placeholder="Dispatch"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-amber-500/30 focus:border-amber-500 transition-all font-medium"
                  />
                </div>
              </div>
              <div class="mt-6 flex items-center gap-2 px-4 py-3 bg-zinc-50 dark:bg-zinc-800/50 rounded-xl border border-dashed border-zinc-200 dark:border-zinc-700">
                <.icon name="hero-light-bulb" class="size-4 text-zinc-400" />
                <p class="text-[11px] font-bold text-zinc-400 uppercase tracking-wide">
                  Common: Job, Visit, Appointment, Delivery, Session, Order, Case
                </p>
              </div>
            </div>

            <div class="flex justify-end gap-3 pt-2">
              <.link navigate={~p"/dashboard"}>
                <button
                  type="button"
                  class="px-6 py-3 rounded-xl text-sm font-bold text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all"
                >
                  Cancel
                </button>
              </.link>
              <button
                type="submit"
                class="flex items-center gap-2 px-8 py-3 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
                phx-disable-with="Saving..."
              >
                <.icon name="hero-check" class="size-5" /> Save Terminology
              </button>
            </div>
          </.form>
        </div>

        <div class="xl:col-span-4 space-y-6">
          <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm sticky top-8">
            <div class="flex items-center gap-3 mb-6">
              <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                <.icon name="hero-bolt" class="text-primary size-6" />
              </div>
              <div>
                <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                  Quick Presets
                </h3>
                <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                  Industry defaults
                </p>
              </div>
            </div>

            <div class="grid grid-cols-1 gap-3">
              <%= for preset <- @presets do %>
                <button
                  type="button"
                  phx-click="apply_preset"
                  phx-value-preset={preset}
                  class="flex items-center justify-between px-5 py-4 rounded-2xl border border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/50 hover:border-primary hover:bg-white dark:hover:bg-zinc-800 transition-all group shadow-sm hover:shadow-md"
                >
                  <div class="flex flex-col">
                    <span class="text-sm font-black text-zinc-700 dark:text-zinc-300 group-hover:text-primary transition-colors">
                      {preset |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()}
                    </span>
                    <span class="text-[10px] font-bold text-zinc-400 group-hover:text-zinc-500 uppercase tracking-wider">
                      Apply labels for this industry
                    </span>
                  </div>
                  <.icon
                    name="hero-chevron-right"
                    class="size-5 text-zinc-300 group-hover:text-primary transition-all group-hover:translate-x-1"
                  />
                </button>
              <% end %>
            </div>

            <div class="mt-8 p-5 bg-primary/5 rounded-2xl border border-primary/10 relative overflow-hidden">
              <div class="relative z-10 flex gap-4">
                <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                  <.icon name="hero-information-circle" class="size-6 text-primary" />
                </div>
                <div>
                  <h3 class="text-sm font-black text-zinc-900 dark:text-white tracking-tight">
                    Why customize?
                  </h3>
                  <p class="text-[11px] font-bold text-zinc-500 dark:text-zinc-400 mt-1 leading-relaxed uppercase tracking-wide">
                    Using industry-specific terms makes your team feel at home and simplifies training.
                  </p>
                </div>
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
