defmodule FieldHubWeb.SettingsLive.Branding do
  @moduledoc """
  Settings page for configuring organization branding.
  Allows organizations to customize brand name, logo, and colors.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  @impl true
  def mount(_params, _session, socket) do
    org = socket.assigns.current_organization

    form_data = %{
      "brand_name" => org.brand_name || org.name,
      "logo_url" => org.logo_url || "",
      "primary_color" => org.primary_color || "#3B82F6",
      "secondary_color" => org.secondary_color || "#1E40AF"
    }

    socket =
      socket
      |> assign(:page_title, "Branding Settings")
      |> assign(:form, to_form(form_data, as: "branding"))

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
            Settings
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Branding & Identity
          </h2>
          <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 max-w-lg">
            Customize how your organization appears across the platform. These settings will be applied to your workspace.
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <.link navigate={~p"/dashboard"}>
            <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
              <.icon name="hero-arrow-left" class="size-4" /> Back
            </button>
          </.link>
        </div>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-12 gap-8">
        <!-- Form Column -->
        <div class="xl:col-span-7 space-y-6">
          <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
            <!-- Identity Card -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
              <div class="flex items-center gap-3 mb-6">
                <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                  <.icon name="hero-identification" class="text-primary size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Brand Identity
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500">
                    Your organization's name and logo
                  </p>
                </div>
              </div>

              <div class="space-y-5">
                <div>
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300 mb-2">
                    Brand Name
                  </label>
                  <input
                    type="text"
                    name="branding[brand_name]"
                    value={@form[:brand_name].value}
                    placeholder="Your Company Name"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium"
                  />
                </div>

                <div>
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300 mb-2">
                    Logo URL
                  </label>
                  <div class="flex gap-3">
                    <div class="size-12 rounded-xl bg-zinc-100 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 flex items-center justify-center overflow-hidden flex-shrink-0">
                      <%= if @form[:logo_url].value && @form[:logo_url].value != "" do %>
                        <img src={@form[:logo_url].value} class="size-10 object-contain" alt="Logo" />
                      <% else %>
                        <.icon name="hero-photo" class="size-6 text-zinc-400" />
                      <% end %>
                    </div>
                    <input
                      type="text"
                      name="branding[logo_url]"
                      value={@form[:logo_url].value}
                      placeholder="https://example.com/logo.png"
                      class="flex-1 px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-mono text-sm"
                    />
                  </div>
                  <p class="text-[10px] text-zinc-400 mt-2 uppercase tracking-wide font-bold">
                    Use a PNG with transparency • Recommended height: 40px
                  </p>
                </div>
              </div>
            </div>

            <!-- Colors Card -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
              <div class="flex items-center gap-3 mb-6">
                <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                  <.icon name="hero-swatch" class="text-primary size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Color Palette
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500">
                    Define your brand colors
                  </p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Primary Color -->
                <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl p-5 border border-zinc-100 dark:border-zinc-800">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300 mb-3">
                    Primary Color
                  </label>
                  <div class="flex gap-3 items-center">
                    <div class="relative">
                      <input
                        type="color"
                        name="branding[primary_color]"
                        value={@form[:primary_color].value}
                        class="size-14 rounded-xl border-2 border-zinc-200 dark:border-zinc-700 cursor-pointer overflow-hidden p-0 shadow-lg"
                      />
                    </div>
                    <div class="flex-1">
                      <input
                        type="text"
                        value={@form[:primary_color].value}
                        class="w-full px-3 py-2.5 rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-900 font-mono text-sm text-center font-bold uppercase"
                        readonly
                      />
                      <p class="mt-1.5 text-[10px] text-zinc-400 font-bold uppercase tracking-wide">
                        Buttons & Accents
                      </p>
                    </div>
                  </div>
                </div>

                <!-- Secondary Color -->
                <div class="bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl p-5 border border-zinc-100 dark:border-zinc-800">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300 mb-3">
                    Secondary Color
                  </label>
                  <div class="flex gap-3 items-center">
                    <div class="relative">
                      <input
                        type="color"
                        name="branding[secondary_color]"
                        value={@form[:secondary_color].value}
                        class="size-14 rounded-xl border-2 border-zinc-200 dark:border-zinc-700 cursor-pointer overflow-hidden p-0 shadow-lg"
                      />
                    </div>
                    <div class="flex-1">
                      <input
                        type="text"
                        value={@form[:secondary_color].value}
                        class="w-full px-3 py-2.5 rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-900 font-mono text-sm text-center font-bold uppercase"
                        readonly
                      />
                      <p class="mt-1.5 text-[10px] text-zinc-400 font-bold uppercase tracking-wide">
                        Secondary UI
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex justify-end gap-3 pt-2">
              <.link navigate={~p"/dashboard"}>
                <button type="button" class="px-6 py-3 rounded-xl text-sm font-bold text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all">
                  Cancel
                </button>
              </.link>
              <button type="submit" class="flex items-center gap-2 px-8 py-3 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1" phx-disable-with="Saving...">
                <.icon name="hero-check" class="size-5" /> Save Changes
              </button>
            </div>
          </.form>
        </div>

        <!-- Preview Column -->
        <div class="xl:col-span-5">
          <div class="sticky top-8 space-y-4">
            <!-- Preview Card -->
            <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
              <div class="flex items-center gap-3 mb-6">
                <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                  <.icon name="hero-eye" class="text-primary size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Live Preview
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500">
                    See how your brand appears
                  </p>
                </div>
              </div>

              <!-- Browser Mock -->
              <div class="bg-zinc-100 dark:bg-zinc-800 rounded-2xl overflow-hidden border border-zinc-200 dark:border-zinc-700">
                <div class="bg-zinc-200 dark:bg-zinc-700 px-3 py-2 flex items-center gap-1.5">
                  <div class="size-2 rounded-full bg-zinc-400"></div>
                  <div class="size-2 rounded-full bg-zinc-400"></div>
                  <div class="size-2 rounded-full bg-zinc-400"></div>
                  <div class="ml-2 bg-white dark:bg-zinc-600 rounded-md px-3 py-0.5 text-[9px] text-zinc-400 flex-1 truncate font-mono">
                    fieldhub.app/{@current_organization.slug}
                  </div>
                </div>

                <div class="bg-white dark:bg-zinc-900 min-h-[320px] flex">
                  <!-- Mock Sidebar -->
                  <div class="w-14 border-r border-zinc-100 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-800/50 flex flex-col items-center py-4 gap-3">
                    <div
                      class="size-8 rounded-lg flex items-center justify-center text-white shadow-lg font-black text-[9px]"
                      style={"background-color: #{@form[:primary_color].value}"}
                    >
                      FH
                    </div>
                    <div class="size-8 rounded-lg bg-zinc-200 dark:bg-zinc-700"></div>
                    <div class="size-8 rounded-lg bg-zinc-200 dark:bg-zinc-700"></div>
                  </div>

                  <!-- Mock Content -->
                  <div class="flex-1 p-4">
                    <div class="flex items-center gap-2 mb-4">
                      <%= if @form[:logo_url].value && @form[:logo_url].value != "" do %>
                        <img src={@form[:logo_url].value} class="h-5 w-auto" alt="Logo" />
                      <% end %>
                      <span class="text-[10px] font-black text-zinc-900 dark:text-white">
                        {@form[:brand_name].value || "Your Brand"}
                      </span>
                    </div>

                    <div class="space-y-3">
                      <div class="h-4 w-1/3 bg-zinc-100 dark:bg-zinc-800 rounded"></div>
                      <div class="grid grid-cols-2 gap-2">
                        <div class="h-16 bg-zinc-50 dark:bg-zinc-800/50 rounded-lg border border-zinc-100 dark:border-zinc-800 p-2">
                          <div class="size-4 rounded bg-zinc-200 dark:bg-zinc-700 mb-1"></div>
                          <div class="h-2 w-1/2 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
                        </div>
                        <div class="h-16 bg-zinc-50 dark:bg-zinc-800/50 rounded-lg border border-zinc-100 dark:border-zinc-800 p-2">
                          <div class="size-4 rounded bg-zinc-200 dark:bg-zinc-700 mb-1"></div>
                          <div class="h-2 w-1/2 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
                        </div>
                      </div>

                      <div class="flex gap-2 mt-3">
                        <div
                          class="px-3 py-1.5 rounded-lg text-[8px] font-black text-white shadow-sm"
                          style={"background-color: #{@form[:primary_color].value}"}
                        >
                          PRIMARY
                        </div>
                        <div
                          class="px-3 py-1.5 rounded-lg text-[8px] font-black border"
                          style={"color: #{@form[:secondary_color].value}; border-color: #{@form[:secondary_color].value}"}
                        >
                          SECONDARY
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Quick Stats -->
            <div class="grid grid-cols-2 gap-3">
              <div class="bg-white dark:bg-zinc-900 p-4 rounded-xl border border-zinc-200 dark:border-zinc-800">
                <p class="text-[10px] font-black text-zinc-400 uppercase tracking-wide mb-1">Primary</p>
                <div class="flex items-center gap-2">
                  <div class="size-6 rounded-lg shadow-inner" style={"background-color: #{@form[:primary_color].value}"}></div>
                  <span class="text-sm font-mono font-bold text-zinc-900 dark:text-white">{@form[:primary_color].value}</span>
                </div>
              </div>
              <div class="bg-white dark:bg-zinc-900 p-4 rounded-xl border border-zinc-200 dark:border-zinc-800">
                <p class="text-[10px] font-black text-zinc-400 uppercase tracking-wide mb-1">Secondary</p>
                <div class="flex items-center gap-2">
                  <div class="size-6 rounded-lg shadow-inner" style={"background-color: #{@form[:secondary_color].value}"}></div>
                  <span class="text-sm font-mono font-bold text-zinc-900 dark:text-white">{@form[:secondary_color].value}</span>
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
  def handle_event("validate", %{"branding" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  @impl true
  def handle_event("save", %{"branding" => params}, socket) do
    org = socket.assigns.current_organization

    case Accounts.update_organization(org, %{
           brand_name: params["brand_name"],
           logo_url: params["logo_url"],
           primary_color: params["primary_color"],
           secondary_color: params["secondary_color"]
         }) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Branding updated successfully!")
         |> push_navigate(to: ~p"/settings/branding")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update branding.")}
    end
  end
end
