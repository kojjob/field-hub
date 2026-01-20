defmodule FieldHubWeb.UserLive.ForgotPassword do
  @moduledoc """
  LiveView for the forgot password page.
  Sends a magic link to reset/login when the email exists.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-100 font-dashboard flex items-center justify-center p-8">
      <div class="w-full max-w-md">
        <!-- Card Container -->
        <div class="bg-white rounded-2xl shadow-xl shadow-slate-200/50 p-8 space-y-6">
          <!-- Header -->
          <div class="text-center space-y-2">
            <.link navigate={~p"/"} class="inline-flex items-center gap-2.5 mb-4">
              <div class="size-10 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-primary/20">
                <.icon name="hero-command-line" class="size-6" />
              </div>
              <span class="text-xl font-black tracking-tight text-slate-900">FieldHub</span>
            </.link>

            <h1 class="text-2xl font-black text-slate-900 tracking-tight">
              Reset your password
            </h1>
            <p class="text-slate-500 text-sm">
              Enter your email and we'll send you a secure link to sign in.
            </p>
          </div>
          
    <!-- Success Message -->
          <div
            :if={@email_sent}
            id="success-banner"
            class="bg-emerald-50 border border-emerald-200 rounded-xl p-4 flex items-start gap-3"
            role="alert"
          >
            <div class="shrink-0">
              <.icon name="hero-check-circle" class="size-5 text-emerald-500" />
            </div>
            <div>
              <h3 class="text-sm font-bold text-emerald-800">Check your inbox</h3>
              <p class="text-sm text-emerald-700 mt-0.5">
                If an account exists for <strong>{@submitted_email}</strong>, we've sent login instructions.
              </p>
            </div>
          </div>
          
    <!-- Form -->
          <.form
            :if={!@email_sent}
            for={@form}
            id="forgot_password_form"
            phx-submit="send_reset_link"
            class="space-y-5"
          >
            <div class="space-y-1.5">
              <label class="text-sm font-semibold text-slate-700">
                Email Address
              </label>
              <.input
                field={@form[:email]}
                type="email"
                placeholder="e.g. john@servicepro.com"
                required
                autofocus
                phx-debounce="300"
                class="w-full !bg-white !text-slate-900 border border-slate-200 !rounded-lg !h-12 !px-4 focus:!ring-2 focus:!ring-primary/20 focus:!border-primary transition-all placeholder:text-slate-400"
              />
            </div>

            <button
              type="submit"
              phx-disable-with="Sending..."
              class="w-full bg-primary text-white py-3.5 rounded-lg text-sm font-bold shadow-lg shadow-primary/20 hover:brightness-110 transition-all active:scale-[0.99] flex items-center justify-center gap-2"
            >
              <.icon name="hero-envelope" class="size-4" /> Send Reset Link
            </button>
          </.form>
          
    <!-- Send Another -->
          <div :if={@email_sent} class="space-y-4">
            <button
              type="button"
              phx-click="reset_form"
              class="w-full bg-slate-100 text-slate-700 py-3 rounded-lg text-sm font-semibold hover:bg-slate-200 transition-all"
            >
              Try a different email
            </button>
          </div>
          
    <!-- Back to Login -->
          <div class="text-center pt-2">
            <.link
              navigate={~p"/users/log-in"}
              class="inline-flex items-center gap-1 text-slate-500 text-sm hover:text-primary transition-colors"
            >
              <.icon name="hero-arrow-left" class="size-4" /> Back to login
            </.link>
          </div>
        </div>
        
    <!-- Footer -->
        <p class="text-center text-xs text-slate-400 mt-6">
          Need help?
          <a href="mailto:support@fieldhub.app" class="text-primary hover:underline">
            Contact support
          </a>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"email" => ""}, as: "user")

    {:ok,
     socket
     |> assign(form: form, email_sent: false, submitted_email: nil)
     |> assign(page_title: "Forgot Password")}
  end

  @impl true
  def handle_event("send_reset_link", %{"user" => %{"email" => email}}, socket) do
    # Always show success to prevent email enumeration
    if user = Accounts.get_user_by_email(email) do
      # Generate the URL for the magic link
      url_fun = &url(~p"/users/log-in/#{&1}")

      # In dev mode, log the URL so developers can test
      if Application.get_env(:field_hub, :env) == :dev do
        token = Accounts.generate_magic_link_token(user)
        magic_url = url_fun.(token)

        require Logger

        Logger.info("""

        ========================================
        🔗 PASSWORD RESET LINK (DEV ONLY)
        ========================================
        Email: #{email}
        Link: #{magic_url}
        ========================================
        """)
      end

      Accounts.deliver_login_instructions(user, url_fun)
    end

    {:noreply,
     socket
     |> assign(email_sent: true, submitted_email: email)}
  end

  @impl true
  def handle_event("reset_form", _params, socket) do
    form = to_form(%{"email" => ""}, as: "user")

    {:noreply,
     socket
     |> assign(form: form, email_sent: false, submitted_email: nil)}
  end
end
