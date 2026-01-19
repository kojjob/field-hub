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
    <div class="space-y-10 pb-20">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            Account
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Notification Settings
          </h2>
          <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 max-w-lg">
            Manage how and when you receive updates and alerts.
          </p>
        </div>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <div class="xl:col-span-2">
          <div class="bg-white dark:bg-zinc-900 p-8 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm relative overflow-hidden group">
            <div class="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full -mr-16 -mt-16 transition-all group-hover:bg-primary/10"></div>

            <.form for={@form} id="notifications-form" phx-submit="save" phx-change="validate" class="space-y-8 relative">
              <div class="space-y-6">
                <h3 class="text-lg font-black text-zinc-900 dark:text-white flex items-center gap-2">
                  <div class="size-8 rounded-lg bg-primary/10 flex items-center justify-center">
                    <.icon name="hero-envelope" class="size-4 text-primary" />
                  </div>
                  Email Notifications
                </h3>

                <div class="pl-10 space-y-4">
                  <div class="flex items-start gap-4 p-4 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-100 dark:border-zinc-800 transition-all hover:border-primary/20">
                    <div class="flex items-center h-5 pt-1">
                      <input
                        id="notify_on_new_jobs"
                        name="user[notify_on_new_jobs]"
                        type="checkbox"
                        value="true"
                        checked={@form[:notify_on_new_jobs].value}
                        class="size-5 rounded-md border-zinc-300 text-primary focus:ring-primary cursor-pointer"
                      />
                      <input name="user[notify_on_new_jobs]" type="hidden" value="false" />
                    </div>
                    <div class="flex-1 text-sm cursor-pointer" onclick="document.getElementById('notify_on_new_jobs').click()">
                      <label class="font-bold text-zinc-900 dark:text-white cursor-pointer select-none">New Job Assignments</label>
                      <p class="text-zinc-500 dark:text-zinc-400 mt-0.5">Get notified immediately when you are assigned to a new job.</p>
                    </div>
                  </div>

                  <div class="flex items-start gap-4 p-4 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-100 dark:border-zinc-800 transition-all hover:border-primary/20">
                    <div class="flex items-center h-5 pt-1">
                      <input
                        id="notify_on_job_updates"
                        name="user[notify_on_job_updates]"
                        type="checkbox"
                        value="true"
                        checked={@form[:notify_on_job_updates].value}
                        class="size-5 rounded-md border-zinc-300 text-primary focus:ring-primary cursor-pointer"
                      />
                       <input name="user[notify_on_job_updates]" type="hidden" value="false" />
                    </div>
                    <div class="flex-1 text-sm cursor-pointer" onclick="document.getElementById('notify_on_job_updates').click()">
                      <label class="font-bold text-zinc-900 dark:text-white cursor-pointer select-none">Job Updates</label>
                      <p class="text-zinc-500 dark:text-zinc-400 mt-0.5">Receive updates when job status changes or comments are added.</p>
                    </div>
                  </div>
                </div>
              </div>

              <div class="w-full h-px bg-zinc-100 dark:bg-zinc-800 my-8"></div>

              <div class="space-y-6">
                <h3 class="text-lg font-black text-zinc-900 dark:text-white flex items-center gap-2">
                  <div class="size-8 rounded-lg bg-amber-500/10 flex items-center justify-center">
                    <.icon name="hero-megaphone" class="size-4 text-amber-500" />
                  </div>
                  Marketing & Updates
                </h3>

                <div class="pl-10 space-y-4">
                  <div class="flex items-start gap-4 p-4 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-100 dark:border-zinc-800 transition-all hover:border-amber-500/20">
                    <div class="flex items-center h-5 pt-1">
                      <input
                        id="notify_marketing"
                        name="user[notify_marketing]"
                        type="checkbox"
                        value="true"
                        checked={@form[:notify_marketing].value}
                        class="size-5 rounded-md border-zinc-300 text-amber-500 focus:ring-amber-500 cursor-pointer"
                      />
                      <input name="user[notify_marketing]" type="hidden" value="false" />
                    </div>
                    <div class="flex-1 text-sm cursor-pointer" onclick="document.getElementById('notify_marketing').click()">
                      <label class="font-bold text-zinc-900 dark:text-white cursor-pointer select-none">Product Announcements</label>
                      <p class="text-zinc-500 dark:text-zinc-400 mt-0.5">Be the first to know about new features, improvements, and news.</p>
                    </div>
                  </div>
                </div>
              </div>

              <div class="pt-6 flex justify-end">
                 <button type="submit" class="flex items-center gap-2 px-8 py-3 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1">
                  <.icon name="hero-check" class="size-5" /> Save Preferences
                </button>
              </div>
            </.form>
          </div>
        </div>

        <div class="xl:col-span-1 space-y-6">
             <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
             <h3 class="font-bold text-zinc-900 dark:text-white mb-4">Notification Channels</h3>
             <div class="space-y-3">
               <div class="flex items-center gap-3 p-3 rounded-xl bg-zinc-50 dark:bg-zinc-800/50">
                 <.icon name="hero-device-phone-mobile" class="size-5 text-zinc-400" />
                 <div>
                    <p class="text-xs font-bold text-zinc-900 dark:text-white">Push Notifications</p>
                    <p class="text-[10px] text-zinc-500">Coming to mobile app soon</p>
                 </div>
               </div>
               <div class="flex items-center gap-3 p-3 rounded-xl bg-zinc-50 dark:bg-zinc-800/50">
                 <.icon name="hero-chat-bubble-left-ellipsis" class="size-5 text-zinc-400" />
                 <div>
                    <p class="text-xs font-bold text-zinc-900 dark:text-white">SMS Alerts</p>
                    <p class="text-[10px] text-zinc-500">Enable in Organization Settings</p>
                 </div>
               </div>
             </div>
           </div>
        </div>
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
