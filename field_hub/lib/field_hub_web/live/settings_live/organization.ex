defmodule FieldHubWeb.SettingsLive.Organization do
  @moduledoc """
  Settings page for configuring organization details.
  Allows administrators to manage basic info, location, and regional settings.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  @impl true
  def mount(_params, _session, socket) do
    org = socket.assigns.current_organization

    socket =
      socket
      |> assign(:page_title, "Organization Settings")
      |> assign(:current_nav, :organization)
      |> assign(:form, to_form(Accounts.change_organization(org)))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10 pb-20">
      <!-- Page Heading -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            System
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Organization Settings
          </h2>
          <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 max-w-lg">
            Manage your company details, address, and regional preferences.
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
          <.form
            for={@form}
            id="organization-form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-8"
          >
            <!-- General Information -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden group">
              <div class="absolute top-0 right-0 w-24 h-24 bg-primary/5 rounded-full -mr-12 -mt-12 transition-all group-hover:bg-primary/10">
              </div>

              <div class="flex items-center gap-3 mb-8">
                <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                  <.icon name="hero-building-office-2" class="text-primary size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    General Information
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    Basic company details
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div class="md:col-span-2 space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Organization Name
                  </label>
                  <.input
                    field={@form[:name]}
                    type="text"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Phone Support
                  </label>
                  <.input
                    field={@form[:phone]}
                    type="tel"
                    placeholder="+1 (555) 000-0000"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Support Email
                  </label>
                  <.input
                    field={@form[:email]}
                    type="email"
                    placeholder="support@company.com"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Industry
                  </label>
                  <.input
                    field={@form[:industry]}
                    type="text"
                    placeholder="e.g. HVAC, Plumbing"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Company Size
                  </label>
                  <.input
                    field={@form[:size]}
                    type="select"
                    options={["1-5": "1-5", "6-20": "6-20", "21-50": "21-50", "50+": "50+"]}
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium focus:ring-0"
                  />
                </div>
              </div>
            </div>
            
    <!-- Location Settings -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden group">
              <div class="absolute top-0 right-0 w-24 h-24 bg-emerald-500/5 rounded-full -mr-12 -mt-12 transition-all group-hover:bg-emerald-500/10">
              </div>

              <div class="flex items-center gap-3 mb-8">
                <div class="size-11 rounded-xl bg-emerald-500/10 flex items-center justify-center">
                  <.icon name="hero-map-pin" class="text-emerald-500 size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Location & Address
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    Headquarters location
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div class="md:col-span-2 space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Street Address
                  </label>
                  <.input
                    field={@form[:address_line1]}
                    type="text"
                    placeholder="123 Main St"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="md:col-span-2 space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Apartment, Suite, etc.
                  </label>
                  <.input
                    field={@form[:address_line2]}
                    type="text"
                    placeholder="Suite 100"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">City</label>
                  <.input
                    field={@form[:city]}
                    type="text"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    State / Province
                  </label>
                  <.input
                    field={@form[:state]}
                    type="text"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    ZIP / Postal Code
                  </label>
                  <.input
                    field={@form[:zip]}
                    type="text"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Country
                  </label>
                  <.input
                    field={@form[:country]}
                    type="text"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>
              </div>
            </div>
            
    <!-- Regional Settings -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden group">
              <div class="absolute top-0 right-0 w-24 h-24 bg-amber-500/5 rounded-full -mr-12 -mt-12 transition-all group-hover:bg-amber-500/10">
              </div>

              <div class="flex items-center gap-3 mb-8">
                <div class="size-11 rounded-xl bg-amber-500/10 flex items-center justify-center">
                  <.icon name="hero-globe-americas" class="text-amber-500 size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Regional Settings
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    Timezone and formatting
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Timezone
                  </label>
                  <!-- In a real app, this would be a select of actual IANA timezones -->
                  <.input
                    field={@form[:timezone]}
                    type="text"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                  <p class="text-xs text-zinc-500">e.g. America/New_York</p>
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Currency
                  </label>
                  <.input
                    field={@form[:currency]}
                    type="text"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white font-medium"
                  />
                </div>
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
                <.icon name="hero-check" class="size-5" /> Save Changes
              </button>
            </div>
          </.form>
        </div>

        <div class="xl:col-span-4 space-y-6">
          <!-- Info Card -->
          <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
            <div class="flex items-center gap-3 mb-6">
              <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                <.icon name="hero-identification" class="text-primary size-6" />
              </div>
              <div>
                <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                  Identity
                </h3>
                <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                  Organization Profile
                </p>
              </div>
            </div>

            <div class="space-y-4">
              <div class="p-4 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-100 dark:border-zinc-800">
                <p class="text-xs font-bold text-zinc-500 uppercase tracking-wider mb-1">
                  Organization ID
                </p>
                <p class="font-mono text-xs text-zinc-700 dark:text-zinc-300 truncate">
                  {@current_organization.id}
                </p>
              </div>

              <div class="p-4 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-100 dark:border-zinc-800">
                <p class="text-xs font-bold text-zinc-500 uppercase tracking-wider mb-1">
                  Slug (URL)
                </p>
                <p class="font-mono text-xs text-zinc-700 dark:text-zinc-300 truncate">
                  {@current_organization.slug}
                </p>
              </div>
            </div>

            <div class="mt-6 p-4 bg-yellow-50 dark:bg-yellow-900/10 rounded-xl border border-yellow-100 dark:border-yellow-900/20">
              <div class="flex gap-3">
                <.icon
                  name="hero-exclamation-triangle"
                  class="size-5 text-yellow-600 dark:text-yellow-500 shrink-0"
                />
                <div>
                  <p class="text-xs font-bold text-yellow-800 dark:text-yellow-500">
                    Need to change your slug?
                  </p>
                  <p class="text-[11px] text-yellow-700 dark:text-yellow-400 mt-1">
                    This affects your portal URLs. Please contact support to change.
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
  def handle_event("validate", %{"organization" => params}, socket) do
    changeset =
      socket.assigns.current_organization
      |> Accounts.change_organization(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"organization" => params}, socket) do
    case Accounts.update_organization(socket.assigns.current_organization, params) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization settings updated successfully!")
         |> push_navigate(to: ~p"/settings/organization")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
