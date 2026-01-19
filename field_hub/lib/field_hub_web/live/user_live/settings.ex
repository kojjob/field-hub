defmodule FieldHubWeb.UserLive.Settings do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  # Mock sessions for UI demonstration since we don't track devices yet
  @mock_sessions [
    %{id: "s1", device: "Chrome on MacOS (14.2.1)", ip: "192.168.1.1", location: "London, UK", active: true, last_active: "Active now", icon: "hero-computer-desktop"},
    %{id: "s2", device: "FieldHub App on iPhone 15 Pro", ip: "172.16.2.45", location: "Manchester, UK", active: false, last_active: "2 hours ago", icon: "hero-device-phone-mobile"},
    %{id: "s3", device: "Android Tablet - Dispatch Panel", ip: "10.0.0.89", location: "Liverpool, UK", active: false, last_active: "3 days ago", icon: "hero-device-tablet"}
  ]

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, user} ->
          put_flash(socket, :info, "Email changed successfully.")
          |> assign(current_scope: %{socket.assigns.current_scope | user: user})

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_changeset = Accounts.change_user_profile(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:sessions, @mock_sessions)
      |> assign(:current_nav, :user_settings)
      |> assign(:current_tab, :profile)
      |> assign(:page_title, "Settings")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_tab = case params["tab"] do
      "security" -> :security
      "notifications" -> :notifications
      "billing" -> :billing
      "team" -> :team
      _ -> :profile
    end

    {:noreply, assign(socket, :current_tab, current_tab)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[1600px] mx-auto">
      <!-- Header -->
      <div class="mb-8">
        <nav class="flex items-center text-sm text-zinc-500 dark:text-zinc-400 mb-2">
          <span>Settings</span>
          <.icon name="hero-chevron-right" class="w-4 h-4 mx-2" />
          <span class="text-zinc-900 dark:text-zinc-100 font-medium">User Profile</span>
        </nav>
        <h1 class="text-3xl font-bold text-zinc-900 dark:text-white tracking-tight">Profile Settings</h1>
        <p class="text-zinc-500 dark:text-zinc-400 mt-1">Manage your personal presence and account safety across the FieldHub platform.</p>
      </div>

      <div class="flex flex-col lg:flex-row gap-8">
        <!-- Settings Sidebar -->
        <aside class="w-full lg:w-64 flex-shrink-0 space-y-1">
          <.link patch={~p"/users/settings?tab=profile"} class={if @current_tab == :profile, do: "flex items-center gap-3 px-4 py-2.5 bg-primary text-white rounded-xl font-medium shadow-sm transition-all", else: "flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all"}>
            <.icon name="hero-user" class="w-5 h-5" />
            Profile
          </.link>
          <.link patch={~p"/users/settings?tab=security"} class={if @current_tab == :security, do: "flex items-center gap-3 px-4 py-2.5 bg-primary text-white rounded-xl font-medium shadow-sm transition-all", else: "flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all"}>
            <.icon name="hero-shield-check" class="w-5 h-5" />
            Security
          </.link>
          <a href="#" class="flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all opacity-50 cursor-not-allowed">
            <.icon name="hero-bell" class="w-5 h-5" />
            Notifications
            <span class="ml-auto text-[10px] bg-zinc-100 dark:bg-zinc-800 px-1.5 py-0.5 rounded text-zinc-500">Soon</span>
          </a>
          <a href="#" class="flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all opacity-50 cursor-not-allowed">
            <.icon name="hero-credit-card" class="w-5 h-5" />
            Billing & Plan
             <span class="ml-auto text-[10px] bg-zinc-100 dark:bg-zinc-800 px-1.5 py-0.5 rounded text-zinc-500">Soon</span>
          </a>
          <a href="#" class="flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all opacity-50 cursor-not-allowed">
            <.icon name="hero-users" class="w-5 h-5" />
            Team Management
             <span class="ml-auto text-[10px] bg-zinc-100 dark:bg-zinc-800 px-1.5 py-0.5 rounded text-zinc-500">Soon</span>
          </a>
        </aside>

        <!-- Main Content Area -->
        <div class="flex-1 space-y-8">
          <%= if @current_tab == :profile do %>
            <!-- Avatar Section -->
            <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm transition-all duration-200 hover:shadow-md">
              <div class="flex items-start sm:items-center gap-6 flex-col sm:flex-row">
                <div class="relative group">
                  <div class="size-24 rounded-full bg-orange-100 dark:bg-orange-900/30 text-orange-600 dark:text-orange-400 flex items-center justify-center text-3xl font-bold ring-4 ring-white dark:ring-zinc-900 border border-orange-200 dark:border-orange-800/50">
                    <%= String.first(@current_scope.user.name || @current_scope.user.email) |> String.upcase() %>
                  </div>
                  <div class="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer">
                    <.icon name="hero-camera" class="w-8 h-8 text-white" />
                  </div>
                </div>
                <div class="flex-1">
                  <h3 class="text-lg font-bold text-zinc-900 dark:text-white">Your Avatar</h3>
                  <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">Accepted formats: JPG, PNG, WEBP.<br/>Minimum dimension 400x400px. Max size 2MB.</p>
                  <div class="mt-4 flex gap-3">
                    <button class="bg-primary hover:bg-primary/90 text-white px-4 py-2 rounded-lg text-sm font-semibold transition-colors flex items-center gap-2 shadow-sm shadow-primary/20">
                       <.icon name="hero-arrow-up-tray" class="w-4 h-4" />
                       Upload New Photo
                    </button>
                    <button class="bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-700 text-zinc-700 dark:text-zinc-300 border border-zinc-200 dark:border-zinc-700 px-4 py-2 rounded-lg text-sm font-semibold transition-colors">
                      Remove
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- ID/Personal Info Section -->
            <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden transition-all duration-200 hover:shadow-md">
               <div class="absolute top-8 right-8">
                <span class="inline-flex items-center rounded-md bg-teal-50 dark:bg-teal-900/30 px-2.5 py-1 text-xs font-bold text-teal-700 dark:text-teal-400 ring-1 ring-inset ring-teal-600/20 uppercase tracking-widest">
                  Identity
                </span>
              </div>

              <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-6">Personal Information</h3>

              <.form for={@profile_form} id="profile_form" phx-change="validate_profile" phx-submit="update_profile" class="space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <.input field={@profile_form[:name]} label="Full Name" placeholder="John Doe" class="bg-zinc-50 dark:bg-zinc-800/50" />
                  </div>
                  <!-- Placeholder for visual balance -->
                   <div class="hidden md:block"></div>
                </div>

                <div class="relative group">
                   <.input field={@profile_form[:email_view_only]} name="email_view_only" value={@current_email} label="Email Address" disabled class="bg-zinc-50 dark:bg-zinc-800/50 text-zinc-500" />
                   <div class="absolute right-0 top-9">
                      <span class="inline-flex items-center rounded-md bg-green-50 dark:bg-green-900/30 px-2 py-1 text-xs font-medium text-green-700 dark:text-green-400 ring-1 ring-inset ring-green-600/20 uppercase">
                        Verified
                      </span>
                   </div>
                   <p class="mt-2 text-xs text-zinc-500">To change your email, please use the Security tab.</p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <.input field={@profile_form[:phone]} label="Phone Number" placeholder="+1 (555) 000-1234" class="bg-zinc-50 dark:bg-zinc-800/50" />
                  </div>
                  <div>
                    <label class="block text-sm font-semibold leading-6 text-zinc-900 dark:text-zinc-100">Language / Locale</label>
                    <select class="mt-2 block w-full rounded-2xl border-0 py-2.5 pl-3 pr-10 text-zinc-900 dark:text-zinc-100 ring-1 ring-inset ring-zinc-300 dark:ring-zinc-700 focus:ring-2 focus:ring-primary sm:text-sm sm:leading-6 bg-zinc-50 dark:bg-zinc-800/50">
                      <option>English (US)</option>
                      <option>English (UK)</option>
                      <option>Spanish</option>
                      <option>French</option>
                    </select>
                  </div>
                </div>

                <div class="flex justify-end pt-4 border-t border-zinc-100 dark:border-zinc-800 mt-6">
                  <.button variant="primary" phx-disable-with="Saving...">Save Changes</.button>
                </div>
              </.form>
            </div>
          <% end %>

          <%= if @current_tab == :security do %>
             <!-- Active Sessions -->
            <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm">
              <h3 class="text-lg font-bold text-zinc-900 dark:text-white">Security & Active Sessions</h3>
              <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1 mb-6">Manage devices currently logged into your account.</p>

              <div class="space-y-4">
                <%= for session <- @sessions do %>
                  <div class="flex items-center justify-between p-4 rounded-xl border border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20 hover:border-zinc-200 dark:hover:border-zinc-700 transition-colors">
                    <div class="flex items-center gap-4">
                      <div class="size-10 rounded-lg bg-zinc-200 dark:bg-zinc-700 flex items-center justify-center text-zinc-500 dark:text-zinc-400">
                        <.icon name={session.icon} class="w-6 h-6" />
                      </div>
                      <div>
                        <div class="flex items-center gap-2">
                          <span class="font-semibold text-zinc-900 dark:text-zinc-100">{session.device}</span>
                           <%= if session.active do %>
                            <span class="px-1.5 py-0.5 rounded bg-teal-100 dark:bg-teal-900 text-[10px] font-bold text-teal-700 dark:text-teal-300 uppercase tracking-wide">Current</span>
                           <% end %>
                        </div>
                        <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-0.5">
                          {session.ip} • {session.location} • {session.last_active}
                        </p>
                      </div>
                    </div>
                    <div>
                      <%= unless session.active do %>
                        <button class="text-sm font-semibold text-red-600 hover:text-red-700 transition-colors hover:underline">Revoke Access</button>
                      <% else %>
                         <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5 text-zinc-400" />
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Danger Zone -->
            <div class="rounded-2xl p-6 bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/20 flex items-center justify-between">
              <div>
                <h4 class="text-red-800 dark:text-red-300 font-bold flex items-center gap-2">
                   <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
                   Think your account is compromised?
                </h4>
                <p class="text-red-600 dark:text-red-400 text-sm mt-1">Sign out from all sessions to secure your account immediately.</p>
              </div>
              <button class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg text-sm font-bold shadow-sm shadow-red-500/20 transition-colors">
                Sign Out All Sessions
              </button>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
              <!-- Change Password -->
              <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm">
                  <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-6 flex items-center gap-2">
                     <.icon name="hero-key" class="w-5 h-5 text-primary" />
                     Change Password
                  </h3>
                  <.form for={@password_form} id="password_form" action={~p"/users/update-password"} method="post" phx-change="validate_password" phx-submit="update_password" phx-trigger-action={@trigger_submit} class="space-y-4">
                      <input name={@password_form[:email].name} type="hidden" value={@current_email} />
                      <.input field={@password_form[:password]} type="password" label="New Password" required class="bg-zinc-50 dark:bg-zinc-800/50" />
                      <.input field={@password_form[:password_confirmation]} type="password" label="Confirm Password" required class="bg-zinc-50 dark:bg-zinc-800/50" />
                      <.button variant="primary" class="w-full">Update Password</.button>
                  </.form>
              </div>

              <!-- Change Email -->
              <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm">
                  <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-6 flex items-center gap-2">
                    <.icon name="hero-envelope" class="w-5 h-5 text-primary" />
                    Change Email
                  </h3>
                   <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email" class="space-y-4">
                      <.input field={@email_form[:email]} type="email" label="New Email Address" required class="bg-zinc-50 dark:bg-zinc-800/50" />
                      <.button variant="primary" class="w-full">Update Email</.button>
                  </.form>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user
    case Accounts.update_user_profile(user, user_params) do
      {:ok, user} ->
        info = "Profile updated successfully."
        # Update current scope with new user data
        current_scope = %{socket.assigns.current_scope | user: user}

        {:noreply,
         socket
         |> assign(current_scope: current_scope)
         |> put_flash(:info, info)
         |> assign(profile_form: to_form(Accounts.change_user_profile(user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset, action: :update))}
    end
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    if Accounts.sudo_mode?(user) do
      case Accounts.change_user_email(user, user_params) do
        %{valid?: true} = changeset ->
          Accounts.deliver_user_update_email_instructions(
            Ecto.Changeset.apply_action!(changeset, :insert),
            user.email,
            &url(~p"/users/settings/confirm-email/#{&1}")
          )

          info = "A link to confirm your email change has been sent to the new address."
          {:noreply, socket |> put_flash(:info, info)}

        changeset ->
          {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
      end
    else
      {:noreply, socket |> put_flash(:error, "You must log in to access this page.") |> redirect(to: ~p"/users/log-in")}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    if Accounts.sudo_mode?(user) do
      case Accounts.change_user_password(user, user_params) do
        %{valid?: true} = changeset ->
          {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

        changeset ->
          {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
      end
    else
      {:noreply, socket |> put_flash(:error, "You must log in to access this page.") |> redirect(to: ~p"/users/log-in")}
    end
  end
end
