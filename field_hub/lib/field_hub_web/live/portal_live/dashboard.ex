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
    {lifetime_invoiced, total_service_count, avg_completion_days, trust_score} = fetch_lifetime_stats(customer.id)
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
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950">
      <header class="bg-white/80 dark:bg-zinc-950/80 backdrop-blur-xl border-b border-zinc-200 dark:border-zinc-800 sticky top-0 z-50">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between">
          <div class="flex items-center gap-4">
            <div class="size-11 rounded-2xl bg-zinc-900 dark:bg-zinc-100 flex items-center justify-center text-zinc-100 dark:text-zinc-900 font-black text-xl shadow-lg shadow-zinc-900/10">
              {String.at(@customer.organization.name, 0)}
            </div>
            <div>
              <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-0.5">
                {@customer.organization.name}
              </p>
              <h1 class="text-xl font-bold text-zinc-900 dark:text-white tracking-tight">
                Client Portal <span class="text-zinc-400 dark:text-zinc-600 font-medium mx-2">/</span> {@customer.name}
              </h1>
            </div>
          </div>

          <div class="flex items-center gap-4">
                <div class="flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20">
                  <div class="size-1.5 rounded-full bg-emerald-500 animate-pulse shadow-[0_0_8px_rgba(16,185,129,0.6)]"></div>
                  <span class="text-[10px] font-black text-emerald-600 dark:text-emerald-400 uppercase tracking-widest">System Live</span>
                </div>
            <.link
              href={~p"/portal/logout"}
              method="delete"
              class="size-10 rounded-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center text-zinc-600 dark:text-zinc-400 hover:text-red-600 dark:hover:text-red-400 transition-all hover:rotate-12"
              title="Log out"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-5" />
            </.link>
          </div>
        </div>
      </header>

      <main class="max-w-6xl mx-auto px-4 sm:px-6 py-10">
        <!-- Intelligent KPI Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          <.kpi_widget
            label="Lifetime Service Value"
            value={"$#{format_money(@lifetime_invoiced)}"}
            subtext="Total across all services"
            icon="hero-banknotes"
            color="emerald"
          />
          <.kpi_widget
            label="Total Service Visits"
            value={to_string(@total_service_count)}
            subtext="Completed jobs"
            icon="hero-check-badge"
            color="primary"
          />
          <.kpi_widget
            label="Avg Completion"
            value={"#{@avg_completion_days} Days"}
            subtext="From request to finish"
            icon="hero-clock"
            color="amber"
          />
          <.kpi_widget
            label="Active Trust"
            value={"#{@trust_score}%"}
            subtext="Service reliability"
            icon="hero-shield-check"
            color="teal"
          />
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-10">
          <!-- Main Area (65%) -->
          <div class="lg:col-span-8 space-y-12">
            <!-- Active Jobs Section -->
            <section>
              <div class="flex items-center gap-3 mb-8">
                <div class="size-10 rounded-xl bg-primary flex items-center justify-center shadow-lg shadow-primary/20">
                  <.icon name="hero-bolt" class="size-5 text-white" />
                </div>
                <div>
                  <h2 class="text-2xl font-black text-zinc-900 dark:text-white tracking-tight">Active {@terminology["task_label_plural"]}</h2>
                  <p class="text-sm text-zinc-500 font-medium">Real-time status of your current services</p>
                </div>
              </div>

              <%= if Enum.empty?(@active_jobs) do %>
                <div class="bg-white dark:bg-zinc-900 rounded-[32px] border-2 border-dashed border-zinc-200 dark:border-zinc-800 p-16 text-center">
                  <div class="size-20 mx-auto mb-6 rounded-3xl bg-zinc-50 dark:bg-zinc-800/50 flex items-center justify-center border border-zinc-100 dark:border-zinc-800">
                    <.icon name="hero-calendar" class="size-10 text-zinc-300 dark:text-zinc-600" />
                  </div>
                  <h3 class="text-xl font-bold text-zinc-900 dark:text-white mb-2">Operations clear</h3>
                  <p class="text-zinc-500 max-w-xs mx-auto text-sm font-medium">
                    You have no active or scheduled services at this time.
                  </p>
                </div>
              <% else %>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <%= for job <- @active_jobs do %>
                    <.link
                      navigate={~p"/portal/jobs/#{job}"}
                      class="relative bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 p-6 hover:shadow-2xl hover:shadow-primary/5 transition-all group overflow-hidden"
                    >
                      <div class="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                        <.icon name="hero-bolt" class="size-24 text-primary" />
                      </div>
                      <div class="flex items-start justify-between mb-6 relative z-10">
                        <span class={[
                          "px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border shadow-sm",
                          status_color_theme(job.status)
                        ]}>
                          {String.replace(job.status, "_", " ")}
                        </span>
                        <div class="size-8 rounded-full bg-zinc-50 dark:bg-zinc-800 border border-zinc-100 dark:border-zinc-700 flex items-center justify-center group-hover:bg-primary group-hover:text-white transition-colors">
                          <.icon
                            name="hero-arrow-up-right"
                            class="size-4"
                          />
                        </div>
                      </div>
                      <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2 group-hover:text-primary transition-colors relative z-10">
                        {job.title}
                      </h3>
                      <div class="space-y-3 mt-6 relative z-10">
                        <div class="flex items-center gap-3">
                          <div class="size-8 rounded-lg bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center text-zinc-400">
                            <.icon name="hero-calendar" class="size-4" />
                          </div>
                          <div>
                            <p class="text-[10px] uppercase font-black text-zinc-400 tracking-wider leading-none mb-1">Schedule</p>
                            <p class="text-xs font-bold text-zinc-700 dark:text-zinc-300">
                              {format_date(job.scheduled_date)}
                            </p>
                          </div>
                        </div>
                        <%= if job.technician do %>
                          <div class="flex items-center gap-3 pt-3 border-t border-zinc-50 dark:border-zinc-800">
                            <img
                              src={"https://ui-avatars.com/api/?name=#{URI.encode(job.technician.name)}&background=random&color=fff&bold=true"}
                              class="size-8 rounded-lg object-cover"
                            />
                            <div>
                              <p class="text-[10px] uppercase font-black text-zinc-400 tracking-wider leading-none mb-1">{@terminology["worker_label"]}</p>
                              <p class="text-xs font-bold text-zinc-700 dark:text-zinc-300">{job.technician.name}</p>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </.link>
                  <% end %>
                </div>
              <% end %>
            </section>

            <!-- Service History Table-style -->
            <section>
              <div class="flex items-center justify-between mb-8">
                <div class="flex items-center gap-3">
                  <div class="size-10 rounded-xl bg-zinc-900 dark:bg-zinc-100 flex items-center justify-center">
                    <.icon name="hero-clock" class="size-5 text-white dark:text-zinc-900" />
                  </div>
                  <div>
                    <h2 class="text-2xl font-black text-zinc-900 dark:text-white tracking-tight">{@terminology["task_label"]} Intelligence</h2>
                    <p class="text-sm text-zinc-500 font-medium">Chronological record of service performance</p>
                  </div>
                </div>
                <.link
                  navigate={~p"/portal/history"}
                  class="px-4 py-2 rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 text-xs font-bold text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors shadow-sm"
                >
                  Explore All
                </.link>
              </div>

              <%= if Enum.empty?(@completed_jobs) do %>
                <p class="text-zinc-400 text-sm font-medium italic">Your service history is currently empty.</p>
              <% else %>
                <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 overflow-hidden shadow-sm">
                  <table class="w-full text-left">
                    <thead>
                      <tr class="text-[10px] font-black text-zinc-400 uppercase tracking-[0.2em] bg-zinc-50/50 dark:bg-zinc-800/30">
                        <th class="px-8 py-4">Service Details</th>
                        <th class="px-8 py-4">Completed On</th>
                        <th class="px-8 py-4 text-right"></th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-zinc-50 dark:divide-zinc-800/50">
                      <%= for job <- @completed_jobs do %>
                        <tr class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/10 transition-colors cursor-pointer" phx-click={JS.navigate(~p"/portal/jobs/#{job}")}>
                          <td class="px-8 py-6">
                            <p class="font-bold text-zinc-900 dark:text-white group-hover:text-primary transition-colors">{job.title}</p>
                            <p class="text-[11px] text-zinc-500 font-medium mt-0.5">#{job.number}</p>
                          </td>
                          <td class="px-8 py-6">
                            <p class="text-xs font-bold text-zinc-700 dark:text-zinc-300">
                              {format_date(job.completed_at)}
                            </p>
                            <p class="text-[10px] text-zinc-400 font-medium mt-0.5 whitespace-nowrap">
                              <%= if job.technician do %>
                                Verified by {job.technician.name}
                              <% end %>
                            </p>
                          </td>
                          <td class="px-8 py-6 text-right">
                             <.icon name="hero-chevron-right" class="size-4 text-zinc-300 group-hover:translate-x-1 transition-transform" />
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            </section>
          </div>

          <!-- Sidebar Area (35%) -->
          <div class="lg:col-span-4 space-y-8">
            <%!-- Outstanding Financials --%>
            <%= if length(@unpaid_invoices) > 0 do %>
              <div class="bg-amber-50 dark:bg-amber-500/5 rounded-[40px] border-2 border-amber-100 dark:border-amber-500/20 p-8">
                <div class="flex items-center gap-3 mb-8">
                  <div class="size-12 rounded-2xl bg-amber-500 flex items-center justify-center shadow-lg shadow-amber-500/20">
                    <.icon name="hero-credit-card" class="size-6 text-white" />
                  </div>
                  <div>
                    <h3 class="text-xl font-black text-amber-900 dark:text-amber-400 leading-tight">Financial<br/>Outstanding</h3>
                  </div>
                </div>

                <div class="space-y-4 mb-8">
                  <%= for invoice <- @unpaid_invoices do %>
                    <.link
                      navigate={~p"/portal/invoices/#{invoice.id}"}
                      class="block p-4 bg-white dark:bg-zinc-900 rounded-2xl border border-amber-200 dark:border-amber-500/10 hover:border-amber-500 transition-all shadow-sm group"
                    >
                      <div class="flex items-center justify-between mb-2">
                        <span class="text-[10px] font-black text-amber-600 dark:text-amber-500 uppercase tracking-widest">{invoice.number}</span>
                        <span class="text-lg font-black text-zinc-900 dark:text-white">${format_money(invoice.total_amount)}</span>
                      </div>
                      <p class="text-xs text-zinc-500 font-medium italic">Due {Calendar.strftime(invoice.due_date, "%b %d")}</p>
                    </.link>
                  <% end %>
                </div>

                <.link
                  navigate={~p"/portal/invoices"}
                  class="w-full flex items-center justify-center gap-2 py-4 bg-amber-500 hover:bg-amber-600 text-white font-black rounded-2xl transition-all shadow-lg shadow-amber-500/20 active:scale-95 group"
                >
                  Settle Balance <.icon name="hero-arrow-right" class="size-4 group-hover:translate-x-1 transition-transform" />
                </.link>
              </div>
            <% end %>

            <%!-- Notification Preferences --%>
            <div class="bg-white dark:bg-zinc-900 rounded-[40px] border border-zinc-200 dark:border-zinc-800 p-8">
              <div class="size-12 rounded-2xl bg-zinc-900 dark:bg-white flex items-center justify-center mb-6">
                <.icon name="hero-bell" class="size-6 text-white dark:text-zinc-900" />
              </div>
              <h3 class="text-xl font-black text-zinc-900 dark:text-white tracking-tight mb-2">Notifications</h3>
              <p class="text-sm text-zinc-500 font-medium mb-8 leading-relaxed">
                Manage how you receive updates about your service appointments, invoices, and job status.
              </p>

              <button
                type="button"
                phx-click={show_modal("preferences-modal")}
                class="w-full flex items-center justify-between p-4 bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl border border-zinc-100 dark:border-zinc-800 text-left hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors group"
              >
                <div>
                  <p class="font-bold text-zinc-900 dark:text-white text-sm">Manage Settings</p>
                  <p class="text-[10px] text-zinc-400 font-black uppercase tracking-wider mt-0.5">
                    Email & SMS
                  </p>
                </div>
                <div class="size-8 rounded-full bg-white dark:bg-zinc-700 flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform">
                  <.icon name="hero-cog-6-tooth" class="size-4 text-zinc-500 dark:text-zinc-300" />
                </div>
              </button>
            </div>
          </div>
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
          <p class="text-sm text-zinc-500">Fine-tune how you receive updates from {@customer.organization.name}.</p>
        </div>

        <.form for={@form} phx-change="validate_preferences" phx-submit="save_preferences" class="space-y-6">
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
             <button type="button" phx-click={hide_modal("preferences-modal")} class="px-4 py-2 rounded-xl text-sm font-bold text-zinc-500 hover:text-zinc-900 dark:hover:text-white transition-colors">Cancel</button>
             <.button type="submit" class="bg-primary hover:bg-primary/90 text-white rounded-xl px-4 py-2 text-sm font-bold shadow-lg shadow-primary/20">
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
        <p class="text-2xl font-black text-zinc-900 dark:text-white leading-none tracking-tight mb-1">{@value}</p>
        <p class="text-[10px] text-zinc-500 font-medium">{@subtext}</p>
      </div>
    </div>
    """
  end

  defp status_color_theme("pending"),
    do: "bg-zinc-50 text-zinc-500 border-zinc-100 dark:bg-zinc-800/50 dark:text-zinc-400 dark:border-zinc-700"

  defp status_color_theme("en_route"),
    do: "bg-blue-50 text-blue-600 border-blue-100 dark:bg-blue-500/10 dark:text-blue-400 dark:border-blue-500/20"

  defp status_color_theme("arrived"),
    do: "bg-indigo-50 text-indigo-600 border-indigo-100 dark:bg-indigo-500/10 dark:text-indigo-400 dark:border-indigo-500/20"

  defp status_color_theme("in_progress"),
    do: "bg-emerald-50 text-emerald-600 border-emerald-100 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/20"

  defp status_color_theme("completed"),
    do: "bg-teal-50 text-teal-600 border-teal-100 dark:bg-teal-500/10 dark:text-teal-400 dark:border-teal-500/20"

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
        where: j.customer_id == ^customer_id and j.status == "completed" and not is_nil(j.completed_at),
        select: fragment("ROUND(AVG(EXTRACT(EPOCH FROM (? - ?)) / 86400)::numeric, 1)", j.completed_at, j.inserted_at)

    avg_completion_days = Repo.one(avg_completion_query) || 0.0

    # Calculate Trust Score (Reliability)
    # Based on completion rate of non-cancelled jobs
    total_non_cancelled =
      from(j in Jobs.Job,
        where: j.customer_id == ^customer_id and j.status != "cancelled",
        select: count(j.id)
      ) |> Repo.one()

    trust_score =
      if total_non_cancelled > 0 do
        round((history_count / total_non_cancelled) * 100)
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
end
