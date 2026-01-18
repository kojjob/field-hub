defmodule FieldHubWeb.OnboardingLive do
  @moduledoc """
  LiveView for organization onboarding wizard.
  Beautiful multi-step onboarding with primary theme.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Accounts.Organization
  alias FieldHub.Config.IndustryTemplates

  @impl true
  def mount(_params, _session, socket) do
    user = Accounts.get_user!(socket.assigns.current_scope.user.id)

    organization =
      if user.organization_id, do: Accounts.get_organization!(user.organization_id), else: nil

    cond do
      is_nil(organization) ->
        # Create a blank organization for the form
        changeset = Organization.changeset(%Organization{}, %{})
        form = to_form(changeset, as: "organization")

        {:ok,
         assign(socket,
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
    case socket.assigns.step do
      1 ->
        # Step 1 -> 2: Create organization with selected industry
        user = Accounts.get_user!(socket.assigns.current_scope.user.id)
        industry = socket.assigns.selected_industry

        template =
          Enum.find(socket.assigns.industries, fn t -> to_string(t.key) == industry end) || %{}

        # Generate a unique org name and slug from user's email
        base_name = user.email |> String.split("@") |> List.first() |> String.capitalize()
        org_name = "#{base_name}'s Organization"

        org_slug =
          Organization.generate_slug(org_name) <> "-#{System.unique_integer([:positive])}"

        org_attrs = %{
          name: org_name,
          slug: org_slug,
          industry: industry,
          terminology: Map.get(template, :terminology, %{})
        }

        case Accounts.create_organization_with_owner(org_attrs, user) do
          {:ok, %{organization: organization}} ->
            changeset = Organization.changeset(organization, %{})
            form = to_form(changeset, as: "organization")

            {:noreply,
             socket
             |> assign(:organization, organization)
             |> assign(:form, form)
             |> assign(:step, 2)}

          {:error, _failed_operation, _changeset, _changes} ->
            {:noreply,
             put_flash(socket, :error, "Could not create organization. Please try again.")}
        end

      _ ->
        {:noreply, assign(socket, :step, socket.assigns.step + 1)}
    end
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
    case Accounts.update_organization(socket.assigns.organization, %{
           onboarding_completed_at: DateTime.utc_now()
         }) do
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
    <div class="max-w-4xl mx-auto py-10 px-4 sm:px-6 lg:px-8 font-dashboard">
      <!-- Steps Navigation (Horizontal) -->
      <nav aria-label="Progress" class="mb-12">
        <ol role="list" class="flex items-center justify-between gap-4">
          <li :for={step <- 1..4} class="flex-1">
            <div class={[
              "h-1.5 rounded-full transition-all duration-700",
              @step >= step && "bg-primary shadow-[0_0_10px_rgba(16,185,129,0.3)]",
              @step < step && "bg-zinc-200 dark:bg-zinc-800"
            ]} />
            <div class="mt-4 flex flex-col items-center sm:items-start">
              <span class={[
                "text-[10px] font-black uppercase tracking-[0.15em]",
                @step >= step && "text-primary dark:text-primary",
                @step < step && "text-zinc-500"
              ]}>
                Step 0{step}
              </span>
              <span class={[
                "text-xs font-bold mt-1 hidden sm:block",
                @step == step && "text-zinc-900 dark:text-zinc-100",
                @step != step && "text-zinc-500"
              ]}>
                <%= case step do %>
                  <% 1 -> %>
                    Industry
                  <% 2 -> %>
                    Details
                  <% 3 -> %>
                    Branding
                  <% 4 -> %>
                    Launch
                <% end %>
              </span>
            </div>
          </li>
        </ol>
      </nav>

      <div class="bg-white dark:bg-zinc-900 rounded-[2.5rem] shadow-2xl shadow-zinc-200/50 dark:shadow-none border border-zinc-100 dark:border-zinc-800 overflow-hidden">
        <div class="p-8 lg:p-12">
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
      </div>
    </div>
    """
  end

  # Step 1: Industry Selection
  defp step_1_industry(assigns) do
    ~H"""
    <div class="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div class="text-center mb-10">
        <div class="inline-flex items-center gap-2 bg-primary/10 dark:bg-primary/20 text-primary dark:text-primary px-4 py-2 rounded-full text-[10px] font-black uppercase tracking-widest mb-4">
          <.icon name="hero-sparkles" class="size-4" /> Getting Started
        </div>
        <h1 class="text-4xl lg:text-5xl font-black text-zinc-900 dark:text-white tracking-tight mb-3">
          What's your industry?
        </h1>
        <p class="text-lg text-zinc-500 dark:text-zinc-400 max-w-xl mx-auto font-medium">
          We'll customize terminology and workflows to match your business perfectly.
        </p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <%= for template <- @industries do %>
          <button
            type="button"
            phx-click="select_industry"
            phx-value-template={template.key}
            class={"group relative p-6 rounded-3xl border-2 transition-all text-left #{if @selected == to_string(template.key), do: "border-primary bg-primary/5 dark:bg-primary/10 shadow-xl shadow-primary/10", else: "border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-900/50 hover:border-primary/50 hover:bg-white dark:hover:bg-zinc-800/80"}"}
          >
            <div class="flex items-start gap-4">
              <div class={"size-14 rounded-2xl flex items-center justify-center flex-shrink-0 transition-all shadow-sm #{if @selected == to_string(template.key), do: "bg-primary text-white shadow-primary/20", else: "bg-white dark:bg-zinc-800 text-zinc-500 group-hover:bg-primary group-hover:text-white"}"}>
                <.icon name={template.icon} class="size-7 text-inherit" />
              </div>
              <div class="flex-1">
                <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-1 tracking-tight">
                  {template.name}
                </h3>
                <p class="text-sm text-zinc-500 dark:text-zinc-400 font-medium leading-relaxed">
                  {template.description}
                </p>
              </div>
              <%= if @selected == to_string(template.key) do %>
                <div class="absolute top-4 right-4 size-6 bg-primary rounded-full flex items-center justify-center text-white">
                  <.icon name="hero-check" class="size-4 stroke-[3]" />
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
          class={"group flex items-center gap-2 px-8 py-4 rounded-2xl font-bold text-base transition-all active:scale-[0.98] #{if @selected, do: "bg-primary text-white shadow-xl shadow-primary/20 hover:bg-primary/90", else: "bg-zinc-100 dark:bg-zinc-800 text-zinc-400 cursor-not-allowed"}"}
        >
          Continue
          <.icon
            name="hero-arrow-right"
            class="size-5 group-hover:translate-x-1 transition-transform"
          />
        </button>
      </div>
    </div>
    """
  end

  # Step 2: Company Details
  defp step_2_details(assigns) do
    ~H"""
    <div class="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div class="mb-10 text-center lg:text-left">
        <div class="inline-flex items-center gap-2 bg-primary/10 dark:bg-primary/20 text-primary dark:text-primary px-4 py-2 rounded-full text-[10px] font-black uppercase tracking-widest mb-4">
          <.icon name="hero-building-office-2" class="size-4" /> Company Profile
        </div>
        <h1 class="text-4xl lg:text-5xl font-black text-zinc-900 dark:text-white tracking-tight mb-3">
          Tell us about your company
        </h1>
        <p class="text-lg text-zinc-500 dark:text-zinc-400 font-medium">
          This information helps us personalize your experience.
        </p>
      </div>

      <.form
        for={@form}
        id="onboarding-form"
        phx-change="validate"
        phx-submit="save_details"
        class="space-y-8"
      >
        <!-- Basic Info Section -->
        <div class="bg-zinc-50/50 dark:bg-zinc-800/30 rounded-3xl border border-zinc-100 dark:border-zinc-800 p-8 space-y-8">
          <div class="flex items-center gap-4">
            <div class="size-10 bg-primary text-white rounded-xl flex items-center justify-center shadow-lg shadow-primary/20">
              <.icon name="hero-identification" class="size-6" />
            </div>
            <div>
              <h3 class="text-xl font-bold text-zinc-900 dark:text-white tracking-tight">
                Basic Information
              </h3>
              <p class="text-sm text-zinc-500 font-medium tracking-tight">
                Public details for your organization
              </p>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                Organization Name *
              </label>
              <.input
                field={@form[:name]}
                type="text"
                placeholder="ACME Field Services"
                class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                Contact Email
              </label>
              <.input
                field={@form[:email]}
                type="email"
                placeholder="contact@company.com"
                class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                Phone Number
              </label>
              <.input
                field={@form[:phone]}
                type="tel"
                placeholder="+1 (555) 123-4567"
                class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                Website
              </label>
              <.input
                field={@form[:website]}
                type="url"
                placeholder="https://www.company.com"
                class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
              />
            </div>
          </div>
        </div>

    <!-- Address Section -->
        <div class="bg-zinc-50/50 dark:bg-zinc-800/30 rounded-3xl border border-zinc-100 dark:border-zinc-800 p-8 space-y-8">
          <div class="flex items-center gap-4">
            <div class="size-10 bg-primary text-white rounded-xl flex items-center justify-center shadow-lg shadow-primary/20">
              <.icon name="hero-map-pin" class="size-6" />
            </div>
            <div>
              <h3 class="text-xl font-bold text-zinc-900 dark:text-white tracking-tight">
                Business Address
              </h3>
              <p class="text-sm text-zinc-500 font-medium tracking-tight">
                Physical location of your HQ
              </p>
            </div>
          </div>

          <div class="space-y-6">
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                Street Address
              </label>
              <.input
                field={@form[:address]}
                type="text"
                placeholder="123 Business Street, Suite 100"
                class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
              />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div class="space-y-2">
                <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                  City / Town
                </label>
                <.input
                  field={@form[:city]}
                  type="text"
                  placeholder="San Francisco"
                  class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
                />
              </div>
              <div class="space-y-2">
                <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                  State / Province
                </label>
                <.input
                  field={@form[:state]}
                  type="text"
                  placeholder="California"
                  class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
                />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div class="space-y-2">
                <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                  Postal / ZIP Code
                </label>
                <.input
                  field={@form[:postal_code]}
                  type="text"
                  placeholder="94103"
                  class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
                />
              </div>
              <div class="space-y-2">
                <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                  Country
                </label>
                <.input
                  field={@form[:country]}
                  type="text"
                  placeholder="United States"
                  class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
                />
              </div>
            </div>
          </div>
        </div>

    <!-- Navigation Buttons -->
        <div class="pt-6 flex justify-between items-center">
          <button
            type="button"
            phx-click="back"
            class="group flex items-center gap-2 px-6 py-3 text-zinc-500 hover:text-zinc-900 dark:hover:text-white font-bold transition-all"
          >
            <.icon
              name="hero-arrow-left"
              class="size-5 group-hover:-translate-x-1 transition-transform"
            /> Back
          </button>
          <.button
            type="submit"
            class="group flex items-center gap-2 !bg-primary !text-white !px-8 !py-4 !rounded-2xl !font-bold !text-base shadow-xl shadow-primary/20 hover:bg-primary/90 transition-all active:scale-[0.98]"
          >
            Continue to Branding
            <.icon
              name="hero-arrow-right"
              class="size-5 group-hover:translate-x-1 transition-transform"
            />
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
      <div class="mb-10 text-center lg:text-left">
        <div class="inline-flex items-center gap-2 bg-primary/10 dark:bg-primary/20 text-primary dark:text-primary px-4 py-2 rounded-full text-[10px] font-black uppercase tracking-widest mb-4">
          <.icon name="hero-swatch" class="size-4" /> Brand Identity
        </div>
        <h1 class="text-4xl lg:text-5xl font-black text-zinc-900 dark:text-white tracking-tight mb-3">
          Make it yours
        </h1>
        <p class="text-lg text-zinc-500 dark:text-zinc-400 font-medium">
          Customize colors and branding to match your company identity.
        </p>
      </div>

      <.form
        for={@form}
        id="branding-form"
        phx-change="validate"
        phx-submit="save_branding"
        class="space-y-8"
      >
        <div class="bg-zinc-50/50 dark:bg-zinc-800/30 rounded-3xl border border-zinc-100 dark:border-zinc-800 p-8">
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-12">
            <!-- Color Settings -->
            <div class="space-y-8">
              <div class="flex items-center gap-4">
                <div class="size-10 bg-primary text-white rounded-xl flex items-center justify-center shadow-lg shadow-primary/20">
                  <.icon name="hero-paint-brush" class="size-6" />
                </div>
                <div>
                  <h3 class="text-xl font-bold text-zinc-900 dark:text-white tracking-tight">
                    Brand Colors
                  </h3>
                  <p class="text-sm text-zinc-500 font-medium tracking-tight">
                    Set your primary visual tokens
                  </p>
                </div>
              </div>

              <div class="space-y-6">
                <div class="space-y-2">
                  <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                    Primary Color
                  </label>
                  <div class="flex items-center gap-4">
                    <.input
                      field={@form[:primary_color]}
                      type="color"
                      value="#10B981"
                      class="!h-14 !w-24 !p-1.5 !rounded-2xl !border-2 !border-zinc-100 dark:!border-zinc-800 cursor-pointer shadow-sm shadow-zinc-200/50 dark:shadow-none bg-white dark:bg-zinc-900"
                    />
                    <span class="text-sm font-mono font-bold text-zinc-400 bg-zinc-100 dark:bg-zinc-800 px-3 py-1.5 rounded-lg">
                      #10B981
                    </span>
                  </div>
                </div>
                <div class="space-y-2">
                  <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                    Secondary Color
                  </label>
                  <div class="flex items-center gap-4">
                    <.input
                      field={@form[:secondary_color]}
                      type="color"
                      value="#0F172A"
                      class="!h-14 !w-24 !p-1.5 !rounded-2xl !border-2 !border-zinc-100 dark:!border-zinc-800 cursor-pointer shadow-sm shadow-zinc-200/50 dark:shadow-none bg-white dark:bg-zinc-900"
                    />
                    <span class="text-sm font-mono font-bold text-zinc-400 bg-zinc-100 dark:bg-zinc-800 px-3 py-1.5 rounded-lg">
                      #0F172A
                    </span>
                  </div>
                </div>
              </div>

              <div class="space-y-2 pt-4">
                <label class="text-xs font-bold text-zinc-400 uppercase tracking-widest ml-1">
                  Brand Name (Display)
                </label>
                <.input
                  field={@form[:brand_name]}
                  type="text"
                  placeholder="Your Brand Name"
                  class="!bg-white dark:!bg-zinc-900 !border-zinc-100 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 font-semibold"
                />
                <p class="text-[10px] text-zinc-400 font-bold uppercase tracking-wider ml-1">
                  Used for customer communication
                </p>
              </div>
            </div>

    <!-- Live Preview -->
            <div class="space-y-6">
              <div class="flex items-center gap-4 mb-4">
                <div class="size-10 bg-primary text-white rounded-xl flex items-center justify-center shadow-lg shadow-primary/20">
                  <.icon name="hero-eye" class="size-6" />
                </div>
                <div>
                  <h3 class="text-xl font-bold text-zinc-900 dark:text-white tracking-tight">
                    Live Preview
                  </h3>
                  <p class="text-sm text-zinc-500 font-medium tracking-tight">
                    Real-time preview of your brand
                  </p>
                </div>
              </div>

              <div class="bg-zinc-100 dark:bg-zinc-800/50 rounded-3xl p-8 border border-zinc-100/50 dark:border-zinc-800/50">
                <div class="bg-white dark:bg-zinc-900 rounded-2xl shadow-2xl shadow-zinc-900/10 dark:shadow-none overflow-hidden border border-zinc-100 dark:border-zinc-800">
                  <div class="h-4 bg-primary"></div>
                  <div class="p-6">
                    <div class="flex items-center gap-3 mb-6">
                      <div class="size-10 bg-primary rounded-xl shadow-lg shadow-primary/20">
                      </div>
                      <div class="h-4 w-32 bg-zinc-200 dark:bg-zinc-700 rounded-full"></div>
                    </div>
                    <div class="space-y-3">
                      <div class="h-3 w-full bg-zinc-100 dark:bg-zinc-800 rounded-full"></div>
                      <div class="h-3 w-5/6 bg-zinc-100 dark:bg-zinc-800 rounded-full"></div>
                      <div class="h-3 w-4/6 bg-zinc-100 dark:bg-zinc-800 rounded-full"></div>
                    </div>
                    <div class="mt-8 flex justify-end">
                      <div class="px-6 py-2.5 bg-primary text-white text-xs font-black uppercase tracking-widest rounded-xl shadow-lg shadow-primary/20">
                        Primary Button
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

    <!-- Navigation -->
        <div class="pt-6 flex justify-between items-center">
          <button
            type="button"
            phx-click="back"
            class="group flex items-center gap-2 px-6 py-3 text-zinc-500 hover:text-zinc-900 dark:hover:text-white font-bold transition-all"
          >
            <.icon
              name="hero-arrow-left"
              class="size-5 group-hover:-translate-x-1 transition-transform"
            /> Back
          </button>
          <.button
            type="submit"
            class="group flex items-center gap-2 !bg-primary !text-white !px-8 !py-4 !rounded-2xl !font-bold !text-base shadow-xl shadow-primary/20 hover:bg-primary/90 transition-all active:scale-[0.98]"
          >
            Almost Done!
            <.icon
              name="hero-arrow-right"
              class="size-5 group-hover:translate-x-1 transition-transform"
            />
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  # Step 4: Launch
  defp step_4_launch(assigns) do
    ~H"""
    <div class="space-y-12 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div class="text-center py-8">
        <div class="relative inline-block mb-10">
          <div class="absolute inset-0 bg-primary/30 rounded-full blur-3xl animate-pulse"></div>
          <div class="relative size-32 bg-gradient-to-br from-primary to-emerald-600 rounded-full flex items-center justify-center shadow-2xl shadow-primary/30">
            <.icon name="hero-rocket-launch" class="size-16 text-white" />
          </div>
        </div>

        <div class="inline-flex items-center gap-2 bg-primary/10 dark:bg-primary/30 text-primary dark:text-primary px-5 py-2.5 rounded-full text-[10px] font-black uppercase tracking-[0.2em] mb-6">
          <.icon name="hero-sparkles" class="size-4" /> Setup Complete
        </div>

        <h1 class="text-4xl lg:text-5xl font-black text-zinc-900 dark:text-white tracking-tight mb-4">
          You're all set, {if @organization, do: @organization.name, else: "Team"}!
        </h1>
        <p class="text-xl text-zinc-500 dark:text-zinc-400 max-w-xl mx-auto font-medium leading-relaxed">
          Your workspace is configured and ready. Start managing your field operations like a pro.
        </p>
      </div>

    <!-- Quick Start Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white dark:bg-zinc-800/30 rounded-[2rem] border border-zinc-100 dark:border-zinc-800 p-8 text-center group hover:border-primary/50 hover:bg-primary/10 transition-all shadow-sm">
          <div class="size-14 bg-primary/10 dark:bg-primary/20 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:bg-primary group-hover:text-white transition-all text-primary dark:text-primary shadow-sm">
            <.icon name="hero-user-group" class="size-7" />
          </div>
          <h3 class="font-bold text-zinc-900 dark:text-white mb-2 tracking-tight">Invite Team</h3>
          <p class="text-sm text-zinc-500 dark:text-zinc-400 font-medium leading-relaxed">
            Add technicians and admin staff
          </p>
        </div>
        <div class="bg-white dark:bg-zinc-800/30 rounded-[2rem] border border-zinc-100 dark:border-zinc-800 p-8 text-center group hover:border-emerald-500/50 hover:bg-emerald-50/10 transition-all shadow-sm">
          <div class="size-14 bg-emerald-50 dark:bg-emerald-900/20 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:bg-emerald-600 group-hover:text-white transition-all text-emerald-600 dark:text-emerald-400 shadow-sm">
            <.icon name="hero-user-plus" class="size-7" />
          </div>
          <h3 class="font-bold text-zinc-900 dark:text-white mb-2 tracking-tight">Add Customers</h3>
          <p class="text-sm text-zinc-500 dark:text-zinc-400 font-medium leading-relaxed">
            Import your existing client base
          </p>
        </div>
        <div class="bg-white dark:bg-zinc-800/30 rounded-[2rem] border border-zinc-100 dark:border-zinc-800 p-8 text-center group hover:border-amber-500/50 hover:bg-amber-50/10 transition-all shadow-sm">
          <div class="size-14 bg-amber-50 dark:bg-amber-900/20 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:bg-amber-600 group-hover:text-white transition-all text-amber-600 dark:text-amber-400 shadow-sm">
            <.icon name="hero-calendar" class="size-7" />
          </div>
          <h3 class="font-bold text-zinc-900 dark:text-white mb-2 tracking-tight">Create Job</h3>
          <p class="text-sm text-zinc-500 dark:text-zinc-400 font-medium leading-relaxed">
            Schedule your first service call
          </p>
        </div>
      </div>

      <div class="pt-8 flex justify-center">
        <button
          type="button"
          phx-click="finish_onboarding"
          class="group flex items-center gap-3 bg-primary text-white px-12 py-5 rounded-2xl font-black text-lg shadow-2xl shadow-primary/30 hover:bg-primary/90 hover:scale-[1.02] transition-all active:scale-[0.98]"
        >
          Launch Dashboard
          <.icon
            name="hero-rocket-launch"
            class="size-6 text-white group-hover:translate-x-1 group-hover:-translate-y-1 transition-transform"
          />
        </button>
      </div>
    </div>
    """
  end
end
