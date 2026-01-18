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
    <div class="max-w-4xl mx-auto">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-zinc-900 dark:text-white tracking-tight">
          Branding Settings
        </h1>
        <p class="mt-2 text-zinc-600 dark:text-zinc-400">
          Customize how your organization appears in the application. These settings will be applied across your workspace.
        </p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <div class="lg:col-span-7">
          <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
            <!-- Brand Name & Logo -->
            <div class="bg-white dark:bg-zinc-800/50 rounded-2xl shadow-sm border border-zinc-200 dark:border-zinc-700/50 p-6 overflow-hidden relative">
              <div class="absolute top-0 left-0 w-1 h-full bg-indigo-500"></div>
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-white mb-6 flex items-center gap-2">
                <.icon name="hero-identification" class="size-5 text-indigo-500" /> Identity
              </h2>

              <div class="space-y-4">
                <.input
                  field={@form[:brand_name]}
                  label="Brand Name"
                  placeholder="Your Company Name"
                  class="input-bordered"
                />

                <.input
                  field={@form[:logo_url]}
                  label="Logo URL"
                  placeholder="https://example.com/logo.png"
                  class="input-bordered"
                />
                <p class="text-xs text-zinc-500 mt-1 italic">
                  Tip: Use a PNG with transparency. Recommended height: 40px.
                </p>
              </div>
            </div>
            
    <!-- Colors -->
            <div class="bg-white dark:bg-zinc-800/50 rounded-2xl shadow-sm border border-zinc-200 dark:border-zinc-700/50 p-6 overflow-hidden relative">
              <div class="absolute top-0 left-0 w-1 h-full bg-indigo-600"></div>
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-white mb-6 flex items-center gap-2">
                <.icon name="hero-swatch" class="size-5 text-indigo-600" /> Visual Theme
              </h2>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-2">
                    Primary Color
                  </label>
                  <div class="flex gap-2">
                    <input
                      type="color"
                      name="branding[primary_color]"
                      value={@form[:primary_color].value}
                      class="h-11 w-14 rounded-lg border border-zinc-300 dark:border-zinc-600 cursor-pointer overflow-hidden p-0"
                    />
                    <div class="relative flex-1">
                      <input
                        type="text"
                        value={@form[:primary_color].value}
                        class="w-full px-3 py-2.5 border border-zinc-300 dark:border-zinc-600 rounded-lg bg-zinc-50 dark:bg-zinc-900 font-mono text-sm"
                        readonly
                      />
                    </div>
                  </div>
                  <p class="mt-2 text-xs text-zinc-500">
                    Buttons, active states, and primary accents.
                  </p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-2">
                    Secondary Color
                  </label>
                  <div class="flex gap-2">
                    <input
                      type="color"
                      name="branding[secondary_color]"
                      value={@form[:secondary_color].value}
                      class="h-11 w-14 rounded-lg border border-zinc-300 dark:border-zinc-600 cursor-pointer overflow-hidden p-0"
                    />
                    <div class="relative flex-1">
                      <input
                        type="text"
                        value={@form[:secondary_color].value}
                        class="w-full px-3 py-2.5 border border-zinc-300 dark:border-zinc-600 rounded-lg bg-zinc-50 dark:bg-zinc-900 font-mono text-sm"
                        readonly
                      />
                    </div>
                  </div>
                  <p class="mt-2 text-xs text-zinc-500">Secondary actions and subtle UI elements.</p>
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-3 pt-4">
              <.button navigate={~p"/dashboard"} class="btn-ghost">
                Cancel
              </.button>
              <.button type="submit" variant="primary" class="px-8" phx-disable-with="Saving...">
                Save Changes
              </.button>
            </div>
          </.form>
        </div>
        
    <!-- Preview Column -->
        <div class="lg:col-span-5">
          <div class="sticky top-8 space-y-6">
            <div class="bg-zinc-100 dark:bg-zinc-900 rounded-3xl p-1 border border-zinc-200 dark:border-zinc-800 shadow-xl overflow-hidden">
              <div class="bg-zinc-200 dark:bg-zinc-800 px-4 py-2 flex items-center gap-1.5">
                <div class="size-2.5 rounded-full bg-zinc-400"></div>
                <div class="size-2.5 rounded-full bg-zinc-400"></div>
                <div class="size-2.5 rounded-full bg-zinc-400"></div>
                <div class="ml-2 bg-white dark:bg-zinc-700 rounded-md px-3 py-0.5 text-[10px] text-zinc-400 flex-1 truncate">
                  https://fieldhub.app/{@current_organization.slug}
                </div>
              </div>

              <div class="bg-white dark:bg-zinc-950 min-h-[400px] flex flex-col">
                <!-- Mock Sidebar -->
                <div class="flex flex-1">
                  <div class="w-16 border-r border-zinc-100 dark:border-zinc-900 bg-zinc-50 dark:bg-zinc-900/50 flex flex-col items-center py-4 gap-4">
                    <div
                      class="size-8 rounded-lg flex items-center justify-center text-white shadow-lg"
                      style={"background-color: #{@form[:primary_color].value}"}
                    >
                      <span class="text-[10px] font-bold">FH</span>
                    </div>
                    <div class="size-8 rounded-lg bg-zinc-200 dark:bg-zinc-800"></div>
                    <div class="size-8 rounded-lg bg-zinc-200 dark:bg-zinc-800"></div>
                    <div class="mt-auto size-8 rounded-full bg-indigo-500/20 border border-indigo-500/30">
                    </div>
                  </div>

                  <div class="flex-1 p-6">
                    <div class="flex items-center gap-3 mb-8">
                      <%= if @form[:logo_url].value && @form[:logo_url].value != "" do %>
                        <img src={@form[:logo_url].value} class="h-6 w-auto" alt="Logo preview" />
                      <% else %>
                        <div class="h-6 w-24 bg-zinc-100 dark:bg-zinc-800 rounded animate-pulse">
                        </div>
                      <% end %>
                      <h3 class="text-sm font-bold text-zinc-900 dark:text-white">
                        {@form[:brand_name].value || "Your Brand"}
                      </h3>
                    </div>

                    <div class="space-y-4">
                      <div class="h-8 w-1/2 bg-zinc-100 dark:bg-zinc-800 rounded-lg"></div>
                      <div class="grid grid-cols-2 gap-4">
                        <div class="h-24 bg-zinc-50 dark:bg-zinc-900 rounded-xl border border-zinc-100 dark:border-zinc-800 flex flex-col p-3 gap-2">
                          <div class="size-6 rounded bg-zinc-200 dark:bg-zinc-800"></div>
                          <div class="h-3 w-1/2 bg-zinc-200 dark:bg-zinc-800 rounded"></div>
                          <div
                            class="h-5 w-3/4 bg-zinc-200 dark:bg-zinc-800 rounded mt-auto"
                            style={"background-color: #{@form[:primary_color].value}20"}
                          >
                          </div>
                        </div>
                        <div class="h-24 bg-zinc-50 dark:bg-zinc-900 rounded-xl border border-zinc-100 dark:border-zinc-800">
                        </div>
                      </div>

                      <div class="flex gap-2 mt-4">
                        <div
                          class="px-4 py-2 rounded-lg text-[10px] font-bold text-white shadow-sm"
                          style={"background-color: #{@form[:primary_color].value}"}
                        >
                          PRIMARY ACTION
                        </div>
                        <div
                          class="px-4 py-2 rounded-lg text-[10px] font-bold border"
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
            <p class="text-center text-xs text-zinc-500">
              Live preview of your organization dashboard
            </p>
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
