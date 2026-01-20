defmodule FieldHubWeb.UserLive.Registration do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white font-dashboard flex">
      <!-- Left Side: Photo with Testimonial -->
      <div class="hidden lg:flex lg:w-[50%] relative bg-slate-900 overflow-hidden">
        <!-- Background Image -->
        <img
          src="https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=1200&h=1600&fit=crop"
          class="absolute inset-0 w-full h-full object-cover opacity-80"
          alt="Technician working"
        />
        <!-- Overlay Gradient -->
        <div class="absolute inset-0 bg-gradient-to-t from-slate-900 via-slate-900/40 to-transparent">
        </div>

    <!-- Header Logo -->
        <div class="absolute top-8 left-8 z-10">
          <.link navigate={~p"/"} class="flex items-center gap-2.5">
            <div class="size-9 bg-white/20 backdrop-blur-sm rounded-xl flex items-center justify-center text-white">
              <.icon name="hero-command-line" class="size-5" />
            </div>
            <span class="text-xl font-black tracking-tight text-white">FieldHub</span>
          </.link>
        </div>

    <!-- Testimonial -->
        <div class="absolute bottom-0 left-0 right-0 p-10 z-10">
          <blockquote class="space-y-4">
            <p class="text-2xl font-bold text-white leading-relaxed">
              "FieldHub transformed how we manage our service fleet."
            </p>
            <p class="text-slate-300 text-sm">
              Join 2,000+ contractors scaling their business today.
            </p>
          </blockquote>
        </div>
      </div>

    <!-- Right Side: Form -->
      <div class="flex-1 flex flex-col overflow-y-auto">
        <!-- Mobile Header -->
        <div class="lg:hidden bg-white border-b border-slate-200 px-6 py-4">
          <.link navigate={~p"/"} class="flex items-center gap-2.5">
            <div class="size-9 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-primary/20">
              <.icon name="hero-command-line" class="size-5" />
            </div>
            <span class="text-xl font-black tracking-tight text-slate-900">FieldHub</span>
          </.link>
        </div>

        <div class="flex-1 flex items-center justify-center p-8 lg:p-12">
          <div class="w-full max-w-md space-y-8">
            <div class="space-y-2">
              <h1 class="text-3xl font-black text-slate-900 tracking-tight">
                Create Your Account
              </h1>
              <p class="text-slate-500">
                Join FieldHub and streamline your service business operations.
              </p>
            </div>

    <!-- Social Login Buttons -->
            <div class="grid grid-cols-2 gap-3">
              <button
                type="button"
                class="flex items-center justify-center gap-2 px-4 py-3 border border-slate-200 rounded-lg hover:bg-slate-50 transition-all font-semibold text-sm text-slate-700"
              >
                <svg class="size-5" viewBox="0 0 24 24">
                  <path
                    fill="#4285F4"
                    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  />
                  <path
                    fill="#34A853"
                    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  />
                  <path
                    fill="#EA4335"
                    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  />
                </svg>
                Google
              </button>
              <button
                type="button"
                class="flex items-center justify-center gap-2 px-4 py-3 border border-slate-200 rounded-lg hover:bg-slate-50 transition-all font-semibold text-sm text-slate-700"
              >
                <svg class="size-5" viewBox="0 0 24 24" fill="#00A4EF">
                  <path d="M11.4 24H0V12.6h11.4V24zM24 24H12.6V12.6H24V24zM11.4 11.4H0V0h11.4v11.4zm12.6 0H12.6V0H24v11.4z" />
                </svg>
                Microsoft
              </button>
            </div>

    <!-- Divider -->
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-slate-200"></div>
              </div>
              <div class="relative flex justify-center text-xs uppercase">
                <span class="bg-white px-4 text-slate-400 font-bold tracking-wider">
                  Or sign up with email
                </span>
              </div>
            </div>

            <%!-- Error Summary Banner --%>
            <div
              :if={@form.errors != [] and @form.source.action}
              id="registration-error-banner"
              class="bg-red-50 border border-red-200 rounded-xl p-4 flex items-start gap-3 animate-shake"
              role="alert"
            >
              <div class="shrink-0">
                <.icon name="hero-exclamation-triangle" class="size-5 text-red-500" />
              </div>
              <div>
                <h3 class="text-sm font-bold text-red-800">Please fix the following:</h3>
                <ul class="text-sm text-red-700 mt-1 list-disc list-inside space-y-0.5">
                  <%= for {field, {msg, _opts}} <- @form.errors do %>
                    <li><%= humanize_field(field) %>: <%= msg %></li>
                  <% end %>
                </ul>
              </div>
            </div>

            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              class="space-y-5"
            >
              <div class="grid grid-cols-2 gap-4">
                <div class="space-y-1.5">
                  <label class="text-sm font-semibold text-slate-700">
                    Full Name
                  </label>
                  <.input
                    field={@form[:name]}
                    placeholder="e.g. Alex Johnson"
                    required
                    class="w-full !bg-white !text-slate-900 border border-slate-300 !rounded-lg !h-12 !px-4 focus:!ring-2 focus:!ring-primary/20 focus:!border-primary transition-all placeholder:text-slate-400"
                  />
                </div>
                <div class="space-y-1.5">
                  <label class="text-sm font-semibold text-slate-700">
                    Company Name
                  </label>
                  <.input
                    field={@form[:company_name]}
                    placeholder="e.g. Apex Plumbing"
                    required
                    class="w-full !bg-white !text-slate-900 border border-slate-300 !rounded-lg !h-12 !px-4 focus:!ring-2 focus:!ring-primary/20 focus:!border-primary transition-all placeholder:text-slate-400"
                  />
                </div>
              </div>

              <div class="space-y-1.5">
                <label class="text-sm font-semibold text-slate-700">
                  Work Email Address
                </label>
                <.input
                  field={@form[:email]}
                  type="email"
                  placeholder="alex@email.com"
                  required
                  class="w-full !bg-white !text-slate-900 border border-slate-300 !rounded-lg !h-12 !px-4 focus:!ring-2 focus:!ring-primary/20 focus:!border-primary transition-all placeholder:text-slate-400"
                />
              </div>

              <div class="space-y-1.5">
                <label class="text-sm font-semibold text-slate-700">
                  Password
                </label>
                <div class="relative" id="reg-password-field-wrapper" phx-hook="PasswordToggle" phx-update="ignore">
                  <input
                    type="password"
                    name={@form[:password].name}
                    id="reg-password-input"
                    placeholder="Min. 12 characters"
                    class="w-full bg-white text-slate-900 border border-slate-300 rounded-lg h-12 px-4 pr-12 focus:ring-2 focus:ring-primary/20 focus:border-primary focus:outline-none transition-all placeholder:text-slate-400"
                  />
                  <button
                    type="button"
                    class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                  >
                    <span id="eye-open"><.icon name="hero-eye" class="size-5" /></span>
                    <span id="eye-closed" class="hidden">
                      <.icon name="hero-eye-slash" class="size-5" />
                    </span>
                  </button>
                </div>
              </div>

              <div class="flex items-start gap-3">
                <input
                  type="hidden"
                  name={@form[:terms_accepted].name}
                  value="false"
                />
                <input
                  type="checkbox"
                  id="terms_accepted"
                  name={@form[:terms_accepted].name}
                  value="true"
                  checked={Phoenix.HTML.Form.normalize_value("checkbox", @form[:terms_accepted].value)}
                  class="size-4 rounded border-slate-300 text-primary focus:ring-primary/20 mt-0.5"
                />
                <label for="terms_accepted" class="text-sm text-slate-600 leading-tight cursor-pointer">
                  I agree to the
                  <span class="text-primary font-semibold hover:underline">Terms of Service</span>
                  and
                  <span class="text-primary font-semibold hover:underline">Privacy Policy</span>
                </label>
              </div>

              <button
                type="submit"
                class="w-full bg-primary text-white py-3.5 rounded-lg text-sm font-bold shadow-lg shadow-primary/20 hover:brightness-110 transition-all active:scale-[0.99]"
              >
                Create Account
              </button>
            </.form>

            <div class="text-center">
              <p class="text-slate-500 text-sm">
                Already have an account?
                <.link
                  navigate={~p"/users/log-in"}
                  class="text-primary font-semibold hover:underline"
                >
                  Log in
                </.link>
              </p>
            </div>
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
         |> assign(:show_password, false)
         |> assign_form(changeset), temporary_assigns: [form: nil]}
    end
  end

  @impl true
  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, :show_password, !socket.assigns.show_password)}
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

  # Helper to convert field names to user-friendly labels
  defp humanize_field(:email), do: "Email"
  defp humanize_field(:password), do: "Password"
  defp humanize_field(:name), do: "Full name"
  defp humanize_field(:company_name), do: "Company name"
  defp humanize_field(:terms_accepted), do: "Terms"
  defp humanize_field(field), do: Phoenix.Naming.humanize(field)
end
