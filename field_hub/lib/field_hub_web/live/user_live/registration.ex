defmodule FieldHubWeb.UserLive.Registration do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts
  alias FieldHub.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-white dark:bg-zinc-950 flex flex-col lg:flex-row font-dashboard overflow-hidden">
      <!-- Left Side: Visual / Quote -->
      <div class="lg:w-1/2 relative hidden lg:flex flex-col justify-end p-20 overflow-hidden">
        <div class="absolute inset-0 z-0">
          <img src="/images/registration_bg.png" class="w-full h-full object-cover scale-105" alt="Technician working" />
          <div class="absolute inset-0 bg-gradient-to-t from-fsm-primary/90 via-fsm-primary/40 to-transparent"></div>
        </div>

        <div class="relative z-10 space-y-6 animate-in">
          <div class="flex items-center gap-3 mb-10">
            <div class="size-10 bg-white rounded-xl flex items-center justify-center text-fsm-primary shadow-xl">
              <span class="material-symbols-outlined notranslate text-2xl">grid_view</span>
            </div>
            <span class="text-2xl font-black tracking-tighter text-white">FieldHub</span>
          </div>

          <p class="text-4xl font-black text-white tracking-tight leading-[1.1] font-display">
            "FieldHub transformed how we manage our service fleet."
          </p>
          <p class="text-white/80 font-bold text-lg">
            Join 2,000+ contractors scaling their business today.
          </p>
        </div>
      </div>

      <!-- Right Side: Registration Form -->
      <div class="lg:w-1/2 flex flex-col items-center justify-center px-6 py-12 lg:px-24 overflow-y-auto bg-[#F8FAFB] dark:bg-zinc-950">
        <div class="max-w-md w-full space-y-10 animate-fade">
          <div class="lg:hidden flex items-center gap-3 mb-8">
            <div class="size-10 bg-fsm-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-fsm-primary/20">
              <span class="material-symbols-outlined notranslate text-2xl">grid_view</span>
            </div>
            <span class="text-2xl font-black tracking-tighter text-slate-900 dark:text-white">FieldHub</span>
          </div>

          <div class="space-y-4">
            <h1 class="text-4xl font-black text-slate-900 dark:text-white tracking-tighter font-display">Create Your Account</h1>
            <p class="text-slate-500 dark:text-slate-400 font-medium">Join FieldHub and streamline your service business operations.</p>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <button class="flex items-center justify-center gap-3 px-6 py-4 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-[1.25rem] shadow-sm hover:bg-slate-50 dark:hover:bg-zinc-800/50 transition-all font-black text-sm text-slate-700 dark:text-slate-200">
              <img src="https://www.google.com/favicon.ico" class="size-4" alt="Google" />
              Google
            </button>
            <button class="flex items-center justify-center gap-3 px-6 py-4 bg-white dark:bg-zinc-900 border border-slate-200 dark:border-zinc-800 rounded-[1.25rem] shadow-sm hover:bg-slate-50 dark:hover:bg-zinc-800/50 transition-all font-black text-sm text-slate-700 dark:text-slate-200">
              <span class="material-symbols-outlined notranslate text-lg text-blue-600">grid_view</span>
              Microsoft
            </button>
          </div>

          <div class="relative py-4 flex items-center">
            <div class="flex-grow border-t border-slate-200 dark:border-zinc-800"></div>
            <span class="flex-shrink mx-4 text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">Or sign up with email</span>
            <div class="flex-grow border-t border-slate-200 dark:border-zinc-800"></div>
          </div>

          <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate" class="space-y-5">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div class="space-y-1.5">
                <label class="text-[11px] font-black uppercase tracking-widest text-slate-400 ml-1">Full Name</label>
                <.input
                  field={@form[:name]}
                  placeholder="e.g. Alex Johnson"
                  required
                  class="input input-bordered w-full !bg-white dark:!bg-zinc-900 !border-slate-200 dark:!border-zinc-800 !rounded-2xl !h-14 !pl-5 focus:!ring-2 focus:!ring-fsm-primary/20 focus:!border-fsm-primary transition-all font-bold text-slate-700 dark:text-slate-200"
                />
              </div>
              <div class="space-y-1.5">
                <label class="text-[11px] font-black uppercase tracking-widest text-slate-400 ml-1">Company Name</label>
                <.input
                  field={@form[:company_name]}
                  placeholder="e.g. Apex Plumbing"
                  required
                  class="input input-bordered w-full !bg-white dark:!bg-zinc-900 !border-slate-200 dark:!border-zinc-800 !rounded-2xl !h-14 !pl-5 focus:!ring-2 focus:!ring-fsm-primary/20 focus:!border-fsm-primary transition-all font-bold text-slate-700 dark:text-slate-200 outline-none"
                />
              </div>
            </div>

            <div class="space-y-1.5">
              <label class="text-[11px] font-black uppercase tracking-widest text-slate-400 ml-1">Work Email Address</label>
              <.input
                field={@form[:email]}
                type="email"
                placeholder="work@email.com"
                required
                class="input input-bordered w-full !bg-white dark:!bg-zinc-900 !border-slate-200 dark:!border-zinc-800 !rounded-2xl !h-14 !pl-5 focus:!ring-2 focus:!ring-fsm-primary/20 focus:!border-fsm-primary transition-all font-bold text-slate-700 dark:text-slate-200"
              />
            </div>

            <div class="space-y-1.5">
              <label class="text-[11px] font-black uppercase tracking-widest text-slate-400 ml-1">Password</label>
              <div class="relative group">
                <.input
                  id="reg_password_input"
                  field={@form[:password]}
                  type="password"
                  placeholder="Min. 8 characters"
                  required
                  class="input input-bordered w-full !bg-white dark:!bg-zinc-900 !border-slate-200 dark:!border-zinc-800 !rounded-2xl !h-14 !pl-5 focus:!ring-2 focus:!ring-fsm-primary/20 focus:!border-fsm-primary transition-all font-bold text-slate-700 dark:text-slate-200 pr-12"
                />
                <button
                  type="button"
                  phx-hook="PasswordToggle"
                  id="reg_password_toggle"
                  data-input-id="reg_password_input"
                  class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-fsm-primary transition-colors"
                >
                  <span class="material-symbols-outlined notranslate text-xl icon-vis">visibility</span>
                  <span class="material-symbols-outlined notranslate text-xl icon-hid" style="display: none;">visibility_off</span>
                </button>
              </div>
            </div>

            <div class="flex items-start gap-3 px-1">
              <.input field={@form[:terms_accepted]} type="checkbox" id="terms" class="size-5 mt-0.5 rounded-lg border-slate-200 text-fsm-primary focus:ring-fsm-primary/20" />
              <label for="terms" class="text-sm font-bold text-slate-500 leading-tight">
                I agree to the <a href="#" class="text-fsm-primary hover:underline">Terms of Service</a> and <a href="#" class="text-fsm-primary hover:underline">Privacy Policy</a>.
              </label>
            </div>

            <.button phx-disable-with="Creating account..." class="btn btn-primary w-full !bg-fsm-primary !border-fsm-primary !text-white !py-6 !rounded-[1.25rem] !text-base !font-black !tracking-tight shadow-xl shadow-fsm-primary/20 hover:brightness-110 hover:!bg-fsm-primary hover:!border-fsm-primary transition-all">
              Create Account
            </.button>
          </.form>

          <div class="text-center pt-6">
            <p class="text-sm font-bold text-slate-500">
              Already have an account? <.link navigate={~p"/users/log-in"} class="text-fsm-primary hover:underline">Log in</.link>
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
         |> assign_form(changeset),
         temporary_assigns: [form: nil]}
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
