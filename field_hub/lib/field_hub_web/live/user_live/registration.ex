defmodule FieldHubWeb.UserLive.Registration do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950 flex font-dashboard">
      <!-- Left Sidebar: Brand & Value -->
      <div class="hidden lg:flex lg:w-[40%] bg-zinc-900 relative overflow-hidden flex-col justify-between p-12">
        <div class="absolute inset-0 opacity-20">
          <div class="absolute top-[-10%] left-[-10%] w-[60%] h-[60%] bg-indigo-500/30 rounded-full blur-[120px]">
          </div>
          <div class="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] bg-emerald-500/20 rounded-full blur-[120px]">
          </div>
        </div>

        <div class="relative z-10">
          <div class="flex items-center gap-3">
            <div class="size-11 bg-indigo-600 rounded-2xl flex items-center justify-center text-white shadow-xl shadow-indigo-600/20">
              <.icon name="hero-command-line" class="size-6" />
            </div>
            <span class="text-2xl font-black tracking-tight text-white">FieldHub</span>
          </div>
        </div>

        <div class="relative z-10 space-y-8">
          <div class="space-y-4">
            <h2 class="text-5xl font-black text-white leading-[1.1] tracking-tight">
              Scale your service business with <span class="text-indigo-400">confidence.</span>
            </h2>
            <p class="text-lg text-zinc-400 font-medium leading-relaxed max-w-md">
              The all-in-one platform for modern field service teams. Dispatch, track, and get paid faster.
            </p>
          </div>

          <div class="flex items-center gap-4 text-white/60">
            <div class="flex -space-x-3">
              <img
                :for={i <- 1..4}
                src={"https://i.pravatar.cc/100?img=#{i+10}"}
                class="size-10 rounded-full border-2 border-zinc-900"
              />
            </div>
            <p class="text-sm font-bold">Joined by 2,000+ contractors</p>
          </div>
        </div>

        <div class="relative z-10 text-zinc-500 text-sm font-bold">
          &copy; {DateTime.utc_now().year} FieldHub Inc. All rights reserved.
        </div>
      </div>
      
    <!-- Right Side: Form -->
      <div class="flex-1 flex flex-col items-center justify-center p-6 lg:p-24 bg-white dark:bg-zinc-950">
        <div class="w-full max-w-md space-y-10">
          <div class="lg:hidden flex justify-center mb-8">
            <div class="flex items-center gap-2">
              <div class="size-10 bg-indigo-600 rounded-xl flex items-center justify-center text-white">
                <.icon name="hero-command-line" class="size-5" />
              </div>
              <span class="text-xl font-black tracking-tight dark:text-white">FieldHub</span>
            </div>
          </div>

          <div class="space-y-2 text-center lg:text-left">
            <h1 class="text-4xl font-black text-zinc-900 dark:text-white tracking-tight">
              Get started for free
            </h1>
            <p class="text-zinc-500 dark:text-zinc-400 font-medium text-lg">
              Create your professional account in seconds.
            </p>
          </div>

          <.form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-6"
          >
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div class="space-y-2">
                <label class="text-xs font-bold text-zinc-500 dark:text-zinc-400 uppercase tracking-wider ml-1">
                  Full Name
                </label>
                <.input
                  field={@form[:name]}
                  placeholder="Alex Johnson"
                  required
                  class="w-full !bg-zinc-50 dark:!bg-zinc-900 !border-zinc-200 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 focus:!ring-2 focus:!ring-indigo-500/20 focus:!border-indigo-500 transition-all font-semibold"
                />
              </div>
              <div class="space-y-2">
                <label class="text-xs font-bold text-zinc-500 dark:text-zinc-400 uppercase tracking-wider ml-1">
                  Company
                </label>
                <.input
                  field={@form[:company_name]}
                  placeholder="Apex Plumbing"
                  required
                  class="w-full !bg-zinc-50 dark:!bg-zinc-900 !border-zinc-200 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 focus:!ring-2 focus:!ring-indigo-500/20 focus:!border-indigo-500 transition-all font-semibold"
                />
              </div>
            </div>

            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-500 dark:text-zinc-400 uppercase tracking-wider ml-1">
                Email Address
              </label>
              <.input
                field={@form[:email]}
                type="email"
                placeholder="alex@company.com"
                required
                class="w-full !bg-zinc-50 dark:!bg-zinc-900 !border-zinc-200 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 focus:!ring-2 focus:!ring-indigo-500/20 focus:!border-indigo-500 transition-all font-semibold"
              />
            </div>

            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-500 dark:text-zinc-400 uppercase tracking-wider ml-1">
                Password
              </label>
              <.input
                field={@form[:password]}
                type="password"
                placeholder="••••••••"
                required
                class="w-full !bg-zinc-50 dark:!bg-zinc-900 !border-zinc-200 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 focus:!ring-2 focus:!ring-indigo-500/20 focus:!border-indigo-500 transition-all font-semibold"
              />
            </div>

            <div class="flex items-center gap-3">
              <input
                type="checkbox"
                required
                class="size-5 rounded-lg border-zinc-300 dark:border-zinc-800 text-indigo-600 focus:ring-indigo-500/20 dark:bg-zinc-900"
              />
              <label class="text-sm font-medium text-zinc-500 dark:text-zinc-400">
                I agree to the
                <a href="#" class="text-indigo-600 dark:text-indigo-400 hover:underline">Terms</a>
                and
                <a href="#" class="text-indigo-600 dark:text-indigo-400 hover:underline">
                  Privacy Policy
                </a>
              </label>
            </div>

            <button
              type="submit"
              class="w-full bg-indigo-600 text-white py-4 rounded-2xl text-base font-bold shadow-xl shadow-indigo-600/20 hover:bg-indigo-700 transition-all active:scale-[0.98]"
            >
              Create account
            </button>
          </.form>

          <div class="text-center">
            <p class="text-zinc-500 dark:text-zinc-400 font-medium">
              Already have an account?
              <.link
                navigate={~p"/users/log-in"}
                class="text-indigo-600 dark:text-indigo-400 font-bold hover:underline"
              >
                Log in
              </.link>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns.current_scope do
      %{user: user} when not is_nil(user) ->
        {:ok, redirect(socket, to: FieldHubWeb.UserAuth.signed_in_path(user))}

      _ ->
        changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

        {:ok,
         socket
         |> assign_form(changeset), temporary_assigns: [form: nil]}
    end
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Send the email for future reference
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        # Generate a token for immediate auto-login
        token = Accounts.generate_magic_link_token(user)

        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully! Logging you in...")
         |> push_navigate(to: ~p"/users/log-in/#{token}?auto=true")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
