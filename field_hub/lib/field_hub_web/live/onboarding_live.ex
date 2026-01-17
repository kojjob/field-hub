defmodule FieldHubWeb.OnboardingLive do
  @moduledoc """
  LiveView for organization onboarding.

  New users without an organization are directed here to create their
  first organization. Once created, they become the owner of the organization.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Accounts.Organization

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
       |> assign(:changeset, changeset)
       |> assign(:slug_preview, nil)}
    end
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
    <div class="mx-auto max-w-xl py-12 px-4">
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
          Create Your Organization
        </h1>
        <p class="mt-2 text-lg text-gray-600 dark:text-gray-400">
          Let's get your business set up in FieldHub.
        </p>
      </div>

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

          <div class="pt-4">
            <button
              type="submit"
              class="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-base font-medium text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200"
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
