defmodule FieldHubWeb.SettingsLive.Users do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    org = socket.assigns.current_organization

    if user.role not in ["owner", "admin"] do
      {:ok,
       socket
       |> put_flash(:error, "You do not have permission to view team settings.")
       |> push_navigate(to: ~p"/dashboard")}
    else
      socket =
        socket
        |> assign(:page_title, "Team Management")
        |> assign(:current_nav, :users)
        |> assign(:users, Accounts.list_org_users(org))
        |> assign(:show_invite_modal, false)
        |> assign(:form, to_form(%{}, as: "user"))

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("open_invite_modal", _params, socket) do
    {:noreply, assign(socket, :show_invite_modal, true)}
  end

  @impl true
  def handle_event("close_invite_modal", _params, socket) do
    {:noreply, assign(socket, :show_invite_modal, false)}
  end

  @impl true
  def handle_event("validate", %{"user" => _user_params}, socket) do
    # We could add validation logic here if we exposed a changeset
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.invite_user(socket.assigns.current_organization, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User invited successfully.")
         |> assign(:show_invite_modal, false)
         |> assign(:users, Accounts.list_org_users(socket.assigns.current_organization))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "user"))}
    end
  end

  @impl true
  def handle_event("delete_user", %{"id" => id}, socket) do
    user_to_delete = Accounts.get_user!(id)

    # Prevent deleting yourself
    if user_to_delete.id == socket.assigns.current_user.id do
      {:noreply, put_flash(socket, :error, "You cannot delete your own account.")}
    else
      case Accounts.delete_user(user_to_delete) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "User removed successfully.")
           |> assign(:users, Accounts.list_org_users(socket.assigns.current_organization))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not delete user.")}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10 pb-20">
      <!-- Page Heading -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            Organization
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Team Management
          </h2>
          <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 max-w-lg">
            Manage your organization's team members and their roles.
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <button
            phx-click="open_invite_modal"
            class="flex items-center gap-2 px-6 py-2.5 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
          >
            <.icon name="hero-user-plus" class="size-5" /> Invite Member
          </button>
        </div>
      </div>
      
    <!-- Users List -->
      <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-zinc-100 dark:border-zinc-800">
                <th class="px-6 py-4 text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  Name
                </th>
                <th class="px-6 py-4 text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  Email
                </th>
                <th class="px-6 py-4 text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  Role
                </th>
                <th class="px-6 py-4 text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  Joined
                </th>
                <th class="px-6 py-4 text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wider text-right">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
              <%= for user <- @users do %>
                <tr class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div class="size-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-lg">
                        <%= if user.avatar_url do %>
                          <img src={user.avatar_url} class="size-10 rounded-full object-cover" />
                        <% else %>
                          {String.at(user.name || "U", 0)}
                        <% end %>
                      </div>
                      <div>
                        <div class="font-bold text-zinc-900 dark:text-white">
                          {user.name || "Unknown"}
                        </div>
                        <div class="text-xs text-zinc-500 dark:text-zinc-400">
                          {user.phone}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-sm text-zinc-600 dark:text-zinc-400">
                    {user.email}
                  </td>
                  <td class="px-6 py-4">
                    <span class={[
                      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wide",
                      user.role == "owner" &&
                        "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
                      user.role == "admin" &&
                        "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300",
                      user.role == "technician" &&
                        "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300",
                      user.role == "dispatcher" &&
                        "bg-cyan-100 text-cyan-800 dark:bg-cyan-900/30 dark:text-cyan-300",
                      user.role == "viewer" &&
                        "bg-zinc-100 text-zinc-800 dark:bg-zinc-800 dark:text-zinc-300"
                    ]}>
                      {user.role}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-sm text-zinc-500 dark:text-zinc-500">
                    {Calendar.strftime(user.inserted_at, "%b %d, %Y")}
                  </td>
                  <td class="px-6 py-4 text-right">
                    <%= if user.id != @current_user.id do %>
                      <button
                        phx-click="delete_user"
                        phx-value-id={user.id}
                        data-confirm="Are you sure you want to remove this user?"
                        class="text-red-500 hover:text-red-600 dark:hover:text-red-400 font-bold text-sm opacity-0 group-hover:opacity-100 transition-all p-2 bg-red-50 dark:bg-red-900/10 rounded-lg"
                      >
                        Remove
                      </button>
                    <% else %>
                      <span class="text-xs text-zinc-400 italic">It's you</span>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
      
    <!-- Invite Modal -->
      <%= if @show_invite_modal do %>
        <div
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-zinc-900/80 backdrop-blur-sm transition-all"
          id="invite-modal"
        >
          <div class="bg-white dark:bg-zinc-900 w-full max-w-md rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-2xl overflow-hidden relative animate-in fade-in zoom-in-95 duration-200">
            <button
              phx-click="close_invite_modal"
              class="absolute top-4 right-4 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200"
            >
              <.icon name="hero-x-mark" class="size-6" />
            </button>

            <div class="p-8">
              <div class="flex items-center gap-3 mb-6">
                <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
                  <.icon name="hero-user-plus" class="text-primary size-6" />
                </div>
                <div>
                  <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                    Invite Member
                  </h3>
                  <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                    Add someone to your team
                  </p>
                </div>
              </div>

              <.form
                for={@form}
                id="invite-user-form"
                phx-submit="save"
                phx-change="validate"
                class="space-y-6"
              >
                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Full Name
                  </label>
                  <input
                    type="text"
                    name="user[name]"
                    value={@form[:name].value}
                    required
                    placeholder="Jane Doe"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium"
                  />
                  <.error :for={err <- @form[:name].errors}>
                    {FieldHubWeb.CoreComponents.translate_error(err)}
                  </.error>
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">
                    Email Address
                  </label>
                  <input
                    type="email"
                    name="user[email]"
                    value={@form[:email].value}
                    required
                    placeholder="jane@company.com"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white placeholder-zinc-400 focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium"
                  />
                  <.error :for={err <- @form[:email].errors}>
                    {FieldHubWeb.CoreComponents.translate_error(err)}
                  </.error>
                </div>

                <div class="space-y-2">
                  <label class="block text-sm font-bold text-zinc-700 dark:text-zinc-300">Role</label>
                  <select
                    name="user[role]"
                    class="w-full px-4 py-3 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-white focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all font-medium appearance-none"
                  >
                    <option value="viewer" selected>Viewer (Read-only)</option>
                    <option value="technician">Technician (Mobile App access)</option>
                    <option value="dispatcher">Dispatcher (Assign jobs)</option>
                    <option value="admin">Admin (Full access)</option>
                    <option value="owner">Owner (Full access + Billing)</option>
                  </select>
                </div>

                <div class="flex justify-end gap-3 pt-4">
                  <button
                    type="button"
                    phx-click="close_invite_modal"
                    class="px-6 py-3 rounded-xl text-sm font-bold text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    class="flex items-center gap-2 px-8 py-3 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
                  >
                    Send Invitation
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
