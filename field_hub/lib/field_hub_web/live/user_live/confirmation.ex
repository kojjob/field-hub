defmodule FieldHubWeb.UserLive.Confirmation do
  use FieldHubWeb, :live_view

  alias FieldHub.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-100 font-dashboard flex items-center justify-center p-6">
      <div class="w-full max-w-md bg-white rounded-3xl shadow-xl shadow-slate-200/50 p-8 lg:p-12 space-y-8">
        <div class="text-center space-y-4">
          <div class="mx-auto size-12 bg-primary/10 rounded-2xl flex items-center justify-center text-primary mb-6">
            <.icon name="hero-envelope-open" class="size-6" />
          </div>
          <h1 class="text-2xl font-black text-slate-900 tracking-tight">
            Confirm Your Magic Link
          </h1>
          <p class="text-slate-500 font-medium">
            Welcome back, <span class="text-slate-900 font-bold">{@user.email}</span>. Click below to securely sign in to your FieldHub account.
          </p>
        </div>

        <.form
          :if={!@user.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-mounted={JS.focus_first()}
          phx-submit="submit"
          action={~p"/users/log-in?_action=confirmed"}
          phx-trigger-action={@trigger_submit}
          class="space-y-4"
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with="Confirming..."
            class="w-full bg-primary text-white py-4 rounded-xl text-sm font-bold shadow-lg shadow-primary/20 hover:brightness-110 transition-all active:scale-[0.99]"
          >
            Confirm and stay logged in
          </.button>
          <.button
            phx-disable-with="Confirming..."
            class="w-full py-4 rounded-xl text-sm font-bold text-slate-600 hover:bg-slate-50 transition-all border border-slate-200"
          >
            Confirm and log in only this time
          </.button>
        </.form>

        <.form
          :if={@user.confirmed_at}
          for={@form}
          id="login_form"
          phx-submit="submit"
          phx-mounted={JS.focus_first()}
          action={~p"/users/log-in"}
          phx-trigger-action={@trigger_submit}
          class="space-y-4"
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <%= if @current_scope && @current_scope.user do %>
            <.button
              phx-disable-with="Logging in..."
              class="w-full bg-primary text-white py-4 rounded-xl text-sm font-bold shadow-lg shadow-primary/20 hover:brightness-110 transition-all active:scale-[0.99]"
            >
              Log in to FieldHub
            </.button>
          <% else %>
            <.button
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Logging in..."
              class="w-full bg-primary text-white py-4 rounded-xl text-sm font-bold shadow-lg shadow-primary/20 hover:brightness-110 transition-all active:scale-[0.99]"
            >
              Keep me logged in on this device
            </.button>
            <.button
              phx-disable-with="Logging in..."
              class="w-full py-4 rounded-xl text-sm font-bold text-slate-600 hover:bg-slate-50 transition-all border border-slate-200"
            >
              Log me in only this time
            </.button>
          <% end %>
        </.form>

        <div :if={!@user.confirmed_at} class="bg-amber-50 rounded-xl p-4 border border-amber-100">
          <div class="flex gap-3">
            <.icon name="hero-light-bulb" class="size-5 text-amber-600 shrink-0" />
            <p class="text-[13px] text-amber-900 font-medium leading-tight">
              Tip: You can enable password sign-in later in your account settings if you prefer.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token} = params, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")
      auto_submit = Map.get(params, "auto") == "true"

      {:ok, assign(socket, user: user, form: form, trigger_submit: auto_submit),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
