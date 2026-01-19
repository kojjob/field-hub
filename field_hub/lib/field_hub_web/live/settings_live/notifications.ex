defmodule FieldHubWeb.SettingsLive.Notifications do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    changeset = Accounts.User.notification_changeset(user, %{})

    socket =
      socket
      |> assign(:page_title, "Notification Settings")
      |> assign(:current_nav, :notifications)
      |> assign(:form, to_form(changeset, as: "user"))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <div class="mb-8">
        <h1 class="text-3xl font-black text-zinc-900 dark:text-white tracking-tight">
          Notifications
        </h1>
        <p class="mt-2 text-zinc-600 dark:text-zinc-400">
          Manage how and when you receive updates.
        </p>
      </div>

      <div class="bg-white dark:bg-zinc-900 rounded-[32px] p-8 shadow-xl shadow-zinc-900/5 ring-1 ring-zinc-200 dark:ring-zinc-800">
        <.form for={@form} id="notifications-form" phx-submit="save" phx-change="validate" class="space-y-8">
          <div class="space-y-6">
            <h3 class="text-lg font-bold text-zinc-900 dark:text-white flex items-center gap-2">
              <.icon name="hero-envelope" class="size-5 text-primary" />
              Email Notifications
            </h3>

            <div class="space-y-4">
              <div class="flex items-start gap-4">
                <div class="flex items-center h-5">
                  <input
                    id="notify_on_new_jobs"
                    name="user[notify_on_new_jobs]"
                    type="checkbox"
                    value="true"
                    checked={@form[:notify_on_new_jobs].value}
                    class="size-5 rounded-md border-zinc-300 text-primary focus:ring-primary"
                  />
                  <input name="user[notify_on_new_jobs]" type="hidden" value="false" />
                </div>
                <div class="flex-1 text-sm">
                  <label for="notify_on_new_jobs" class="font-bold text-zinc-900 dark:text-white">New Jobs</label>
                  <p class="text-zinc-500 dark:text-zinc-400">Get notified when a new job is assigned to you.</p>
                </div>
              </div>

              <div class="flex items-start gap-4">
                <div class="flex items-center h-5">
                  <input
                    id="notify_on_job_updates"
                    name="user[notify_on_job_updates]"
                    type="checkbox"
                    value="true"
                    checked={@form[:notify_on_job_updates].value}
                    class="size-5 rounded-md border-zinc-300 text-primary focus:ring-primary"
                  />
                   <input name="user[notify_on_job_updates]" type="hidden" value="false" />
                </div>
                <div class="flex-1 text-sm">
                  <label for="notify_on_job_updates" class="font-bold text-zinc-900 dark:text-white">Job Updates</label>
                  <p class="text-zinc-500 dark:text-zinc-400">Receive updates when job status changes or comments are added.</p>
                </div>
              </div>
            </div>
          </div>

          <div class="w-full h-px bg-zinc-100 dark:bg-zinc-800"></div>

          <div class="space-y-6">
            <h3 class="text-lg font-bold text-zinc-900 dark:text-white flex items-center gap-2">
              <.icon name="hero-megaphone" class="size-5 text-zinc-400" />
              Marketing
            </h3>

            <div class="space-y-4">
              <div class="flex items-start gap-4">
                <div class="flex items-center h-5">
                  <input
                    id="notify_marketing"
                    name="user[notify_marketing]"
                    type="checkbox"
                    value="true"
                    checked={@form[:notify_marketing].value}
                    class="size-5 rounded-md border-zinc-300 text-primary focus:ring-primary"
                  />
                  <input name="user[notify_marketing]" type="hidden" value="false" />
                </div>
                <div class="flex-1 text-sm">
                  <label for="notify_marketing" class="font-bold text-zinc-900 dark:text-white">Product Updates</label>
                  <p class="text-zinc-500 dark:text-zinc-400">Receive news about new features and improvements.</p>
                </div>
              </div>
            </div>
          </div>

          <div class="pt-6 flex justify-end">
             <button type="submit" class="flex items-center gap-2 px-8 py-3 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1">
              Save Preferences
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.User.notification_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: "user"))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_notifications(user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user) # Update current_user in socket
         |> put_flash(:info, "Notifications preferences updated successfully")
         |> assign(:form, to_form(Accounts.User.notification_changeset(user, %{}), as: "user"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "user"))}
    end
  end
end
