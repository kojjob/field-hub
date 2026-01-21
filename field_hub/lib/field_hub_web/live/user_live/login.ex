defmodule FieldHubWeb.UserLive.Login do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-100 font-dashboard">
      <!-- Header -->
      <header class="fixed top-0 left-0 right-0 bg-white/80 backdrop-blur-sm border-b border-slate-200 z-50">
        <div class="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <.link navigate={~p"/"} class="flex items-center gap-2.5">
            <div class="size-9 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-primary/20">
              <.icon name="hero-command-line" class="size-5" />
            </div>
            <span class="text-xl font-black tracking-tight text-slate-900">FieldHub</span>
          </.link>
          <a
            href="mailto:admin@fieldhub.app"
            class="px-4 py-2 text-sm font-bold text-primary border border-primary/30 rounded-lg hover:bg-primary/5 transition-all"
          >
            Contact Admin
          </a>
        </div>
      </header>
      
    <!-- Main Content -->
      <div class="pt-20 min-h-screen flex">
        <!-- Left Side: Form -->
        <div class="w-full lg:w-[45%] flex items-center justify-center p-8 lg:p-16 bg-white">
          <div class="w-full max-w-md space-y-8">
            <div class="space-y-2">
              <h1 class="text-3xl font-black text-slate-900 tracking-tight">
                Welcome back
              </h1>
              <p class="text-slate-500 font-medium">
                Please enter your details to sign in.
              </p>
            </div>

            <%!-- Error Alert Banner --%>
            <div
              :if={@error_message}
              id="login-error-banner"
              class="bg-red-50 border border-red-200 rounded-xl p-4 flex items-start gap-3 animate-shake"
              role="alert"
            >
              <div class="shrink-0">
                <.icon name="hero-exclamation-triangle" class="size-5 text-red-500" />
              </div>
              <div>
                <h3 class="text-sm font-bold text-red-800">Login Failed</h3>
                <p class="text-sm text-red-700 mt-0.5">{@error_message}</p>
              </div>
              <button
                type="button"
                phx-click="dismiss_error"
                class="ml-auto shrink-0 text-red-400 hover:text-red-600"
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>
            </div>

            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-5"
            >
              <div class="space-y-1.5">
                <label class="text-sm font-semibold text-slate-700">
                  Email Address
                </label>
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  placeholder="e.g. john@servicepro.com"
                  required
                  phx-debounce="300"
                  class={"w-full !bg-white !text-slate-900 border !rounded-lg !h-12 !px-4 focus:!ring-2 focus:!ring-primary/20 focus:!border-primary transition-all placeholder:text-slate-400 #{if @error_message, do: "!border-red-300 !ring-red-100", else: "border-slate-200"}"}
                />
              </div>

              <div class="space-y-1.5">
                <div class="flex items-center justify-between">
                  <label class="text-sm font-semibold text-slate-700">
                    Password
                  </label>
                  <.link
                    navigate={~p"/users/forgot-password"}
                    class="text-sm font-semibold text-primary hover:underline"
                  >
                    Forgot password?
                  </.link>
                </div>
                <div class="relative" id="password-field-wrapper" phx-hook="PasswordToggle">
                  <input
                    type="password"
                    name={f[:password].name}
                    id="password-input"
                    placeholder="Enter your password"
                    required
                    class={"w-full bg-white text-slate-900 border rounded-lg h-12 px-4 pr-12 focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none transition-all placeholder:text-slate-400 #{if @error_message, do: "border-red-300 ring-1 ring-red-100", else: "border-slate-300"}"}
                  />
                  <button
                    type="button"
                    id="password-toggle-btn"
                    class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                  >
                    <span id="eye-open"><.icon name="hero-eye" class="size-5" /></span>
                    <span id="eye-closed" class="hidden">
                      <.icon name="hero-eye-slash" class="size-5" />
                    </span>
                  </button>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <input
                  type="checkbox"
                  id="remember_me"
                  name={f[:remember_me].name}
                  class="size-4 rounded border-slate-300 text-primary focus:ring-primary/20"
                />
                <label for="remember_me" class="text-sm text-slate-600">
                  Remember me
                </label>
              </div>

              <button
                type="submit"
                class="w-full bg-primary text-white py-3.5 rounded-lg text-sm font-bold shadow-lg shadow-primary/20 hover:brightness-110 transition-all active:scale-[0.99]"
              >
                Sign In
              </button>
            </.form>

            <div class="text-center">
              <p class="text-slate-500 text-sm">
                Don't have an account?
                <.link
                  navigate={~p"/users/register"}
                  class="text-primary font-semibold hover:underline"
                >
                  Create account
                </.link>
              </p>
            </div>
          </div>
        </div>
        
    <!-- Right Side: Product Preview -->
        <div class="hidden lg:flex lg:w-[55%] bg-slate-100 items-center justify-center p-16">
          <div class="relative max-w-lg">
            <!-- App Preview Card -->
            <div class="bg-white rounded-3xl shadow-2xl shadow-slate-200/50 p-6 space-y-4">
              <!-- Status Badge -->
              <div class="flex justify-end">
                <div class="inline-flex items-center gap-2 bg-primary/10 text-primary px-3 py-1.5 rounded-full text-xs font-bold">
                  <div class="size-2 bg-primary rounded-full"></div>
                  Job Completed
                </div>
              </div>
              
    <!-- Mock App Interface -->
              <div class="bg-slate-50 rounded-2xl p-5 border border-slate-100">
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-lg font-bold text-slate-900">Field Service eFleets</h3>
                  <div class="flex gap-1">
                    <div class="size-2 rounded-full bg-slate-300"></div>
                    <div class="size-2 rounded-full bg-slate-300"></div>
                    <div class="size-2 rounded-full bg-slate-300"></div>
                  </div>
                </div>
                <div class="space-y-3">
                  <div class="flex gap-3">
                    <div class="h-10 w-1/3 bg-slate-200 rounded-lg"></div>
                    <div class="h-10 flex-1 bg-primary/20 rounded-lg"></div>
                  </div>
                  <div class="grid grid-cols-3 gap-2">
                    <div class="h-16 bg-slate-100 rounded-lg border border-slate-200"></div>
                    <div class="h-16 bg-slate-100 rounded-lg border border-slate-200"></div>
                    <div class="h-16 bg-primary/10 rounded-lg border border-primary/20"></div>
                  </div>
                </div>
              </div>
              
    <!-- Technician Info -->
              <div class="flex items-center gap-3 pt-2">
                <img
                  src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face"
                  class="size-10 rounded-full object-cover"
                  alt="Technician"
                />
                <div>
                  <p class="text-xs text-slate-500">Technician</p>
                  <p class="font-bold text-slate-900 text-sm">Alex Johnson</p>
                </div>
              </div>
            </div>
            
    <!-- Tagline -->
            <div class="text-center mt-8 space-y-2">
              <h2 class="text-2xl font-black text-slate-900 tracking-tight">
                Service Management Simplified
              </h2>
              <p class="text-slate-500 text-sm max-w-sm mx-auto">
                Real-time scheduling, dispatching, and invoicing for your entire fleet in one powerful hub.
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Footer -->
      <footer class="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 py-3 px-6">
        <div class="max-w-7xl mx-auto flex items-center justify-between text-xs text-slate-400">
          <span>© {DateTime.utc_now().year} FieldHub Inc. All rights reserved.</span>
          <div class="flex gap-6">
            <a href="#" class="hover:text-slate-600">Privacy Policy</a>
            <a href="#" class="hover:text-slate-600">Terms of Service</a>
            <a href="#" class="hover:text-slate-600">Security</a>
          </div>
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

    # Only read flash error once we're connected (prevents double-mount clearing issue)
    error_message =
      if connected?(socket) do
        Phoenix.Flash.get(socket.assigns.flash, :error)
      else
        nil
      end

    {:ok,
     socket
     |> assign(form: form, trigger_submit: false, show_password: false)
     |> assign(error_message: error_message)
     |> then(fn s -> if connected?(socket), do: clear_flash(s, :error), else: s end)}
  end

  @impl true
  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, :show_password, !socket.assigns.show_password)}
  end

  @impl true
  def handle_event("dismiss_error", _params, socket) do
    {:noreply, assign(socket, :error_message, nil)}
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
