defmodule FieldHubWeb.OnboardingLive do
  @moduledoc """
  LiveView for organization onboarding.

  New users without an organization are directed here to create their
  first organization. Once created, they become the owner of the organization.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Accounts.Organization
  alias FieldHub.Config.IndustryTemplates

  @impl true
  def mount(_params, _session, socket) do
    session_user = socket.assigns.current_scope.user

    # Refetch user to get current organization_id (session user may be stale)
    user = Accounts.get_user!(session_user.id)

    # Redirect users who already have an organization
    if user.organization_id do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      changeset = Organization.changeset(%Organization{}, %{})

      {:ok,
       socket
       |> assign(:page_title, "Create Your Organization")
       |> assign(:step, 1)
       |> assign(:changeset, changeset)
       |> assign(:slug_preview, nil)
       |> assign(:selected_template, nil)
       |> assign(:templates, IndustryTemplates.templates())}
    end
  end

  @impl true
  def handle_event("select_template", %{"template" => template_key}, socket) do
    {:noreply, assign(socket, :selected_template, template_key)}
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    {:noreply, assign(socket, :step, 2)}
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    {:noreply, assign(socket, :step, 1)}
  end

  @impl true
  def handle_event("validate", %{"organization" => org_params}, socket) do
    changeset =
      %Organization{}
      |> Organization.changeset(org_params)
      |> Map.put(:action, :validate)

    # Generate slug preview
    slug_preview =
      case Map.get(org_params, "name", "") do
        "" -> nil
        name -> Organization.generate_slug(name)
      end

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:slug_preview, slug_preview)}
  end

  @impl true
  def handle_event("create", %{"organization" => org_params}, socket) do
    user = socket.assigns.current_scope.user

    # Generate slug from name
    name = Map.get(org_params, "name", "")
    slug = Accounts.generate_unique_slug(name)
    org_params = Map.put(org_params, "slug", slug)

    # Apply template configuration if selected
    org_params =
      if template_key = socket.assigns.selected_template do
        config = IndustryTemplates.get_config(String.to_existing_atom(template_key))
        org_params
        |> Map.put("terminology", config.terminology)
        |> Map.put("primary_color", config.primary_color)
        |> Map.put("secondary_color", config.secondary_color)
      else
        org_params
      end

    case Accounts.create_organization_with_owner(org_params, user) do
      {:ok, %{organization: _org, user: _updated_user}} ->
        {:noreply,
         socket
         |> put_flash(:info, "Welcome to FieldHub! Your organization is ready.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, :organization, changeset, _changes} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, _failed_operation, _changeset, _changes} ->
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong. Please try again.")
         |> assign(:changeset, Organization.changeset(%Organization{}, org_params))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl py-12 px-4">
      <div class="text-center mb-8">
        <div class="mx-auto h-16 w-16 rounded-full bg-gradient-to-r from-blue-600 to-indigo-600 flex items-center justify-center mb-4">
          <svg class="h-8 w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
            />
          </svg>
        </div>
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
          <%= if @step == 1, do: "Select Your Industry", else: "Create Your Organization" %>
        </h1>
        <p class="mt-2 text-lg text-gray-600 dark:text-gray-400">
          <%= if @step == 1, do: "Choose a template to get started quickly.", else: "Let's get your business set up." %>
        </p>
      </div>

      <!-- Step indicators -->
      <div class="flex justify-center mb-8">
        <div class="flex items-center gap-2">
          <div class={"w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium #{if @step >= 1, do: "bg-blue-600 text-white", else: "bg-gray-200 text-gray-600"}"}>1</div>
          <div class={"w-16 h-1 #{if @step >= 2, do: "bg-blue-600", else: "bg-gray-200"}"}></div>
          <div class={"w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium #{if @step >= 2, do: "bg-blue-600 text-white", else: "bg-gray-200 text-gray-600"}"}>2</div>
        </div>
      </div>

      <%= if @step == 1 do %>
        <!-- Step 1: Industry Template Selection -->
        <div class="bg-white dark:bg-gray-800 shadow-xl rounded-2xl p-8">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <%= for template <- @templates do %>
              <button
                type="button"
                phx-click="select_template"
                phx-value-template={template.key}
                class={"p-4 rounded-xl border-2 text-left transition-all duration-200 hover:border-blue-400 #{if @selected_template == Atom.to_string(template.key), do: "border-blue-600 bg-blue-50 dark:bg-blue-900/20", else: "border-gray-200 dark:border-gray-700"}"}
              >
                <div class="flex items-start gap-3">
                  <div class="w-10 h-10 rounded-lg flex items-center justify-center bg-gray-100">
                    <.icon name={template.icon} class="w-5 h-5 text-gray-700" />
                  </div>
                  <div>
                    <div class="font-semibold text-gray-900 dark:text-white"><%= template.name %></div>
                    <div class="text-sm text-gray-500 dark:text-gray-400"><%= template.description %></div>
                  </div>
                </div>
              </button>
            <% end %>
          </div>

          <div class="mt-6 flex justify-between items-center">
            <button
              type="button"
              phx-click="next_step"
              class="text-gray-500 hover:text-gray-700 text-sm"
            >
              Skip for now →
            </button>
            <button
              type="button"
              phx-click="next_step"
              disabled={@selected_template == nil}
              class={"px-6 py-3 rounded-lg font-medium transition-all #{if @selected_template, do: "bg-blue-600 text-white hover:bg-blue-700", else: "bg-gray-200 text-gray-400 cursor-not-allowed"}"}
            >
              Continue
            </button>
          </div>
        </div>
      <% else %>
        <!-- Step 2: Organization Details -->
        <div class="bg-white dark:bg-gray-800 shadow-xl rounded-2xl p-8">
          <.form
            for={@changeset}
            id="onboarding-form"
            phx-change="validate"
            phx-submit="create"
            class="space-y-6"
          >
            <div>
              <label
                for="organization_name"
                class="block text-sm font-medium text-gray-700 dark:text-gray-300"
              >
                Organization Name *
              </label>
              <input
                type="text"
                name="organization[name]"
                id="organization_name"
                value={@changeset.changes[:name] || ""}
                class="mt-1 block w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-lg py-3"
                placeholder="Ace HVAC Services"
                phx-debounce="300"
              />
              <%= if error = @changeset.errors[:name] do %>
                <p class="mt-2 text-sm text-red-600">{translate_error(error)}</p>
              <% end %>

              <%= if @slug_preview do %>
                <p class="mt-2 text-sm text-gray-500">
                  Your URL: <span class="font-mono text-blue-600">fieldhub.io/{@slug_preview}</span>
                </p>
              <% end %>
            </div>

            <div>
              <label
                for="organization_email"
                class="block text-sm font-medium text-gray-700 dark:text-gray-300"
              >
                Business Email
              </label>
              <input
                type="email"
                name="organization[email]"
                id="organization_email"
                value={@changeset.changes[:email] || ""}
                class="mt-1 block w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                placeholder="info@acehvac.com"
                phx-debounce="300"
              />
              <%= if error = @changeset.errors[:email] do %>
                <p class="mt-2 text-sm text-red-600">{translate_error(error)}</p>
              <% end %>
            </div>

            <div>
              <label
                for="organization_phone"
                class="block text-sm font-medium text-gray-700 dark:text-gray-300"
              >
                Business Phone
              </label>
              <input
                type="tel"
                name="organization[phone]"
                id="organization_phone"
                value={@changeset.changes[:phone] || ""}
                class="mt-1 block w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                placeholder="555-123-4567"
                phx-debounce="300"
              />
            </div>

            <%= if @selected_template do %>
              <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 flex items-center gap-3">
                <.icon name="hero-check-circle" class="w-5 h-5 text-blue-600" />
                <span class="text-sm text-blue-800 dark:text-blue-200">
                  Using <strong><%= Enum.find(@templates, & Atom.to_string(&1.key) == @selected_template).name %></strong> template
                </span>
              </div>
            <% end %>

            <div class="pt-4 flex gap-3">
              <button
                type="button"
                phx-click="prev_step"
                class="px-4 py-3 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Back
              </button>
              <button
                type="submit"
                class="flex-1 flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-base font-medium text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200"
              >
                Create Organization & Get Started
              </button>
            </div>
          </.form>

          <div class="mt-6 text-center">
            <p class="text-sm text-gray-500 dark:text-gray-400">
              You'll start with a free 14-day trial. No credit card required.
            </p>
          </div>
        </div>
      <% end %>

      <div class="mt-8 grid grid-cols-3 gap-4 text-center">
        <div class="p-4">
          <div class="text-2xl font-bold text-blue-600">Unlimited</div>
          <div class="text-sm text-gray-500">Jobs</div>
        </div>
        <div class="p-4">
          <div class="text-2xl font-bold text-blue-600">5</div>
          <div class="text-sm text-gray-500">Technicians</div>
        </div>
        <div class="p-4">
          <div class="text-2xl font-bold text-blue-600">14 Days</div>
          <div class="text-sm text-gray-500">Free Trial</div>
        </div>
      </div>
    </div>
    """
  end
end
