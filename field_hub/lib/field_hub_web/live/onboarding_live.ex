defmodule FieldHubWeb.OnboardingLive do
  @moduledoc """
  LiveView for organization onboarding wizard.
  Beautiful multi-step onboarding with sidebar layout.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Accounts.Organization
  alias FieldHub.Config.IndustryTemplates

  @impl true
  def mount(_params, _session, socket) do
    user = Accounts.get_user!(socket.assigns.current_scope.user.id)
    organization = if user.organization_id, do: Accounts.get_organization!(user.organization_id), else: nil

    cond do
      is_nil(organization) ->
        # Create a blank organization for the form
        changeset = Organization.changeset(%Organization{}, %{})
        form = to_form(changeset, as: "organization")
        {:ok, assign(socket,
          step: 1,
          form: form,
          organization: nil,
          page_title: "Welcome to FieldHub",
          industries: IndustryTemplates.templates(),
          selected_industry: nil
        )}

      organization.onboarding_completed_at ->
        {:ok, push_navigate(socket, to: ~p"/dashboard")}

      true ->
        changeset = Organization.changeset(organization, %{})
        form = to_form(changeset, as: "organization")
        {:ok,
         socket
         |> assign(:page_title, "Configure Your Workspace")
         |> assign(:step, 2)
         |> assign(:organization, organization)
         |> assign(:form, form)
         |> assign(:industries, IndustryTemplates.templates())
         |> assign(:selected_industry, nil)}
    end
  end

  @impl true
  def handle_event("validate", %{"organization" => org_params}, socket) do
    changeset =
      (socket.assigns.organization || %Organization{})
      |> Organization.changeset(org_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "organization"))}
  end

  def handle_event("select_industry", %{"template" => template}, socket) do
    {:noreply, assign(socket, :selected_industry, template)}
  end

  def handle_event("next_step", _params, socket) do
    {:noreply, assign(socket, :step, socket.assigns.step + 1)}
  end

  def handle_event("back", _, socket) do
    {:noreply, assign(socket, :step, max(1, socket.assigns.step - 1))}
  end

  # Step 2: Save Company Details
  def handle_event("save_details", %{"organization" => org_params}, socket) do
    case Accounts.update_organization(socket.assigns.organization, org_params) do
      {:ok, organization} ->
        form = to_form(Organization.changeset(organization, %{}), as: "organization")
        {:noreply,
         socket
         |> assign(:organization, organization)
         |> assign(:step, 3)
         |> assign(:form, form)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "organization"))}
    end
  end

  # Step 3: Save Branding
  def handle_event("save_branding", %{"organization" => org_params}, socket) do
    case Accounts.update_organization(socket.assigns.organization, org_params) do
      {:ok, organization} ->
        form = to_form(Organization.changeset(organization, %{}), as: "organization")
        {:noreply,
         socket
         |> assign(:organization, organization)
         |> assign(:step, 4)
         |> assign(:form, form)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "organization"))}
    end
  end

  # Step 4: Finish
  def handle_event("finish_onboarding", _params, socket) do
    case Accounts.update_organization(socket.assigns.organization, %{onboarding_completed_at: DateTime.utc_now()}) do
      {:ok, _org} ->
        {:noreply,
         socket
         |> put_flash(:info, "Welcome to FieldHub! Your workspace is ready.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not complete onboarding.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden bg-fsm-bg-light dark:bg-fsm-bg-dark font-dashboard">
      <!-- Onboarding Sidebar -->
      <aside class="w-80 flex-shrink-0 border-r border-fsm-border-light dark:border-slate-800 bg-white dark:bg-fsm-sidebar-dark flex flex-col hidden lg:flex">
        <!-- Logo Section -->
        <div class="p-6 border-b border-fsm-border-light dark:border-slate-800">
          <div class="flex items-center gap-3">
            <div class="size-10 bg-fsm-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-fsm-primary/20">
              <span class="material-symbols-outlined notranslate text-2xl">grid_view</span>
            </div>
            <div class="flex flex-col">
              <h1 class="text-xl font-black leading-tight text-slate-900 dark:text-white tracking-tight">
                FieldHub
              </h1>
              <p class="text-[10px] text-fsm-primary font-bold tracking-[0.15em] uppercase leading-none mt-0.5">
                Setup Wizard
              </p>
            </div>
          </div>
        </div>

        <!-- Steps Navigation -->
        <nav class="flex-1 px-6 py-8 space-y-2">
          <.step_item step={1} current={@step} icon="category" label="Industry" description="Select your business type" />
          <.step_item step={2} current={@step} icon="business" label="Company Details" description="Add organization info" />
          <.step_item step={3} current={@step} icon="palette" label="Branding" description="Customize your look" />
          <.step_item step={4} current={@step} icon="rocket_launch" label="Launch" description="You're ready to go!" />
        </nav>

        <!-- Help Section -->
        <div class="p-6 border-t border-fsm-border-light dark:border-slate-800 mt-auto">
          <div class="bg-gradient-to-br from-fsm-primary/10 to-blue-500/10 dark:from-fsm-primary/20 dark:to-blue-500/20 p-5 rounded-2xl border border-fsm-primary/20">
            <div class="flex items-center gap-3 mb-3">
              <div class="size-10 bg-fsm-primary/20 rounded-xl flex items-center justify-center">
                <span class="material-symbols-outlined notranslate text-fsm-primary text-xl">support_agent</span>
              </div>
              <div>
                <p class="text-sm font-bold text-slate-900 dark:text-white">Need Help?</p>
                <p class="text-xs text-slate-500 dark:text-slate-400">We're here for you</p>
              </div>
            </div>
            <button class="w-full bg-white dark:bg-slate-800 text-fsm-primary text-sm font-bold py-2.5 rounded-xl border border-fsm-primary/30 hover:bg-fsm-primary hover:text-white transition-all">
              Chat with us
            </button>
          </div>
        </div>
      </aside>

      <!-- Main Content -->
      <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
        <!-- Top Bar -->
        <header class="h-16 flex items-center justify-between px-8 border-b border-fsm-border-light dark:border-slate-800 bg-white dark:bg-fsm-sidebar-dark">
          <div class="flex items-center gap-4">
            <div class="lg:hidden flex items-center gap-2">
              <div class="size-8 bg-fsm-primary rounded-lg flex items-center justify-center text-white">
                <span class="material-symbols-outlined notranslate text-lg">grid_view</span>
              </div>
              <span class="font-bold text-slate-900 dark:text-white">FieldHub</span>
            </div>
            <div class="hidden lg:block">
              <p class="text-[10px] font-black text-fsm-primary uppercase tracking-[0.2em]">Setup Progress</p>
              <p class="text-sm font-bold text-slate-600 dark:text-slate-300">Step <%= @step %> of 4</p>
            </div>
          </div>
          <div class="flex items-center gap-4">
            <!-- Progress Bar -->
            <div class="hidden sm:flex items-center gap-3">
              <div class="w-48 h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                <div class="h-full bg-gradient-to-r from-fsm-primary to-blue-500 rounded-full transition-all duration-500" style={"width: #{@step * 25}%"}></div>
              </div>
              <span class="text-sm font-bold text-slate-500"><%= @step * 25 %>%</span>
            </div>
          </div>
        </header>

        <!-- Content Area -->
        <main class="flex-1 overflow-y-auto bg-slate-50/50 dark:bg-fsm-bg-dark p-8 lg:p-12">
          <div class="max-w-3xl mx-auto">
            <%= case @step do %>
              <% 1 -> %>
                <.step_1_industry industries={@industries} selected={@selected_industry} />
              <% 2 -> %>
                <.step_2_details form={@form} organization={@organization} />
              <% 3 -> %>
                <.step_3_branding form={@form} />
              <% 4 -> %>
                <.step_4_launch organization={@organization} />
            <% end %>
          </div>
        </main>

      </div>
    </div>
    """
  end

  # Step indicator component
  defp step_item(assigns) do
    step_class = cond do
      assigns.current == assigns.step -> "bg-fsm-primary/10 dark:bg-fsm-primary/20 border border-fsm-primary/30"
      assigns.current > assigns.step -> "opacity-60"
      true -> "opacity-40"
    end
    assigns = assign(assigns, :step_class, step_class)

    ~H"""
    <div class={"flex items-start gap-4 p-4 rounded-2xl transition-all #{@step_class}"}>
      <div class={"size-10 rounded-xl flex items-center justify-center flex-shrink-0 #{if @current >= @step, do: "bg-fsm-primary text-white shadow-lg shadow-fsm-primary/30", else: "bg-slate-200 dark:bg-slate-700 text-slate-400"}"}>
        <%= if @current > @step do %>
          <span class="material-symbols-outlined notranslate text-xl">check</span>
        <% else %>
          <span class="material-symbols-outlined notranslate text-xl"><%= @icon %></span>
        <% end %>
      </div>
      <div class="flex-1 min-w-0">
        <p class={"text-sm font-bold #{if @current == @step, do: "text-slate-900 dark:text-white", else: "text-slate-600 dark:text-slate-400"}"}><%= @label %></p>
        <p class="text-xs text-slate-500 dark:text-slate-500 mt-0.5"><%= @description %></p>
      </div>
    </div>
    """
  end

  # Step 1: Industry Selection
  defp step_1_industry(assigns) do
    ~H"""
    <div class="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div class="text-center mb-10">
        <div class="inline-flex items-center gap-2 bg-fsm-primary/10 text-fsm-primary px-4 py-2 rounded-full text-xs font-bold uppercase tracking-wider mb-4">
          <span class="material-symbols-outlined notranslate text-base">waving_hand</span>
          Getting Started
        </div>
        <h1 class="text-3xl lg:text-4xl font-black text-slate-900 dark:text-white tracking-tight mb-3">
          What's your industry?
        </h1>
        <p class="text-lg text-slate-500 dark:text-slate-400 max-w-xl mx-auto">
          We'll customize terminology and workflows to match your business perfectly.
        </p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <%= for {key, template} <- @industries do %>
          <button
            type="button"
            phx-click="select_industry"
            phx-value-template={key}
            class={"group relative p-6 rounded-2xl border-2 transition-all text-left #{if @selected == to_string(key), do: "border-fsm-primary bg-fsm-primary/5 shadow-lg shadow-fsm-primary/10", else: "border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800/50 hover:border-fsm-primary/50 hover:shadow-md"}"}
          >
            <div class="flex items-start gap-4">
              <div class={"size-12 rounded-xl flex items-center justify-center flex-shrink-0 #{if @selected == to_string(key), do: "bg-fsm-primary text-white", else: "bg-slate-100 dark:bg-slate-700 text-slate-500 group-hover:bg-fsm-primary/20 group-hover:text-fsm-primary"}"}>
                <span class="material-symbols-outlined notranslate text-2xl"><%= template.icon %></span>
              </div>
              <div class="flex-1">
                <h3 class="text-lg font-bold text-slate-900 dark:text-white mb-1"><%= template.name %></h3>
                <p class="text-sm text-slate-500 dark:text-slate-400"><%= template.description %></p>
              </div>
              <%= if @selected == to_string(key) do %>
                <div class="absolute top-4 right-4 size-6 bg-fsm-primary rounded-full flex items-center justify-center">
                  <span class="material-symbols-outlined notranslate text-white text-sm">check</span>
                </div>
              <% end %>
            </div>
          </button>
        <% end %>
      </div>

      <div class="pt-8 flex justify-end">
        <button
          type="button"
          phx-click="next_step"
          disabled={is_nil(@selected)}
          class={"flex items-center gap-2 px-8 py-4 rounded-xl font-bold text-base transition-all #{if @selected, do: "bg-fsm-primary text-white shadow-lg shadow-fsm-primary/30 hover:brightness-110", else: "bg-slate-200 dark:bg-slate-700 text-slate-400 cursor-not-allowed"}"}
        >
          Continue
          <span class="material-symbols-outlined notranslate">arrow_forward</span>
        </button>
      </div>
    </div>
    """
  end

  # Step 2: Company Details
  defp step_2_details(assigns) do
    ~H"""
    <div class="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div class="mb-10">
        <div class="inline-flex items-center gap-2 bg-fsm-primary/10 text-fsm-primary px-4 py-2 rounded-full text-xs font-bold uppercase tracking-wider mb-4">
          <span class="material-symbols-outlined notranslate text-base">business</span>
          Company Profile
        </div>
        <h1 class="text-3xl lg:text-4xl font-black text-slate-900 dark:text-white tracking-tight mb-3">
          Tell us about your company
        </h1>
        <p class="text-lg text-slate-500 dark:text-slate-400">
          This information helps us personalize your experience.
        </p>
      </div>

      <.form for={@form} id="onboarding-form" phx-change="validate" phx-submit="save_details" class="space-y-8">
        <!-- Basic Info Section -->
        <div class="bg-white dark:bg-slate-800/50 rounded-2xl border border-slate-200 dark:border-slate-700 p-6 lg:p-8 space-y-6">
          <div class="flex items-center gap-3 mb-2">
            <div class="size-8 bg-fsm-primary/10 rounded-lg flex items-center justify-center">
              <span class="material-symbols-outlined notranslate text-fsm-primary text-lg">info</span>
            </div>
            <h3 class="text-lg font-bold text-slate-900 dark:text-white">Basic Information</h3>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Organization Name *</label>
              <.input field={@form[:name]} type="text" placeholder="ACME Field Services" class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
            </div>
            <div class="space-y-2">
              <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Contact Email</label>
              <.input field={@form[:email]} type="email" placeholder="contact@company.com" class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
            </div>
            <div class="space-y-2">
              <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Phone Number</label>
              <.input field={@form[:phone]} type="tel" placeholder="+1 (555) 123-4567" class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
            </div>
            <div class="space-y-2">
              <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Website</label>
              <.input field={@form[:website]} type="url" placeholder="https://www.company.com" class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
            </div>
          </div>
        </div>

        <!-- Address Section (International) -->
        <div class="bg-white dark:bg-slate-800/50 rounded-2xl border border-slate-200 dark:border-slate-700 p-6 lg:p-8 space-y-6">
          <div class="flex items-center gap-3 mb-2">
            <div class="size-8 bg-blue-500/10 rounded-lg flex items-center justify-center">
              <span class="material-symbols-outlined notranslate text-blue-500 text-lg">location_on</span>
            </div>
            <h3 class="text-lg font-bold text-slate-900 dark:text-white">Business Address</h3>
          </div>

          <div class="space-y-6">
            <div class="space-y-2">
              <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Street Address</label>
              <.input field={@form[:address]} type="text" placeholder="123 Business Street, Suite 100" class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">City / Town</label>
                <.input field={@form[:city]} type="text" placeholder="London, New York, Lagos..." class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
              </div>
              <div class="space-y-2">
                <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">State / Province / Region</label>
                <.input field={@form[:state]} type="text" placeholder="California, Ontario, Greater Accra..." class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Postal / ZIP Code</label>
                <.input field={@form[:postal_code]} type="text" placeholder="EC1A 1BB, 10001, 00233..." class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
              </div>
              <div class="space-y-2">
                <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Country</label>
                <.input field={@form[:country]} type="text" placeholder="United States, United Kingdom, Ghana..." class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
              </div>
            </div>
          </div>
        </div>

        <!-- Navigation Buttons -->
        <div class="pt-6 flex justify-between items-center">
          <button type="button" phx-click="back" class="flex items-center gap-2 px-6 py-3 text-slate-500 hover:text-slate-700 font-bold transition-colors">
            <span class="material-symbols-outlined notranslate">arrow_back</span>
            Back
          </button>
          <.button type="submit" class="flex items-center gap-2 !bg-fsm-primary !text-white !px-8 !py-4 !rounded-xl !font-bold !text-base shadow-lg shadow-fsm-primary/30 hover:brightness-110 transition-all">
            Continue to Branding
            <span class="material-symbols-outlined notranslate">arrow_forward</span>
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  # Step 3: Branding
  defp step_3_branding(assigns) do
    ~H"""
    <div class="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div class="mb-10">
        <div class="inline-flex items-center gap-2 bg-fsm-primary/10 text-fsm-primary px-4 py-2 rounded-full text-xs font-bold uppercase tracking-wider mb-4">
          <span class="material-symbols-outlined notranslate text-base">palette</span>
          Brand Identity
        </div>
        <h1 class="text-3xl lg:text-4xl font-black text-slate-900 dark:text-white tracking-tight mb-3">
          Make it yours
        </h1>
        <p class="text-lg text-slate-500 dark:text-slate-400">
          Customize colors and branding to match your company identity.
        </p>
      </div>

      <.form for={@form} id="branding-form" phx-change="validate" phx-submit="save_branding" class="space-y-8">
        <div class="bg-white dark:bg-slate-800/50 rounded-2xl border border-slate-200 dark:border-slate-700 p-6 lg:p-8">
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <!-- Color Settings -->
            <div class="space-y-6">
              <div class="flex items-center gap-3 mb-4">
                <div class="size-8 bg-purple-500/10 rounded-lg flex items-center justify-center">
                  <span class="material-symbols-outlined notranslate text-purple-500 text-lg">format_color_fill</span>
                </div>
                <h3 class="text-lg font-bold text-slate-900 dark:text-white">Brand Colors</h3>
              </div>

              <div class="space-y-4">
                <div class="space-y-2">
                  <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Primary Color</label>
                  <div class="flex items-center gap-4">
                    <.input field={@form[:primary_color]} type="color" value="#3B82F6" class="!h-12 !w-20 !p-1 !rounded-xl !border-2 !border-slate-200 dark:!border-slate-700 cursor-pointer" />
                    <span class="text-sm font-mono text-slate-500 dark:text-slate-400">#3B82F6</span>
                  </div>
                </div>
                <div class="space-y-2">
                  <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Secondary Color</label>
                  <div class="flex items-center gap-4">
                    <.input field={@form[:secondary_color]} type="color" value="#1E40AF" class="!h-12 !w-20 !p-1 !rounded-xl !border-2 !border-slate-200 dark:!border-slate-700 cursor-pointer" />
                    <span class="text-sm font-mono text-slate-500 dark:text-slate-400">#1E40AF</span>
                  </div>
                </div>
              </div>

              <div class="space-y-2 pt-4">
                <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Brand Name (Display)</label>
                <.input field={@form[:brand_name]} type="text" placeholder="Your Brand Name" class="!bg-slate-50 dark:!bg-slate-900 !border-slate-200 dark:!border-slate-700 !rounded-xl" />
                <p class="text-xs text-slate-400">How your brand appears to customers</p>
              </div>
            </div>

            <!-- Live Preview -->
            <div class="space-y-4">
              <div class="flex items-center gap-3 mb-4">
                <div class="size-8 bg-green-500/10 rounded-lg flex items-center justify-center">
                  <span class="material-symbols-outlined notranslate text-green-500 text-lg">preview</span>
                </div>
                <h3 class="text-lg font-bold text-slate-900 dark:text-white">Live Preview</h3>
              </div>

              <div class="bg-slate-100 dark:bg-slate-900 rounded-2xl p-6">
                <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg overflow-hidden">
                  <div class="h-3 bg-gradient-to-r from-blue-500 to-blue-600"></div>
                  <div class="p-4">
                    <div class="flex items-center gap-3 mb-4">
                      <div class="size-8 bg-blue-500 rounded-lg"></div>
                      <span class="font-bold text-sm text-slate-900 dark:text-white">Your Brand</span>
                    </div>
                    <div class="space-y-2">
                      <div class="h-2 w-full bg-slate-100 dark:bg-slate-700 rounded"></div>
                      <div class="h-2 w-3/4 bg-slate-100 dark:bg-slate-700 rounded"></div>
                    </div>
                    <div class="mt-4 flex justify-end">
                      <div class="px-4 py-2 bg-blue-500 text-white text-xs font-bold rounded-lg">Action</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Navigation -->
        <div class="pt-6 flex justify-between items-center">
          <button type="button" phx-click="back" class="flex items-center gap-2 px-6 py-3 text-slate-500 hover:text-slate-700 font-bold transition-colors">
            <span class="material-symbols-outlined notranslate">arrow_back</span>
            Back
          </button>
          <.button type="submit" class="flex items-center gap-2 !bg-fsm-primary !text-white !px-8 !py-4 !rounded-xl !font-bold !text-base shadow-lg shadow-fsm-primary/30 hover:brightness-110 transition-all">
            Almost Done!
            <span class="material-symbols-outlined notranslate">arrow_forward</span>
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  # Step 4: Launch
  defp step_4_launch(assigns) do
    ~H"""
    <div class="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div class="text-center py-8">
        <!-- Success Animation -->
        <div class="relative inline-block mb-8">
          <div class="absolute inset-0 bg-green-400/30 rounded-full blur-2xl animate-pulse"></div>
          <div class="relative size-24 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full flex items-center justify-center shadow-2xl shadow-green-500/30">
            <span class="material-symbols-outlined notranslate text-white text-5xl">rocket_launch</span>
          </div>
        </div>

        <div class="inline-flex items-center gap-2 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 px-4 py-2 rounded-full text-xs font-bold uppercase tracking-wider mb-4">
          <span class="material-symbols-outlined notranslate text-base">celebration</span>
          Setup Complete
        </div>

        <h1 class="text-3xl lg:text-4xl font-black text-slate-900 dark:text-white tracking-tight mb-3">
          You're all set, <%= if @organization, do: @organization.name, else: "Team" %>!
        </h1>
        <p class="text-lg text-slate-500 dark:text-slate-400 max-w-xl mx-auto">
          Your workspace is configured and ready. Start managing your field operations like a pro.
        </p>
      </div>

      <!-- Quick Start Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-white dark:bg-slate-800/50 rounded-2xl border border-slate-200 dark:border-slate-700 p-6 text-center group hover:border-fsm-primary/50 hover:shadow-lg transition-all">
          <div class="size-12 bg-blue-500/10 rounded-xl flex items-center justify-center mx-auto mb-4 group-hover:bg-blue-500 group-hover:text-white transition-all">
            <span class="material-symbols-outlined notranslate text-blue-500 text-2xl group-hover:text-white">group_add</span>
          </div>
          <h3 class="font-bold text-slate-900 dark:text-white mb-1">Invite Team</h3>
          <p class="text-sm text-slate-500 dark:text-slate-400">Add technicians and staff</p>
        </div>
        <div class="bg-white dark:bg-slate-800/50 rounded-2xl border border-slate-200 dark:border-slate-700 p-6 text-center group hover:border-fsm-primary/50 hover:shadow-lg transition-all">
          <div class="size-12 bg-purple-500/10 rounded-xl flex items-center justify-center mx-auto mb-4 group-hover:bg-purple-500 group-hover:text-white transition-all">
            <span class="material-symbols-outlined notranslate text-purple-500 text-2xl group-hover:text-white">person_add</span>
          </div>
          <h3 class="font-bold text-slate-900 dark:text-white mb-1">Add Customers</h3>
          <p class="text-sm text-slate-500 dark:text-slate-400">Import your client base</p>
        </div>
        <div class="bg-white dark:bg-slate-800/50 rounded-2xl border border-slate-200 dark:border-slate-700 p-6 text-center group hover:border-fsm-primary/50 hover:shadow-lg transition-all">
          <div class="size-12 bg-amber-500/10 rounded-xl flex items-center justify-center mx-auto mb-4 group-hover:bg-amber-500 group-hover:text-white transition-all">
            <span class="material-symbols-outlined notranslate text-amber-500 text-2xl group-hover:text-white">add_task</span>
          </div>
          <h3 class="font-bold text-slate-900 dark:text-white mb-1">Create Job</h3>
          <p class="text-sm text-slate-500 dark:text-slate-400">Schedule your first job</p>
        </div>
      </div>

      <!-- Launch Button -->
      <div class="pt-8 flex justify-center">
        <button
          type="button"
          phx-click="finish_onboarding"
          class="group flex items-center gap-3 bg-gradient-to-r from-fsm-primary to-blue-600 text-white px-12 py-5 rounded-2xl font-bold text-lg shadow-2xl shadow-fsm-primary/30 hover:shadow-fsm-primary/50 hover:scale-[1.02] transition-all"
        >
          Launch Dashboard
          <span class="material-symbols-outlined notranslate text-2xl group-hover:translate-x-1 transition-transform">arrow_forward</span>
        </button>
      </div>
    </div>
    """
  end
end
