defmodule FieldHubWeb.PortalLive.Dashboard do
  @moduledoc """
  Customer portal dashboard showing active jobs and service history.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Repo
  alias FieldHub.Jobs
  alias FieldHub.CRM
  alias FieldHub.Billing
  alias FieldHub.Config.Terminology

  @impl true
  def mount(_params, _session, socket) do
    customer = socket.assigns.portal_customer

    if connected?(socket) do
      Phoenix.PubSub.subscribe(FieldHub.PubSub, "customer:#{customer.id}")
    end

    active_jobs = Jobs.list_active_jobs_for_customer(customer.id)
    completed_jobs = Jobs.list_completed_jobs_for_customer(customer.id, limit: 5)
    unpaid_invoices = list_unpaid_invoices(customer.id)

    # New: Fetch total lifetime stats
    {lifetime_invoiced, total_service_count, avg_completion_days, trust_score} =
      fetch_lifetime_stats(customer.id)

    # New: Fetch terminology
    terminology = Terminology.get_terminology(customer.organization)

    changeset = CRM.change_customer(customer)

    socket =
      socket
      |> assign(:customer, customer)
      |> assign(:active_jobs, active_jobs)
      |> assign(:completed_jobs, completed_jobs)
      |> assign(:unpaid_invoices, unpaid_invoices)
      |> assign(:lifetime_invoiced, lifetime_invoiced)
      |> assign(:total_service_count, total_service_count)
      |> assign(:avg_completion_days, avg_completion_days)
      |> assign(:trust_score, trust_score)
      |> assign(:terminology, terminology)
      |> assign(:page_title, "Dashboard")
      |> assign(:form, to_form(changeset))
      |> assign(:show_preferences_modal, false)

    {:ok, socket}
  end

  @impl true
  def handle_info({:job_updated, _job}, socket) do
    customer = socket.assigns.customer
    active_jobs = Jobs.list_active_jobs_for_customer(customer.id)
    completed_jobs = Jobs.list_completed_jobs_for_customer(customer.id, limit: 5)

    {:noreply,
     socket
     |> assign(:active_jobs, active_jobs)
     |> assign(:completed_jobs, completed_jobs)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("validate_preferences", %{"customer" => customer_params}, socket) do
    changeset =
      socket.assigns.customer
      |> CRM.change_customer(customer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save_preferences", %{"customer" => customer_params}, socket) do
    case CRM.update_customer(socket.assigns.customer, customer_params) do
      {:ok, updated_customer} ->
        socket =
          socket
          |> assign(:customer, updated_customer)
          |> assign(:form, to_form(CRM.change_customer(updated_customer)))
          |> put_flash(:info, "Preferences saved successfully")
          |> push_event("close_modal", %{to: "#preferences-modal"})

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset), show_preferences_modal: true)}
    end
  end

  def handle_event("show_toast", %{"message" => message, "type" => type}, socket) do
    {:noreply, put_flash(socket, String.to_atom(type), message)}
  end

  @impl true
  def render(assigns) do
    ~H"""
  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950">
      <main class="max-w-6xl mx-auto px-4 sm:px-6 py-12">
        <!-- Hero Greetings -->
        <div class="mb-12">
          <p class="text-sm font-medium text-zinc-500 dark:text-zinc-400 mb-1">
            {Calendar.strftime(Date.utc_today(), "%A, %B %d, %Y")}
          </p>
          <h1 class="text-3xl sm:text-4xl font-black text-zinc-900 dark:text-white tracking-tight">
            Welcome back, {@customer.name}
          </h1>
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-12 gap-12">
          <!-- Main Content Column (Left) -->
          <div class="xl:col-span-8 space-y-12">

            <!-- KPI Summary Row -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
               <.kpi_widget
                label="Trust Score"
                value={"#{@trust_score}%"}
                subtext="Reliability"
                icon="hero-shield-check"
                color="emerald"
              />
              <.kpi_widget
                label="Avg Service"
                value={"#{@avg_completion_days}d"}
                subtext="Turnaround"
                icon="hero-clock"
                color="blue"
              />
              <.kpi_widget
                label="Total Visits"
                value={to_string(@total_service_count)}
                subtext="Lifetime"
                icon="hero-clipboard-document-check"
                color="zinc"
              />
              <.kpi_widget
                label="Lifetime Value"
                value={"#{currency_symbol(@customer.organization.currency)}#{format_money(@lifetime_invoiced)}"}
                subtext="Invoiced"
                icon="hero-banknotes"
                color="zinc"
              />
            </div>

            <!-- Active Jobs Section -->
            <section>
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-xl font-bold text-zinc-900 dark:text-white tracking-tight flex items-center gap-2">
                  <.icon name="hero-bolt" class="size-5 text-zinc-400" />
                  Active {@terminology["task_label_plural"]}
                </h2>
              </div>

              <%= if Enum.empty?(@active_jobs) do %>
                <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-12 text-center shadow-sm">
                  <div class="size-16 mx-auto mb-4 rounded-full bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center">
                    <.icon name="hero-check" class="size-8 text-zinc-300 dark:text-zinc-600" />
                  </div>
                  <h3 class="text-base font-bold text-zinc-900 dark:text-white mb-1">
                    All caught up
                  </h3>
                  <p class="text-sm text-zinc-500 font-medium">
                    No active services scheduled at the moment.
                  </p>
                </div>
              <% else %>
                <div class="space-y-4">
                  <%= for job <- @active_jobs do %>
                    <.link
                      navigate={~p"/portal/jobs/#{job}"}
                      class="block bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6 hover:border-primary/50 transition-colors shadow-sm group hover:shadow-md"
                    >
                      <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
                        <div>
                          <div class="flex items-center gap-2 mb-2">
                            <span class={[
                              "px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider border",
                              status_color_theme(job.status)
                            ]}>
                              {String.replace(job.status, "_", " ")}
                            </span>
                            <span class="text-xs text-zinc-400 font-medium">#{job.number}</span>
                          </div>
                          <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2 group-hover:text-primary transition-colors">
                            {job.title}
                          </h3>
                        </div>
                        <div class="sm:text-right">
                          <div class="flex items-center sm:justify-end gap-2 text-zinc-600 dark:text-zinc-400 mb-1">
                            <.icon name="hero-calendar" class="size-4" />
                            <span class="text-sm font-bold">{format_date(job.scheduled_date)}</span>
                          </div>
                           <%= if job.technician do %>
                            <div class="flex items-center sm:justify-end gap-2 text-xs text-zinc-500">
                              <span class="font-medium text-zinc-400">{@terminology["worker_label"]}:</span>
                              {job.technician.name}
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </.link>
                  <% end %>
                </div>
              <% end %>
            </section>

            <!-- Recent History (Compact) -->
            <section>
              <div class="flex items-center justify-between mb-6">
                <h2 class="text-xl font-bold text-zinc-900 dark:text-white tracking-tight flex items-center gap-2">
                  <.icon name="hero-clock" class="size-5 text-zinc-400" />
                  Recent History
                </h2>
                <.link
                  navigate={~p"/portal/history"}
                  class="text-xs font-bold text-primary hover:text-primary/80 transition-colors flex items-center gap-1"
                >
                  View All <.icon name="hero-arrow-right" class="size-3" />
                </.link>
              </div>

              <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden shadow-sm">
                <table class="w-full text-left">
                  <thead class="bg-zinc-50/50 dark:bg-zinc-800/30 border-b border-zinc-100 dark:border-zinc-800">
                    <tr>
                      <th class="px-6 py-4 text-[10px] font-black text-zinc-400 uppercase tracking-widest">Service</th>
                      <th class="px-6 py-4 text-[10px] font-black text-zinc-400 uppercase tracking-widest text-right">Date</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-zinc-50 dark:divide-zinc-800/50">
                    <%= for job <- @completed_jobs do %>
                      <tr class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/30 transition-colors cursor-pointer" phx-click={JS.navigate(~p"/portal/jobs/#{job}")}>
                        <td class="px-6 py-4">
                          <p class="text-sm font-bold text-zinc-900 dark:text-white mb-0.5">{job.title}</p>
                          <p class="text-[10px] text-zinc-400">#{job.number}</p>
                        </td>
                        <td class="px-6 py-4 text-right">
                          <p class="text-xs font-medium text-zinc-600 dark:text-zinc-400">
                            {format_date(job.completed_at)}
                          </p>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </section>
          </div>

          <!-- Sidebar (Right) -->
          <aside class="xl:col-span-4 space-y-10">
            <!-- Action Card: Invoices -->
             <%= if length(@unpaid_invoices) > 0 do %>
              <div class="bg-gradient-to-br from-amber-50 to-orange-50 dark:from-amber-950/30 dark:to-orange-950/30 rounded-3xl border border-amber-100 dark:border-amber-900/50 p-6">
                <div class="flex items-center gap-3 mb-4">
                  <div class="size-10 rounded-xl bg-amber-500/10 flex items-center justify-center text-amber-600 dark:text-amber-400">
                    <.icon name="hero-exclamation-circle" class="size-6" />
                  </div>
                  <h3 class="text-lg font-bold text-amber-900 dark:text-amber-100">Action Required</h3>
                </div>

                <p class="text-sm text-amber-800/80 dark:text-amber-200/60 font-medium mb-6">
                  You have <strong>{length(@unpaid_invoices)} unpaid invoices</strong>. Please settle your balance to avoid service interruptions.
                </p>

                <div class="space-y-3">
                  <%= for invoice <- @unpaid_invoices do %>
                    <div class="bg-white/60 dark:bg-zinc-900/60 rounded-xl p-3 flex items-center justify-between border border-amber-200/50 dark:border-amber-900/30">
                       <span class="text-xs font-bold text-zinc-700 dark:text-zinc-300">#{invoice.number}</span>
                       <span class="text-sm font-black text-amber-600 dark:text-amber-500">{currency_symbol(@customer.organization.currency)}{format_money(invoice.total_amount)}</span>
                    </div>
                  <% end %>
                </div>

                <.link
                  navigate={~p"/portal/invoices"}
                  class="mt-6 w-full flex items-center justify-center gap-2 py-3 bg-amber-500 hover:bg-amber-600 text-white text-sm font-bold rounded-xl shadow-lg shadow-amber-500/20 transition-all"
                >
                  Pay Now <.icon name="hero-arrow-right" class="size-4" />
                </.link>
              </div>
            <% end %>

            <!-- Quick Attributes -->
            <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6">
              <h3 class="text-sm font-bold text-zinc-900 dark:text-white mb-6 uppercase tracking-wider">Settings</h3>

              <button
                type="button"
                phx-click={show_modal("preferences-modal")}
                class="w-full flex items-center justify-between p-3 rounded-xl hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors group"
              >
                <div class="flex items-center gap-3">
                  <div class="size-8 rounded-lg bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center text-zinc-500 group-hover:text-zinc-900 dark:group-hover:text-white transition-colors">
                    <.icon name="hero-bell" class="size-4" />
                  </div>
                  <div class="text-left">
                    <p class="text-sm font-bold text-zinc-900 dark:text-white">Notifications</p>
                    <p class="text-xs text-zinc-500">Email & SMS preferences</p>
                  </div>
                </div>
                <.icon name="hero-chevron-right" class="size-4 text-zinc-400 group-hover:translate-x-1 transition-transform" />
              </button>

              <div class="mt-4 pt-4 border-t border-zinc-100 dark:border-zinc-800">
                <p class="text-[10px] font-medium text-zinc-400 text-center">
                  Account ID: <span class="font-mono">{@customer.id |> to_string() |> String.slice(0, 8)}</span>
                </p>
              </div>
            </div>
          </aside>
        </div>
      </main>
    </div>

    <.modal id="preferences-modal">
      <div class="sm:max-w-lg w-full">
        <div class="mb-6">
          <div class="flex items-center gap-3 mb-2">
            <div class="size-10 rounded-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
              <.icon name="hero-bell" class="size-5 text-zinc-900 dark:text-white" />
            </div>
            <h3 class="text-xl font-bold text-zinc-900 dark:text-white">Notification Settings</h3>
          </div>
          <p class="text-sm text-zinc-500">
            Fine-tune how you receive updates from {@customer.organization.name}.
          </p>
        </div>

        <.form
          for={@form}
          phx-change="validate_preferences"
          phx-submit="save_preferences"
          class="space-y-6"
        >
          <.inputs_for :let={pref} field={@form[:preferences]}>
            <div class="divide-y divide-zinc-100 dark:divide-zinc-800 border border-zinc-100 dark:border-zinc-800 rounded-2xl bg-zinc-50/50 dark:bg-zinc-900/50 overflow-hidden">
              <!-- Job Scheduling -->
              <div class="p-4 grid grid-cols-12 gap-4 items-center hover:bg-white dark:hover:bg-zinc-800 transition-colors">
                <div class="col-span-8">
                  <p class="text-sm font-bold text-zinc-900 dark:text-white">Service Scheduled</p>
                  <p class="text-xs text-zinc-500">When an appointment is confirmed</p>
                </div>
                <div class="col-span-2 text-center">
                  <span class="text-[10px] font-bold text-zinc-400 uppercase block mb-1">Email</span>
                  <.input field={pref[:job_scheduled_email]} type="switch" />
                </div>
                <div class="col-span-2 text-center">
                  <span class="text-[10px] font-bold text-zinc-400 uppercase block mb-1">SMS</span>
                  <.input field={pref[:job_scheduled_sms]} type="switch" />
                </div>
              </div>

    <!-- Tech En Route -->
              <div class="p-4 grid grid-cols-12 gap-4 items-center hover:bg-white dark:hover:bg-zinc-800 transition-colors">
                <div class="col-span-8">
                  <p class="text-sm font-bold text-zinc-900 dark:text-white">Technician En Route</p>
                  <p class="text-xs text-zinc-500">When your technician is on the way</p>
                </div>
                <div class="col-span-2 text-center">
                  <.input field={pref[:technician_en_route_email]} type="switch" />
                </div>
                <div class="col-span-2 text-center">
                  <.input field={pref[:technician_en_route_sms]} type="switch" />
                </div>
              </div>

    <!-- Tech Arrived -->
              <div class="p-4 grid grid-cols-12 gap-4 items-center hover:bg-white dark:hover:bg-zinc-800 transition-colors">
                <div class="col-span-8">
                  <p class="text-sm font-bold text-zinc-900 dark:text-white">Technician Arrived</p>
                  <p class="text-xs text-zinc-500">When the technician is at your property</p>
                </div>
                <div class="col-span-2 text-center">
                  <.input field={pref[:technician_arrived_email]} type="switch" />
                </div>
                <div class="col-span-2 text-center">
                  <.input field={pref[:technician_arrived_sms]} type="switch" />
                </div>
              </div>

    <!-- Completed -->
              <div class="p-4 grid grid-cols-12 gap-4 items-center hover:bg-white dark:hover:bg-zinc-800 transition-colors">
                <div class="col-span-8">
                  <p class="text-sm font-bold text-zinc-900 dark:text-white">Service Completed</p>
                  <p class="text-xs text-zinc-500">Completion reports and details</p>
                </div>
                <div class="col-span-2 text-center">
                  <.input field={pref[:job_completed_email]} type="switch" />
                </div>
                <div class="col-span-2 text-center">
                  <.input field={pref[:job_completed_sms]} type="switch" />
                </div>
              </div>
            </div>

            <div class="mt-6 flex flex-col gap-3">
              <div class="flex items-center justify-between p-4 bg-zinc-50/50 dark:bg-zinc-900/50 rounded-xl border border-zinc-100 dark:border-zinc-800">
                <div>
                  <p class="text-sm font-bold text-zinc-900 dark:text-white">Financial Updates</p>
                  <p class="text-xs text-zinc-500">Receive invoices and receipts via email</p>
                </div>
                <.input field={pref[:invoice_email]} type="switch" />
              </div>

              <div class="flex items-center justify-between p-4 bg-zinc-50/50 dark:bg-zinc-900/50 rounded-xl border border-zinc-100 dark:border-zinc-800">
                <div>
                  <p class="text-sm font-bold text-zinc-900 dark:text-white">News & Tips</p>
                  <p class="text-xs text-zinc-500">Occasional updates and maintenance tips</p>
                </div>
                <.input field={pref[:marketing_email]} type="switch" />
              </div>
            </div>
          </.inputs_for>

          <div class="flex items-center justify-end gap-3 pt-6 border-t border-zinc-100 dark:border-zinc-800">
            <button
              type="button"
              phx-click={hide_modal("preferences-modal")}
              class="px-4 py-2 rounded-xl text-sm font-bold text-zinc-500 hover:text-zinc-900 dark:hover:text-white transition-colors"
            >
              Cancel
            </button>
            <.button
              type="submit"
              class="bg-primary hover:bg-primary/90 text-white rounded-xl px-4 py-2 text-sm font-bold shadow-lg shadow-primary/20"
            >
              Save Changes
            </.button>
          </div>
        </.form>
      </div>
    </.modal>
    """
  end

  defp kpi_widget(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 p-6 flex items-start gap-4 hover:border-zinc-400 dark:hover:border-zinc-600 transition-colors shadow-sm relative overflow-hidden group">
      <div class={[
        "size-12 rounded-2xl flex items-center justify-center shrink-0 shadow-inner transition-transform group-hover:scale-110",
        @color == "emerald" && "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400",
        @color == "primary" && "bg-primary/10 text-primary",
        @color == "amber" && "bg-amber-500/10 text-amber-600 dark:text-amber-400",
        @color == "teal" && "bg-teal-500/10 text-teal-600 dark:text-teal-400"
      ]}>
        <.icon name={@icon} class="size-6" />
      </div>
      <div>
        <p class="text-[10px] font-black text-zinc-400 uppercase tracking-[0.15em] mb-1">{@label}</p>
        <p class="text-2xl font-black text-zinc-900 dark:text-white leading-none tracking-tight mb-1">
          {@value}
        </p>
        <p class="text-[10px] text-zinc-500 font-medium">{@subtext}</p>
      </div>
    </div>
    """
  end

  defp status_color_theme("pending"),
    do:
      "bg-zinc-50 text-zinc-500 border-zinc-100 dark:bg-zinc-800/50 dark:text-zinc-400 dark:border-zinc-700"

  defp status_color_theme("en_route"),
    do:
      "bg-blue-50 text-blue-600 border-blue-100 dark:bg-blue-500/10 dark:text-blue-400 dark:border-blue-500/20"

  defp status_color_theme("arrived"),
    do:
      "bg-indigo-50 text-indigo-600 border-indigo-100 dark:bg-indigo-500/10 dark:text-indigo-400 dark:border-indigo-500/20"

  defp status_color_theme("in_progress"),
    do:
      "bg-emerald-50 text-emerald-600 border-emerald-100 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/20"

  defp status_color_theme("completed"),
    do:
      "bg-teal-50 text-teal-600 border-teal-100 dark:bg-teal-500/10 dark:text-teal-400 dark:border-teal-500/20"

  defp status_color_theme(_),
    do: "bg-zinc-50 text-zinc-500 border-zinc-100"

  defp list_unpaid_invoices(customer_id) do
    import Ecto.Query

    Billing.Invoice
    |> Billing.Invoice.for_customer(customer_id)
    |> where([i], i.status in ["sent", "viewed", "overdue"])
    |> order_by([i], desc: i.inserted_at)
    |> limit(5)
    |> Repo.all()
  end

  defp fetch_lifetime_stats(customer_id) do
    import Ecto.Query

    # Calculate total invoiced (paid + sent + overdue)
    lifetime_query =
      Billing.Invoice
      |> Billing.Invoice.for_customer(customer_id)
      |> where([i], i.status != "cancelled")
      |> select([i], coalesce(sum(i.total_amount), 0))

    lifetime_total = Repo.one(lifetime_query)

    # Calculate total service history count
    history_count =
      Jobs.Job
      |> where([j], j.customer_id == ^customer_id)
      |> where([j], j.status == "completed")
      |> Repo.aggregate(:count, :id)

    # Calculate average completion time in days
    avg_completion_query =
      from j in Jobs.Job,
        where:
          j.customer_id == ^customer_id and j.status == "completed" and not is_nil(j.completed_at),
        select:
          fragment(
            "ROUND(AVG(EXTRACT(EPOCH FROM (? - ?)) / 86400)::numeric, 1)",
            j.completed_at,
            j.inserted_at
          )

    avg_completion_days = Repo.one(avg_completion_query) || 0.0

    # Calculate Trust Score (Reliability)
    # Based on completion rate of non-cancelled jobs
    total_non_cancelled =
      from(j in Jobs.Job,
        where: j.customer_id == ^customer_id and j.status != "cancelled",
        select: count(j.id)
      )
      |> Repo.one()

    trust_score =
      if total_non_cancelled > 0 do
        round(history_count / total_non_cancelled * 100)
      else
        100
      end

    {lifetime_total, history_count, avg_completion_days, trust_score}
  end

  defp format_money(nil), do: "0.00"

  defp format_money(%Decimal{} = amount) do
    amount
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
  end

  defp format_money(amount) when is_number(amount),
    do: :erlang.float_to_binary(amount / 1, decimals: 2)

  defp format_money(_), do: "0.00"
  defp format_date(nil), do: "N/A"
  defp format_date(%Date{} = d), do: Calendar.strftime(d, "%b %d, %Y")
  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y")
  defp format_date(_), do: "N/A"

  # Currency symbol mapping based on ISO 4217 currency codes
  defp currency_symbol("USD"), do: "$"
  defp currency_symbol("EUR"), do: "€"
  defp currency_symbol("GBP"), do: "£"
  defp currency_symbol("JPY"), do: "¥"
  defp currency_symbol("CNY"), do: "¥"
  defp currency_symbol("KRW"), do: "₩"
  defp currency_symbol("INR"), do: "₹"
  defp currency_symbol("BRL"), do: "R$"
  defp currency_symbol("CAD"), do: "C$"
  defp currency_symbol("AUD"), do: "A$"
  defp currency_symbol("NGN"), do: "₦"
  defp currency_symbol("GHS"), do: "₵"
  defp currency_symbol("KES"), do: "KSh"
  defp currency_symbol("ZAR"), do: "R"
  defp currency_symbol(_), do: "$"
end
