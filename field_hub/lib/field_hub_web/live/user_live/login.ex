defmodule FieldHubWeb.UserLive.Login do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950 flex font-dashboard">
      <!-- Left Sidebar: Brand & Value -->
      <div class="hidden lg:flex lg:w-[40%] bg-zinc-900 relative overflow-hidden flex-col justify-between p-12">
        <div class="absolute inset-0 opacity-20">
          <div class="absolute top-[-10%] left-[-10%] w-[60%] h-[60%] bg-primary/30 rounded-full blur-[120px]">
          </div>
          <div class="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] bg-primary/20 rounded-full blur-[120px]">
          </div>
        </div>

        <div class="relative z-10">
          <div class="flex items-center gap-3">
            <div class="size-11 bg-primary rounded-2xl flex items-center justify-center text-white shadow-xl shadow-primary/20">
              <.icon name="hero-command-line" class="size-6" />
            </div>
            <span class="text-2xl font-black tracking-tight text-white">FieldHub</span>
          </div>
        </div>

        <div class="relative z-10 space-y-8">
          <div class="space-y-4">
            <h2 class="text-5xl font-black text-white leading-[1.1] tracking-tight">
              Welcome back to <span class="text-primary">FieldHub.</span>
            </h2>
            <p class="text-lg text-zinc-400 font-medium leading-relaxed max-w-md">
              Sign in to manage your team, track jobs in real-time, and scale your operations.
            </p>
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
              <div class="size-10 bg-primary rounded-xl flex items-center justify-center text-white">
                <.icon name="hero-command-line" class="size-5" />
              </div>
              <span class="text-xl font-black tracking-tight dark:text-white">FieldHub</span>
            </div>
          </div>

          <div class="space-y-2 text-center lg:text-left">
            <h1 class="text-4xl font-black text-zinc-900 dark:text-white tracking-tight">
              Login to account
            </h1>
            <p class="text-zinc-500 dark:text-zinc-400 font-medium text-lg">
              Enter your work email and password.
            </p>
          </div>

          <.form
            :let={f}
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
            class="space-y-6"
          >
            <div class="space-y-2">
              <label class="text-xs font-bold text-zinc-500 dark:text-zinc-400 uppercase tracking-wider ml-1">
                Email Address
              </label>
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                placeholder="alex@company.com"
                required
                class="w-full !bg-zinc-50 dark:!bg-zinc-900 !border-zinc-200 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 focus:!ring-2 focus:!ring-primary/20 focus:!border-primary transition-all font-semibold"
              />
            </div>

            <div class="space-y-2">
              <div class="flex items-center justify-between px-1">
                <label class="text-xs font-bold text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  Password
                </label>
                <.link
                  navigate={~p"/users/settings"}
                  class="text-xs font-bold text-primary hover:underline"
                >
                  Forgot?
                </.link>
              </div>
              <.input
                field={f[:password]}
                type="password"
                placeholder="••••••••"
                required
                class="w-full !bg-zinc-50 dark:!bg-zinc-900 !border-zinc-200 dark:!border-zinc-800 !rounded-2xl !h-12 !px-4 focus:!ring-2 focus:!ring-primary/20 focus:!border-primary transition-all font-semibold"
              />
            </div>

            <div class="flex items-center justify-between px-1">
              <div class="flex items-center gap-3">
                <input
                  type="checkbox"
                  id="remember_me"
                  name={f[:remember_me].name}
                  class="size-5 rounded-lg border-zinc-300 dark:border-zinc-800 text-primary focus:ring-primary/20 dark:bg-zinc-900"
                />
                <label for="remember_me" class="text-sm font-medium text-zinc-500 dark:text-zinc-400">
                  Remember me
                </label>
              </div>
            </div>

            <button
              type="submit"
              class="w-full bg-primary text-white py-4 rounded-2xl text-base font-bold shadow-xl shadow-primary/20 hover:bg-primary/90 transition-all active:scale-[0.98]"
            >
              Sign in
            </button>
          </.form>

          <div class="text-center">
            <p class="text-zinc-500 dark:text-zinc-400 font-medium">
              Don't have an account?
              <.link
                navigate={~p"/users/register"}
                class="text-primary font-bold hover:underline"
              >
                Create account
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
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end
end
