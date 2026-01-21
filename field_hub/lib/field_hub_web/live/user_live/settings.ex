defmodule FieldHubWeb.UserLive.Settings do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  # Mock sessions for UI demonstration since we don't track devices yet
  @mock_sessions [
    %{
      id: "s1",
      device: "Chrome on MacOS (14.2.1)",
      ip: "192.168.1.1",
      location: "London, UK",
      active: true,
      last_active: "Active now",
      icon: "hero-computer-desktop"
    },
    %{
      id: "s2",
      device: "FieldHub App on iPhone 15 Pro",
      ip: "172.16.2.45",
      location: "Manchester, UK",
      active: false,
      last_active: "2 hours ago",
      icon: "hero-device-phone-mobile"
    },
    %{
      id: "s3",
      device: "Android Tablet - Dispatch Panel",
      ip: "10.0.0.89",
      location: "Liverpool, UK",
      active: false,
      last_active: "3 days ago",
      icon: "hero-device-tablet"
    }
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
    org = socket.assigns.current_organization
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_changeset = Accounts.change_user_profile(user)
    notification_form = to_form(Accounts.change_user_notifications(user))

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:notification_form, notification_form)
      |> assign(:trigger_submit, false)
      |> assign(:sessions, @mock_sessions)
      |> assign(:current_nav, :user_settings)
      |> assign(:current_tab, :profile)
      |> assign(:page_title, "Settings")
      |> assign(:org_users, if(org, do: Accounts.list_org_users(org), else: []))
      |> assign(:active_jobs_count, if(org, do: FieldHub.Jobs.count_active_jobs(org.id), else: 0))
      |> assign(
        :invitation_form,
        to_form(%{"email" => "", "name" => "", "role" => "viewer"}, as: "user")
      )
      |> assign(:show_invite_modal, false)
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 2_000_000,
        auto_upload: true
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_tab =
      case params["tab"] do
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
        <h1 class="text-3xl font-bold text-zinc-900 dark:text-white tracking-tight">
          Profile Settings
        </h1>
        <p class="text-zinc-500 dark:text-zinc-400 mt-1">
          Manage your personal presence and account safety across the FieldHub platform.
        </p>
      </div>

      <div class="flex flex-col lg:flex-row gap-8">
        <!-- Settings Sidebar -->
        <aside class="w-full lg:w-64 flex-shrink-0 space-y-1">
          <.link
            patch={~p"/users/settings?tab=profile"}
            class={
              if @current_tab == :profile,
                do:
                  "flex items-center gap-3 px-4 py-2.5 bg-primary text-white rounded-xl font-medium shadow-sm transition-all",
                else:
                  "flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all"
            }
          >
            <.icon name="hero-user" class="w-5 h-5" /> Profile
          </.link>
          <.link
            patch={~p"/users/settings?tab=security"}
            class={
              if @current_tab == :security,
                do:
                  "flex items-center gap-3 px-4 py-2.5 bg-primary text-white rounded-xl font-medium shadow-sm transition-all",
                else:
                  "flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all"
            }
          >
            <.icon name="hero-shield-check" class="w-5 h-5" /> Security
          </.link>
          <.link
            patch={~p"/users/settings?tab=notifications"}
            class={
              if @current_tab == :notifications,
                do:
                  "flex items-center gap-3 px-4 py-2.5 bg-primary text-white rounded-xl font-medium shadow-sm transition-all",
                else:
                  "flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all"
            }
          >
            <.icon name="hero-bell" class="w-5 h-5" /> Notifications
          </.link>
          <.link
            patch={~p"/users/settings?tab=billing"}
            class={
              if @current_tab == :billing,
                do:
                  "flex items-center gap-3 px-4 py-2.5 bg-primary text-white rounded-xl font-medium shadow-sm transition-all",
                else:
                  "flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all"
            }
          >
            <.icon name="hero-credit-card" class="w-5 h-5" /> Billing & Plan
          </.link>
          <.link
            patch={~p"/users/settings?tab=team"}
            class={
              if @current_tab == :team,
                do:
                  "flex items-center gap-3 px-4 py-2.5 bg-primary text-white rounded-xl font-medium shadow-sm transition-all",
                else:
                  "flex items-center gap-3 px-4 py-2.5 text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl font-medium transition-all"
            }
          >
            <.icon name="hero-users" class="w-5 h-5" /> Team Management
          </.link>
        </aside>

    <!-- Main Content Area -->
        <div class="flex-1 space-y-8">
          <%= if @current_tab == :profile do %>
            <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm transition-all duration-200 hover:shadow-md">
              <div class="flex items-center gap-3 mb-8">
                <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                  <.icon name="hero-user" class="text-primary size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Personal Information
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    Keep your profile details up to date
                  </p>
                </div>
              </div>

              <.form
                for={@profile_form}
                id="profile_form"
                phx-change="validate_profile"
                phx-submit="update_profile"
                class="space-y-6"
              >
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <.input field={@profile_form[:name]} type="text" label="Full name" />
                  <.input field={@profile_form[:phone]} type="tel" label="Phone" />
                </div>

                <div class="flex items-center justify-end gap-3 pt-2">
                  <.button id="profile-save" phx-disable-with="Saving..." class="px-6">
                    Save Changes
                  </.button>
                </div>
              </.form>
            </div>
          <% end %>

          <%= if @current_tab == :security do %>
            <div class="space-y-8">
              <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm transition-all duration-200 hover:shadow-md">
                <div class="flex items-center gap-3 mb-8">
                  <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                    <.icon name="hero-envelope" class="text-primary size-6" />
                  </div>
                  <div>
                    <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                      Email Address
                    </h3>
                    <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                      Change where you receive account emails
                    </p>
                  </div>
                </div>

                <.form
                  for={@email_form}
                  id="email_form"
                  phx-change="validate_email"
                  phx-submit="update_email"
                  class="space-y-6"
                >
                  <.input field={@email_form[:email]} type="email" label="New email" />

                  <div class="flex items-center justify-end gap-3 pt-2">
                    <.button id="email-save" phx-disable-with="Updating..." class="px-6">
                      Update Email
                    </.button>
                  </div>
                </.form>
              </div>

              <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm transition-all duration-200 hover:shadow-md">
                <div class="flex items-center gap-3 mb-8">
                  <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                    <.icon name="hero-key" class="text-primary size-6" />
                  </div>
                  <div>
                    <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                      Password
                    </h3>
                    <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                      Use a strong password to protect your account
                    </p>
                  </div>
                </div>

                <.form
                  for={@password_form}
                  id="password_form"
                  phx-change="validate_password"
                  phx-submit="update_password"
                  action={~p"/users/update-password"}
                  method="post"
                  phx-trigger-action={@trigger_submit}
                  class="space-y-6"
                >
                  <input type="hidden" name="user[email]" value={@current_email} />
                  <.input field={@password_form[:password]} type="password" label="New password" />
                  <.input
                    field={@password_form[:password_confirmation]}
                    type="password"
                    label="Confirm password"
                  />

                  <div class="flex items-center justify-end gap-3 pt-2">
                    <.button id="password-save" phx-disable-with="Updating..." class="px-6">
                      Update Password
                    </.button>
                  </div>
                </.form>
              </div>
            </div>
          <% end %>

          <%= if @current_tab == :notifications do %>
            <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm transition-all duration-200 hover:shadow-md">
              <div class="flex items-center gap-3 mb-8">
                <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                  <.icon name="hero-bell" class="text-primary size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Notification Preferences
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    Manage how you receive updates
                  </p>
                </div>
              </div>

              <.form
                for={@notification_form}
                id="notification_form"
                phx-change="update_notifications"
                class="space-y-8"
              >
                <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div class="space-y-4">
                    <h4 class="text-sm font-black text-zinc-900 dark:text-white uppercase tracking-wider">
                      Email Notifications
                    </h4>
                    <div class="space-y-4">
                      <div class="flex items-center justify-between p-4 rounded-xl border border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20">
                        <div>
                          <p class="font-bold text-zinc-900 dark:text-white">New Job Assignments</p>
                          <p class="text-xs text-zinc-500">
                            When you are assigned to a new field job.
                          </p>
                        </div>
                        <.input field={@notification_form[:notify_on_new_jobs]} type="checkbox" />
                      </div>

                      <div class="flex items-center justify-between p-4 rounded-xl border border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20">
                        <div>
                          <p class="font-bold text-zinc-900 dark:text-white">Job Progress Updates</p>
                          <p class="text-xs text-zinc-500">
                            When a job status changes or comments are added.
                          </p>
                        </div>
                        <.input field={@notification_form[:notify_on_job_updates]} type="checkbox" />
                      </div>

                      <div class="flex items-center justify-between p-4 rounded-xl border border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20">
                        <div>
                          <p class="font-bold text-zinc-900 dark:text-white">Marketing & News</p>
                          <p class="text-xs text-zinc-500">
                            Updates about new features and best practices.
                          </p>
                        </div>
                        <.input field={@notification_form[:notify_marketing]} type="checkbox" />
                      </div>
                    </div>
                  </div>

                  <div class="space-y-4">
                    <h4 class="text-sm font-black text-zinc-900 dark:text-white uppercase tracking-wider">
                      Push Notifications
                    </h4>
                    <div class="space-y-4 opacity-75">
                      <div class="flex items-center justify-between p-4 rounded-xl border border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20">
                        <div>
                          <p class="font-bold text-zinc-900 dark:text-white">In-App Notifications</p>
                          <p class="text-xs text-zinc-500">
                            Real-time alerts while using the platform.
                          </p>
                        </div>
                        <input type="checkbox" class="toggle toggle-primary" checked disabled />
                      </div>

                      <div class="p-4 rounded-xl border border-dashed border-zinc-200 dark:border-zinc-700 bg-zinc-50/10">
                        <p class="text-sm text-zinc-500 text-center">
                          Push notifications are enabled on your mobile devices natively.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </.form>
            </div>
          <% end %>

          <%= if @current_tab == :billing do %>
            <div class="space-y-8">
              <!-- Current Plan Card -->
              <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden group transition-all duration-200 hover:shadow-md">
                <div class="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full -mr-16 -mt-16 transition-all group-hover:bg-primary/10">
                </div>

                <div class="flex flex-col md:flex-row justify-between gap-8 relative z-10">
                  <div class="flex-1">
                    <div class="flex items-center gap-3 mb-4">
                      <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                        <.icon name="hero-credit-card" class="text-primary size-6" />
                      </div>
                      <div>
                        <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                          Current Subscription
                        </h3>
                        <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                          {Phoenix.Naming.humanize(@current_organization.subscription_tier)} Plan
                        </p>
                      </div>
                    </div>

                    <div class="space-y-6">
                      <div class="flex flex-wrap gap-4">
                        <div class="px-4 py-2 bg-zinc-50 dark:bg-zinc-800 rounded-xl border border-zinc-100 dark:border-zinc-700">
                          <p class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-1">
                            Status
                          </p>
                          <div class="flex items-center gap-2">
                            <div class="size-2 rounded-full bg-emerald-500 animate-pulse"></div>
                            <span class="text-sm font-bold text-zinc-700 dark:text-zinc-200 uppercase">
                              {@current_organization.subscription_status}
                            </span>
                          </div>
                        </div>

                        <div class="px-4 py-2 bg-zinc-50 dark:bg-zinc-800 rounded-xl border border-zinc-100 dark:border-zinc-700">
                          <p class="text-[10px] font-black text-zinc-400 uppercase tracking-widest mb-1">
                            Trial Ends
                          </p>
                          <p class="text-sm font-bold text-zinc-700 dark:text-zinc-200">
                            {format_date(@current_organization.trial_ends_at)}
                          </p>
                        </div>
                      </div>

                      <div class="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-4 border-t border-zinc-100 dark:border-zinc-800">
                        <div class="space-y-2 text-sm">
                          <div class="flex justify-between items-center text-zinc-500">
                            <span>Jobs (Active)</span>
                            <span class="font-bold text-zinc-900 dark:text-white">
                              {@active_jobs_count} / 50
                            </span>
                          </div>
                          <div class="h-1.5 w-full bg-zinc-100 dark:bg-zinc-800 rounded-full overflow-hidden">
                            <div
                              class="h-full bg-primary"
                              style={"width: #{min(@active_jobs_count / 50 * 100, 100)}%"}
                            >
                            </div>
                          </div>
                        </div>

                        <div class="space-y-2 text-sm">
                          <div class="flex justify-between items-center text-zinc-500">
                            <span>Team Members</span>
                            <span class="font-bold text-zinc-900 dark:text-white">
                              {length(@org_users)} / 10
                            </span>
                          </div>
                          <div class="h-1.5 w-full bg-zinc-100 dark:bg-zinc-800 rounded-full overflow-hidden">
                            <div
                              class="h-full bg-primary"
                              style={"width: #{min(length(@org_users) / 10 * 100, 100)}%"}
                            >
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="w-full md:w-64 space-y-3">
                    <button class="w-full h-12 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1">
                      Upgrade to Pro
                    </button>
                    <button class="w-full h-12 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-700 dark:text-zinc-300 rounded-xl font-bold text-sm hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all">
                      Manage via Stripe
                    </button>
                  </div>
                </div>
              </div>

    <!-- Billing History -->
              <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
                <div class="p-6 border-b border-zinc-100 dark:border-zinc-800 flex items-center justify-between">
                  <h3 class="font-black text-zinc-900 dark:text-white tracking-tight">
                    Billing History
                  </h3>
                  <button class="text-xs font-black text-primary uppercase tracking-widest hover:underline">
                    Download All
                  </button>
                </div>
                <div class="overflow-x-auto">
                  <table class="w-full text-left text-sm">
                    <thead class="bg-zinc-50 dark:bg-zinc-800/50 text-[10px] font-black uppercase text-zinc-500 dark:text-zinc-400 tracking-[0.1em]">
                      <tr>
                        <th class="px-6 py-4">Invoice</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4">Amount</th>
                        <th class="px-6 py-4">Date</th>
                        <th class="px-6 py-4 text-right">Action</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
                      <tr class="hover:bg-zinc-50/50 dark:hover:bg-zinc-800/30 transition-colors">
                        <td class="px-6 py-4 font-bold text-zinc-900 dark:text-white">FH-INV-001</td>
                        <td class="px-6 py-4">
                          <span class="px-2 py-1 rounded-md bg-emerald-50 dark:bg-emerald-900/30 text-[11px] font-bold text-emerald-700 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50 uppercase">
                            Paid
                          </span>
                        </td>
                        <td class="px-6 py-4 font-bold text-zinc-600 dark:text-zinc-300">$0.00</td>
                        <td class="px-6 py-4 text-zinc-500">Jan 12, 2026</td>
                        <td class="px-6 py-4 text-right">
                          <button class="text-zinc-400 hover:text-zinc-900 dark:hover:text-white">
                            <.icon name="hero-arrow-down-tray" class="size-4" />
                          </button>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                  <div class="p-8 text-center bg-zinc-50/10">
                    <p class="text-xs text-zinc-400 font-bold uppercase tracking-widest">
                      More invoices will appear here as you grow.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @current_tab == :team do %>
            <div class="space-y-8">
              <!-- Team Header -->
              <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div class="flex items-center gap-3">
                  <div class="size-11 rounded-xl bg-emerald-500/10 flex items-center justify-center">
                    <.icon name="hero-users" class="text-emerald-500 size-6" />
                  </div>
                  <div>
                    <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                      Team Management
                    </h3>
                    <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                      {length(@org_users)} Active Members
                    </p>
                  </div>
                </div>

                <button
                  phx-click="open_invite_modal"
                  class="bg-primary hover:brightness-110 text-white px-6 py-3 rounded-xl text-sm font-black shadow-lg shadow-primary/20 transition-all flex items-center gap-2"
                >
                  <.icon name="hero-plus" class="size-5" /> Invite Member
                </button>
              </div>

    <!-- Team Members Table -->
              <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
                <div class="overflow-x-auto">
                  <table class="w-full text-left text-sm">
                    <thead class="bg-zinc-50 dark:bg-zinc-800/50 text-[10px] font-black uppercase text-zinc-500 dark:text-zinc-400 tracking-[0.1em]">
                      <tr>
                        <th class="px-6 py-4">Member</th>
                        <th class="px-6 py-4">Role</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4">Joined</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
                      <%= for user <- @org_users do %>
                        <tr class="hover:bg-zinc-50/50 dark:hover:bg-zinc-800/30 transition-colors">
                          <td class="px-6 py-4">
                            <div class="flex items-center gap-3">
                              <%= if user.avatar_url do %>
                                <img src={user.avatar_url} class="size-10 rounded-xl object-cover" />
                              <% else %>
                                <div class="size-10 rounded-xl bg-primary/10 flex items-center justify-center font-bold text-primary">
                                  {String.first(user.name || user.email) |> String.upcase()}
                                </div>
                              <% end %>
                              <div class="min-w-0">
                                <p class="font-bold text-zinc-900 dark:text-white truncate">
                                  {user.name || "Unnamed User"}
                                </p>
                                <p class="text-xs text-zinc-500 truncate">{user.email}</p>
                              </div>
                            </div>
                          </td>
                          <td class="px-6 py-4">
                            <%= if user.id == @current_scope.user.id do %>
                              <span class="px-2 py-1 rounded-md text-[10px] font-black uppercase tracking-widest border bg-zinc-50 text-zinc-600 border-zinc-200 dark:bg-zinc-800/50 dark:text-zinc-400 dark:border-zinc-700">
                                {user.role} (You)
                              </span>
                            <% else %>
                              <select
                                phx-change="update_member_role"
                                phx-value-user_id={user.id}
                                class="bg-transparent border-none text-xs font-bold text-zinc-900 dark:text-white focus:ring-0 p-0 cursor-pointer"
                              >
                                <option value="admin" selected={user.role == "admin"}>Admin</option>
                                <option value="technician" selected={user.role == "technician"}>
                                  Technician
                                </option>
                                <option value="viewer" selected={user.role == "viewer"}>
                                  Viewer
                                </option>
                              </select>
                            <% end %>
                          </td>
                          <td class="px-6 py-4">
                            <div class="flex items-center gap-1.5">
                              <div class="size-1.5 rounded-full bg-emerald-500"></div>
                              <span class="text-xs font-bold text-zinc-700 dark:text-zinc-300">
                                Active
                              </span>
                            </div>
                          </td>
                          <td class="px-6 py-4 text-zinc-500">
                            {format_date(user.inserted_at)}
                          </td>
                          <td class="px-6 py-4 text-right">
                            <%= if user.id != @current_scope.user.id do %>
                              <button
                                phx-click="remove_member"
                                phx-value-user_id={user.id}
                                data-confirm="Are you sure you want to remove this member?"
                                class="p-2 text-zinc-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/10 rounded-lg transition-all"
                              >
                                <.icon name="hero-trash" class="size-5" />
                              </button>
                            <% end %>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>

    <!-- Invite Hint -->
              <div class="p-6 rounded-2xl bg-zinc-50 dark:bg-zinc-900/50 border border-dashed border-zinc-200 dark:border-zinc-800 flex items-center gap-4">
                <div class="size-10 rounded-xl bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 flex items-center justify-center text-zinc-400">
                  <.icon name="hero-light-bulb" class="size-5" />
                </div>
                <div class="flex-1">
                  <p class="text-sm font-bold text-zinc-700 dark:text-zinc-200">
                    Pro Tip: Roles defined the access levels.
                  </p>
                  <p class="text-xs text-zinc-500 dark:text-zinc-400">
                    Administrators can manage billing, while Technicians only see assigned jobs.
                  </p>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

    <!-- Invite Member Modal -->
      <.modal
        :if={@show_invite_modal}
        id="invite-modal"
        show
        on_cancel={JS.push("close_invite_modal")}
      >
        <div class="p-2">
          <div class="flex items-center gap-3 mb-6">
            <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
              <.icon name="hero-user-plus" class="text-primary size-6" />
            </div>
            <div>
              <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                Invite Team Member
              </h3>
              <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                Expand your FieldHub organization
              </p>
            </div>
          </div>

          <.form for={@invitation_form} phx-submit="send_invitation" class="space-y-5">
            <div>
              <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300 mb-2">
                Email Address
              </label>
              <.input
                field={@invitation_form[:email]}
                type="email"
                placeholder="colleague@company.com"
                required
              />
            </div>

            <div>
              <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300 mb-2">
                Full Name (Optional)
              </label>
              <.input field={@invitation_form[:name]} type="text" placeholder="John Doe" />
            </div>

            <div>
              <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300 mb-2">
                Role
              </label>
              <.input
                field={@invitation_form[:role]}
                type="select"
                options={[Admin: "admin", Technician: "technician", Viewer: "viewer"]}
              />
              <p class="mt-2 text-[10px] text-zinc-400 font-bold uppercase tracking-wide">
                Admin: Full access • Technician: Job execution • Viewer: Read-only
              </p>
            </div>

            <div class="flex justify-end gap-3 pt-4">
              <button
                type="button"
                phx-click="close_invite_modal"
                class="px-6 py-3 rounded-xl text-sm font-bold text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all font-bold"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-8 py-3 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
              >
                Send Invitation
              </button>
            </div>
          </.form>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true
  def handle_event("update_notifications", %{"user" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_notifications(user, params) do
      {:ok, user} ->
        current_scope = %{socket.assigns.current_scope | user: user}

        {:noreply,
         socket
         |> assign(current_scope: current_scope)
         |> put_flash(:info, "Notification preferences updated.")
         |> assign(notification_form: to_form(Accounts.change_user_notifications(user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, notification_form: to_form(changeset))}
    end
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

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("remove_avatar", _params, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_profile(user, %{avatar_url: nil}) do
      {:ok, user} ->
        current_scope = %{socket.assigns.current_scope | user: user}

        {:noreply,
         socket |> assign(current_scope: current_scope) |> put_flash(:info, "Avatar removed.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not remove avatar.")}
    end
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    # Handle image uploads
    avatar_url =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        dest =
          Path.join([
            :code.priv_dir(:field_hub),
            "static",
            "uploads",
            "#{entry.uuid}.#{ext(entry)}"
          ])

        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)
      |> List.first()

    user_params =
      if avatar_url, do: Map.put(user_params, "avatar_url", avatar_url), else: user_params

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
  def handle_event("open_invite_modal", _params, socket) do
    {:noreply, assign(socket, show_invite_modal: true)}
  end

  @impl true
  def handle_event("close_invite_modal", _params, socket) do
    {:noreply, assign(socket, show_invite_modal: false)}
  end

  @impl true
  def handle_event("send_invitation", %{"user" => attrs}, socket) do
    org = socket.assigns.current_organization

    case Accounts.invite_user(org, attrs) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Invitation sent successfully!")
         |> assign(show_invite_modal: false)
         |> assign(:org_users, Accounts.list_org_users(org))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not send invitation.")}
    end
  end

  @impl true
  def handle_event("update_member_role", %{"user_id" => user_id, "value" => role}, socket) do
    user = Accounts.get_user!(user_id)
    # Ensure user is in the same org
    if user.organization_id == socket.assigns.current_organization.id do
      case Accounts.update_user_profile(user, %{role: role}) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "User role updated.")
           |> assign(:org_users, Accounts.list_org_users(socket.assigns.current_organization))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not update user role.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized.")}
    end
  end

  @impl true
  def handle_event("remove_member", %{"user_id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    if user.organization_id == socket.assigns.current_organization.id do
      Accounts.delete_user(user)

      {:noreply,
       socket
       |> put_flash(:info, "Member removed from organization.")
       |> assign(:org_users, Accounts.list_org_users(socket.assigns.current_organization))}
    else
      {:noreply, put_flash(socket, :error, "Unauthorized.")}
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
      {:noreply,
       socket
       |> put_flash(:error, "You must log in to access this page.")
       |> redirect(to: ~p"/users/log-in")}
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
      {:noreply,
       socket
       |> put_flash(:error, "You must log in to access this page.")
       |> redirect(to: ~p"/users/log-in")}
    end
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp format_date(nil), do: "N/A"
  defp format_date(%{__struct__: _} = date), do: Calendar.strftime(date, "%b %d, %Y")
  defp format_date(_), do: "N/A"
end
