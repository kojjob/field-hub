defmodule FieldHubWeb.UserLive.Login do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#F8FAFB] dark:bg-zinc-950 flex flex-col font-dashboard">
      <!-- Navbar -->
      <nav class="flex items-center justify-between px-8 py-6">
        <div class="flex items-center gap-2">
          <div class="size-8 bg-fsm-primary rounded-lg flex items-center justify-center text-white shadow-lg shadow-fsm-primary/20">
            <span class="material-symbols-outlined notranslate text-xl">grid_view</span>
          </div>
          <span class="text-xl font-black tracking-tighter text-slate-900 dark:text-white mt-0.5">FieldHub</span>
        </div>
        <button class="text-sm font-bold text-slate-500 hover:text-fsm-primary transition-colors bg-white dark:bg-zinc-900 px-4 py-2 rounded-xl border border-slate-200 dark:border-zinc-800 shadow-sm">
          Contact Admin
        </button>
      </nav>

      <div class="flex-1 flex items-center justify-center px-4 py-12">
        <div class="max-w-6xl w-full grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          <!-- Left Side: Login Form -->
          <div class="flex flex-col max-w-md mx-auto lg:mx-0 w-full animate-in">
             <div class="bg-white dark:bg-zinc-900/50 p-10 rounded-[2.5rem] shadow-2xl shadow-slate-200/50 dark:shadow-none border border-slate-100 dark:border-zinc-800 relative overflow-hidden">
                <div class="absolute top-0 right-0 p-8">
                   <div class="size-12 bg-fsm-primary/5 rounded-full flex items-center justify-center">
                      <.icon name="hero-shield-check" class="size-6 text-fsm-primary" />
                   </div>
                </div>

                <h2 class="text-2xl font-display font-bold text-slate-900 dark:text-white mt-8 mb-2">Welcome back</h2>
                <p class="text-slate-500 font-medium mb-8">Please enter your details to sign in.</p>

                <div class="grid grid-cols-2 gap-4 mb-8">
                  <button class="flex items-center justify-center gap-3 w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-2xl py-3.5 hover:bg-slate-50 transition-all group">
                    <img src="https://www.svgrepo.com/show/475656/google-color.svg" class="w-5 h-5 group-hover:scale-110 transition-transform" />
                    <span class="font-bold text-slate-600 dark:text-slate-300">Google</span>
                  </button>
                  <button class="flex items-center justify-center gap-3 w-full bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-2xl py-3.5 hover:bg-slate-50 transition-all group">
                    <img src="https://www.svgrepo.com/show/452263/microsoft.svg" class="w-5 h-5 group-hover:scale-110 transition-transform" />
                    <span class="font-bold text-slate-600 dark:text-slate-300">Microsoft</span>
                  </button>
                </div>

                <div class="relative flex py-2 items-center mb-6">
                  <div class="flex-grow border-t border-slate-200 dark:border-zinc-800"></div>
                  <span class="flex-shrink-0 mx-4 text-slate-400 text-xs font-bold uppercase tracking-widest">Or sign in with</span>
                  <div class="flex-grow border-t border-slate-200 dark:border-zinc-800"></div>
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
                  <div class="space-y-1.5">
                    <label class="text-[11px] font-black uppercase tracking-widest text-slate-400 ml-1">Email Address</label>
                    <.input
                      readonly={!!@current_scope}
                      field={f[:email]}
                      type="email"
                      placeholder="e.g. john@servicepro.com"
                      required
                      class="input input-bordered w-full !bg-slate-50 dark:!bg-zinc-900 !border-slate-100 dark:!border-zinc-800 !rounded-2xl !h-14 !pl-5 focus:!ring-2 focus:!ring-fsm-primary/20 focus:!border-fsm-primary transition-all font-bold text-slate-700 dark:text-slate-200"
                    />
                  </div>

                  <div class="space-y-1.5">
                    <div class="flex items-center justify-between px-1">
                      <label class="text-[11px] font-black uppercase tracking-widest text-slate-400">Password</label>
                      <.link navigate={~p"/users/settings"} class="text-[11px] font-bold text-fsm-primary hover:underline">Forgot password?</.link>
                    </div>
                    <div class="relative group">
                      <.input
                        id="password_input"
                        field={f[:password]}
                        type="password"
                        placeholder="••••••••"
                        required
                        class="input input-bordered w-full !bg-slate-50 dark:!bg-zinc-900 !border-slate-100 dark:!border-zinc-800 !rounded-2xl !h-14 !pl-5 focus:!ring-2 focus:!ring-fsm-primary/20 focus:!border-fsm-primary transition-all font-bold text-slate-700 dark:text-slate-200 pr-12"
                      />
                      <button
                        type="button"
                        phx-hook="PasswordToggle"
                        id="password_toggle"
                        data-input-id="password_input"
                        class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-fsm-primary transition-colors"
                      >
                        <span class="material-symbols-outlined notranslate text-xl icon-vis">visibility</span>
                        <span class="material-symbols-outlined notranslate text-xl icon-hid" style="display: none;">visibility_off</span>
                      </button>
                    </div>
                  </div>

                  <div class="flex items-center gap-3 px-1">
                    <input type="checkbox" id="remember_me" name={f[:remember_me].name} class="size-5 rounded-lg border-slate-200 text-fsm-primary focus:ring-fsm-primary/20" />
                    <label for="remember_me" class="text-sm font-bold text-slate-600 dark:text-slate-400">Remember me</label>
                  </div>

                  <.button class="btn btn-primary w-full !bg-fsm-primary !border-fsm-primary !text-white !py-6 !rounded-[1.25rem] !text-base !font-black !tracking-tight shadow-xl shadow-fsm-primary/20 hover:brightness-110 hover:!bg-fsm-primary hover:!border-fsm-primary transition-all">
                    Sign In
                  </.button>
                </.form>

                <div class="mt-8 text-center pt-8 border-t border-slate-50 dark:border-zinc-800">
                  <p class="text-sm font-bold text-slate-500">
                    Don't have an account? <.link navigate={~p"/users/register"} class="text-fsm-primary hover:underline">Create an account</.link>
                  </p>
                </div>
             </div>
          </div>

          <!-- Right Side: Decorative Preview -->
          <div class="hidden lg:flex flex-col items-center justify-center animate-fade">
             <div class="relative w-full max-w-xl">
                <!-- Blurred Glow -->
                <div class="absolute -top-20 -left-20 size-80 bg-fsm-primary/10 rounded-full blur-[100px]"></div>
                <div class="absolute -bottom-20 -right-20 size-80 bg-blue-500/10 rounded-full blur-[100px]"></div>

                <div class="relative bg-white/40 dark:bg-zinc-800/10 backdrop-blur-xl p-8 rounded-[3rem] border border-white/50 dark:border-white/5 shadow-2xl">
                   <img src="/images/login_preview.png" class="rounded-[2rem] shadow-2xl" alt="Dashboard Preview" />

                   <div class="mt-10 text-center space-y-3">
                      <h3 class="text-2xl font-black text-slate-900 dark:text-white tracking-tight">Service Management Simplified</h3>
                      <p class="text-slate-500 dark:text-slate-400 font-medium max-w-sm mx-auto">
                        Real-time scheduling, dispatching, and invoicing for your entire fleet in one powerful hub.
                      </p>
                   </div>
                </div>

                <!-- Floating Badge -->
                <div class="absolute -top-6 -right-6 bg-white dark:bg-zinc-900 p-4 rounded-2xl shadow-xl border border-slate-100 dark:border-zinc-800 flex items-center gap-3 animate-gradient-x">
                   <div class="size-10 bg-emerald-100 text-emerald-600 rounded-xl flex items-center justify-center">
                      <span class="material-symbols-outlined notranslate">check_circle</span>
                   </div>
                   <div>
                      <p class="text-[10px] text-slate-400 font-black uppercase tracking-widest">Status</p>
                      <p class="text-sm font-black text-slate-900 dark:text-white tracking-tight">Job Completed</p>
                   </div>
                </div>
             </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <footer class="px-8 py-10 flex flex-col md:flex-row items-center justify-between border-t border-slate-100 dark:border-zinc-800 bg-white/50 dark:bg-zinc-900/50">
        <p class="text-xs font-bold text-slate-400">© 2024 FieldHub Inc. All rights reserved.</p>
        <div class="flex items-center gap-6 mt-4 md:mt-0">
          <a href="#" class="text-xs font-bold text-slate-500 hover:text-fsm-primary transition-colors">Privacy Policy</a>
          <a href="#" class="text-xs font-bold text-slate-500 hover:text-fsm-primary transition-colors">Terms of Service</a>
          <a href="#" class="text-xs font-bold text-slate-500 hover:text-fsm-primary transition-colors">Security</a>
        </div>
      </footer>
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
