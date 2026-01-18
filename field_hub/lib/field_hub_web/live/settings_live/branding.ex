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
      |> assign(:form, to_form(form_data))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">Branding Settings</h1>
        <p class="mt-2 text-gray-600">
          Customize how your organization appears in the application.
        </p>
      </div>

      <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
        <!-- Brand Name -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Brand Name</h2>
          <input
            type="text"
            name="branding[brand_name]"
            value={@form.params["brand_name"] || @form.source["brand_name"]}
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            placeholder="Your Company Name"
          />
          <p class="mt-2 text-sm text-gray-500">
            This name appears in the sidebar and app title.
          </p>
        </div>

        <!-- Logo URL -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Logo URL</h2>
          <input
            type="url"
            name="branding[logo_url]"
            value={@form.params["logo_url"] || @form.source["logo_url"]}
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            placeholder="https://example.com/logo.png"
          />
          <p class="mt-2 text-sm text-gray-500">
            URL to your company logo. Recommended size: 200x50px.
          </p>
        </div>

        <!-- Colors -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Brand Colors</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Primary Color</label>
              <div class="flex gap-3">
                <input
                  type="color"
                  name="branding[primary_color]"
                  value={@form.params["primary_color"] || @form.source["primary_color"]}
                  class="h-10 w-16 rounded border border-gray-300 cursor-pointer"
                />
                <input
                  type="text"
                  value={@form.params["primary_color"] || @form.source["primary_color"]}
                  class="flex-1 px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
                  readonly
                />
              </div>
              <p class="mt-1 text-xs text-gray-400">Used for buttons and accents</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Secondary Color</label>
              <div class="flex gap-3">
                <input
                  type="color"
                  name="branding[secondary_color]"
                  value={@form.params["secondary_color"] || @form.source["secondary_color"]}
                  class="h-10 w-16 rounded border border-gray-300 cursor-pointer"
                />
                <input
                  type="text"
                  value={@form.params["secondary_color"] || @form.source["secondary_color"]}
                  class="flex-1 px-3 py-2 border border-gray-300 rounded-lg bg-gray-50"
                  readonly
                />
              </div>
              <p class="mt-1 text-xs text-gray-400">Used for links and secondary elements</p>
            </div>
          </div>
        </div>

        <!-- Preview -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Preview</h2>
          <div class="bg-zinc-900 rounded-lg p-4 flex items-center gap-3">
            <div class="h-8 w-8 rounded bg-zinc-800 flex items-center justify-center">
              <span class="text-xs font-bold" style={"color: #{@form.params["primary_color"] || @form.source["primary_color"]}"}>CO</span>
            </div>
            <span class="text-white font-semibold"><%= @form.params["brand_name"] || @form.source["brand_name"] || "Your Brand" %></span>
          </div>
          <div class="mt-4 flex gap-3">
            <button
              type="button"
              class="px-4 py-2 rounded-lg text-white font-medium"
              style={"background-color: #{@form.params["primary_color"] || @form.source["primary_color"]}"}
            >
              Primary Button
            </button>
            <button
              type="button"
              class="px-4 py-2 rounded-lg font-medium"
              style={"color: #{@form.params["secondary_color"] || @form.source["secondary_color"]}; border: 1px solid #{@form.params["secondary_color"] || @form.source["secondary_color"]}"}
            >
              Secondary Button
            </button>
          </div>
        </div>

        <div class="flex justify-end gap-3">
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
