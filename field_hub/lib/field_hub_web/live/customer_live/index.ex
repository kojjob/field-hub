defmodule FieldHubWeb.CustomerLive.Index do
  use FieldHubWeb, :live_view

  alias FieldHub.CRM
  alias FieldHub.CRM.Customer
  alias FieldHub.CRM.Broadcaster
  alias FieldHub.Jobs

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    org_id = current_user.organization_id

    # Redirect to onboarding if user has no organization
    if is_nil(org_id) do
      {:ok, push_navigate(socket, to: ~p"/onboarding")}
    else
      if connected?(socket) do
        Broadcaster.subscribe_to_org(org_id)
      end

      socket =
        socket
        |> assign(:current_organization, %FieldHub.Accounts.Organization{id: org_id})
        |> assign(:search, "")
        |> assign(:status_filter, "active")
        |> assign(:selected_customer, nil)
        |> assign(:panel_tab, "overview")
        |> assign(:show_form_panel, false)
        |> assign(:current_nav, :customers)
        |> assign(:has_customers, true)
        |> assign(:page, 1)
        |> assign(:total_pages, 1)
        |> stream(:customers, [])

      {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    socket = assign(socket, :page, page)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    customer = CRM.get_customer!(socket.assigns.current_organization.id, id)

    socket
    |> assign(:page_title, "Edit Customer")
    |> assign(:customer, customer)
    |> assign(:show_form_panel, true)
    |> load_customers()
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Customer")
    |> assign(:customer, %Customer{})
    |> assign(:show_form_panel, true)
    |> load_customers()
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    customer = CRM.get_customer!(socket.assigns.current_organization.id, id)
    customer_jobs = get_customer_jobs(socket.assigns.current_organization.id, customer.id)

    socket
    |> assign(:page_title, "Customer Directory")
    |> assign(:customer, nil)
    |> assign(:selected_customer, customer)
    |> assign(:customer_jobs, customer_jobs)
    |> assign(:show_form_panel, false)
    |> assign(:panel_tab, "overview")
    |> load_customers()
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Customer Directory")
    |> assign(:customer, nil)
    |> assign(:selected_customer, nil)
    |> assign(:show_form_panel, false)
    |> load_customers()
  end

  defp load_customers(socket) do
    org_id = socket.assigns.current_organization.id
    search = socket.assigns.search
    page = socket.assigns.page
    pagination_opts = %{page: page, page_size: 10}

    %{entries: customers, total_pages: total_pages} =
      if search == "" or is_nil(search) do
        CRM.list_customers(org_id, pagination_opts)
      else
        CRM.search_customers(org_id, search, pagination_opts)
      end

    socket
    |> assign(:has_customers, customers != [])
    |> assign(:total_pages, total_pages)
    |> stream(:customers, customers, reset: true)
  end

  defp get_customer_jobs(org_id, customer_id) do
    try do
      Jobs.list_jobs_for_customer(org_id, customer_id)
    rescue
      _ -> []
    end
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:page, 1)
     |> load_customers()}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, assign(socket, :status_filter, status)}
  end

  def handle_event("select_customer", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/customers/#{id}")}
  end

  def handle_event("close_panel", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/customers")}
  end

  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :panel_tab, tab)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    customer = CRM.get_customer!(socket.assigns.current_organization.id, id)
    {:ok, _} = CRM.archive_customer(customer)

    socket =
      socket
      |> stream_delete(:customers, customer)
      |> assign(:selected_customer, nil)

    {:noreply, push_patch(socket, to: ~p"/customers")}
  end

  @impl true
  def handle_info({FieldHubWeb.CustomerLive.FormComponent, {:saved, customer}}, socket) do
    {:noreply,
     socket
     |> stream_insert(:customers, customer)
     |> assign(:show_form_panel, false)
     |> push_patch(to: ~p"/customers/#{customer.id}")}
  end

  def handle_info({:customer_created, customer}, socket) do
    {:noreply, stream_insert(socket, :customers, customer)}
  end

  def handle_info({:customer_updated, customer}, socket) do
    {:noreply, stream_insert(socket, :customers, customer)}
  end

  def handle_info({:customer_archived, customer}, socket) do
    {:noreply, stream_delete(socket, :customers, customer)}
  end

  defp customer_initials(name) when is_binary(name) do
    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp customer_initials(_), do: "?"

  defp format_last_service(nil), do: "No jobs yet"

  defp format_last_service(date) when is_struct(date) do
    "Last: #{Calendar.strftime(date, "%b %d, %Y")}"
  end

  defp format_last_service(_), do: "No jobs yet"

  defp format_currency(nil), do: "$0.00"

  defp format_currency(amount) when is_number(amount) do
    "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"
  end

  defp format_currency(_), do: "$0.00"

  defp status_badge_class("active"),
    do: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"

  defp status_badge_class("inactive"),
    do: "bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400"

  defp status_badge_class("contract"),
    do: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"

  defp status_badge_class(_), do: "bg-zinc-100 text-zinc-600"

  defp job_status_badge("completed"),
    do: "bg-emerald-100 text-emerald-700 text-[10px] px-2 py-0.5 rounded-full font-bold uppercase"

  defp job_status_badge("pending"),
    do: "bg-amber-100 text-amber-700 text-[10px] px-2 py-0.5 rounded-full font-bold uppercase"

  defp job_status_badge("in_progress"),
    do: "bg-blue-100 text-blue-700 text-[10px] px-2 py-0.5 rounded-full font-bold uppercase"

  defp job_status_badge(_),
    do: "bg-zinc-100 text-zinc-600 text-[10px] px-2 py-0.5 rounded-full font-bold uppercase"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-4rem)] overflow-hidden">
      <!-- Main Content Area -->
      <div class={[
        "flex-1 flex flex-col min-w-0 transition-all duration-300 overflow-y-auto",
        @show_form_panel && "lg:mr-[480px]",
        !@show_form_panel && @selected_customer && "lg:mr-[420px]"
      ]}>
        <div class="space-y-10 p-6 pb-20">
          <!-- Page Heading -->
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
                CRM
              </p>
              <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
                Customer Directory
              </h2>
            </div>
            <div class="flex flex-wrap items-center gap-3">
              <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
                <.icon name="hero-funnel" class="size-5" /> Filters
              </button>
              <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
                <.icon name="hero-arrow-down-tray" class="size-5" /> Export
              </button>
              <.link patch={~p"/customers/new"}>
                <button class="flex items-center gap-2 px-5 py-2.5 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1">
                  <.icon name="hero-plus" class="size-5" /> Add Customer
                </button>
              </.link>
            </div>
          </div>

          <!-- KPI Cards Grid -->
          <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
            <FieldHubWeb.DashboardComponents.kpi_card
              label="Total Customers"
              value="247"
              change="+12"
              icon="confirmation_number"
              variant={:simple}
            />
            <FieldHubWeb.DashboardComponents.kpi_card
              label="Active Accounts"
              value="218"
              progress={88}
              variant={:progress}
              icon="star"
              subtext="88% of customers active"
            />
            <FieldHubWeb.DashboardComponents.kpi_card
              label="New This Month"
              value="24"
              icon="trending_up"
              variant={:avatars}
            />
            <FieldHubWeb.DashboardComponents.kpi_card
              label="Avg Lifetime Value"
              value="$1,840"
              change="+8.2%"
              icon="payments"
              variant={:simple}
            />
          </div>

          <!-- Search & Filters Bar -->
          <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
            <div class="flex items-center justify-between gap-4">
              <form phx-change="search" id="search-form" class="flex-1 max-w-xl">
                <div class="relative">
                  <.icon
                    name="hero-magnifying-glass"
                    class="absolute left-4 top-1/2 -translate-y-1/2 text-zinc-400 size-5"
                  />
                  <input
                    type="text"
                    name="search"
                    value={@search}
                    placeholder="Search by name, email, or company..."
                    phx-debounce="300"
                    class="w-full pl-12 pr-4 py-3 bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-xl text-sm font-medium text-zinc-700 dark:text-zinc-200 placeholder:text-zinc-400 focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all"
                  />
                </div>
              </form>
              <div class="flex items-center gap-2">
                <button class="px-4 py-2.5 text-xs font-bold rounded-xl bg-primary/10 text-primary border border-primary/20">All</button>
                <button class="px-4 py-2.5 text-xs font-bold rounded-xl text-zinc-500 hover:bg-zinc-100 dark:hover:bg-zinc-800 border border-transparent">Active</button>
                <button class="px-4 py-2.5 text-xs font-bold rounded-xl text-zinc-500 hover:bg-zinc-100 dark:hover:bg-zinc-800 border border-transparent">Contract</button>
              </div>
            </div>
          </div>

          <!-- Customer Table Card -->
          <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
            <table class="min-w-full">
              <thead class="bg-zinc-50 dark:bg-zinc-800/50">
                <tr>
                  <th class="py-4 px-8 text-left text-[10px] font-black uppercase tracking-widest text-zinc-500">
                    Customer Name
                  </th>
                  <th class="py-4 px-6 text-left text-[10px] font-black uppercase tracking-widest text-zinc-500">
                    Contact Info
                  </th>
                  <th class="py-4 px-6 text-left text-[10px] font-black uppercase tracking-widest text-zinc-500">
                    Service History
                  </th>
                  <th class="py-4 px-6 text-left text-[10px] font-black uppercase tracking-widest text-zinc-500">
                    Balance
                  </th>
                  <th class="py-4 px-6 text-left text-[10px] font-black uppercase tracking-widest text-zinc-500">
                    Status
                  </th>
                  <th class="relative py-4 pl-3 pr-8 text-right">
                    <span class="sr-only">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody phx-update="stream" id="customers" class="divide-y divide-zinc-100 dark:divide-zinc-800">
                <tr
                  :for={{id, customer} <- @streams.customers}
                  id={id}
                  phx-click="select_customer"
                  phx-value-id={customer.id}
                  class={[
                    "hover:bg-primary/5 dark:hover:bg-primary/10 cursor-pointer transition-all group",
                    @selected_customer && @selected_customer.id == customer.id &&
                      "bg-primary/10 dark:bg-primary/20"
                  ]}
                >
                  <td class="py-5 px-8">
                    <div class="flex items-center gap-4">
                      <div class="size-10 rounded-full bg-primary flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-primary/20">
                        {customer_initials(customer.name)}
                      </div>
                      <div>
                        <p class="font-bold text-zinc-900 dark:text-white group-hover:text-primary dark:group-hover:text-primary transition-colors">
                          {customer.name}
                        </p>
                        <p class="text-xs text-zinc-500">{customer.city}, {customer.state}</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-5 px-6">
                    <p class="text-sm text-zinc-700 dark:text-zinc-300">{customer.email}</p>
                    <p class="text-xs text-zinc-500">{customer.phone}</p>
                  </td>
                  <td class="py-5 px-6">
                    <p class="text-sm text-zinc-700 dark:text-zinc-300">
                      {format_last_service(customer.updated_at)}
                    </p>
                    <p class="text-xs text-zinc-500">0 Jobs Completed</p>
                  </td>
                  <td class="py-5 px-6">
                    <p class="text-sm font-semibold text-zinc-900 dark:text-white">$0.00</p>
                  </td>
                  <td class="py-5 px-6">
                    <span class={[
                      "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold",
                      status_badge_class("active")
                    ]}>
                      <div class="size-1.5 rounded-full bg-emerald-500"></div>
                      Active
                    </span>
                  </td>
                  <td class="py-5 pl-3 pr-8 text-right">
                    <div class="flex items-center justify-end gap-2 text-zinc-400">
                      <.link
                        patch={~p"/customers/#{customer}/edit"}
                        phx-hook="StopPropagation"
                        class="p-2 rounded-xl hover:bg-zinc-100 dark:hover:bg-zinc-800 hover:text-primary transition-all"
                      >
                        <.icon name="hero-pencil-square" class="size-5" />
                      </.link>
                      <.link
                        phx-click={JS.push("delete", value: %{id: customer.id})}
                        phx-hook="StopPropagation"
                        data-confirm="Are you sure you want to archive this customer?"
                        class="p-2 rounded-xl hover:bg-zinc-100 dark:hover:bg-zinc-800 hover:text-red-600 transition-all"
                      >
                        <.icon name="hero-archive-box" class="size-5" />
                      </.link>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <%= if not @has_customers do %>
              <div class="flex flex-col items-center justify-center py-20">
                <div class="size-16 rounded-2xl bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center mb-4">
                  <.icon name="hero-magnifying-glass" class="size-8 text-zinc-300 dark:text-zinc-600" />
                </div>
                <h3 class="text-sm font-bold text-zinc-900 dark:text-white mb-1">No customers found</h3>
                <p class="text-xs text-zinc-500 dark:text-zinc-400">Try adjusting your search terms</p>
              </div>
            <% end %>
          </div>

          <!-- Pagination -->
          <div class="flex items-center justify-between">
            <p class="text-sm text-zinc-500">
              Page <span class="font-semibold">{@page}</span> of <span class="font-semibold">{@total_pages}</span>
            </p>
            <div class="flex items-center gap-2">
              <.link
                patch={~p"/customers?page=#{@page - 1}&search=#{@search}"}
                class={"size-10 rounded-xl border border-zinc-200 dark:border-zinc-700 flex items-center justify-center text-zinc-400 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-all #{if @page <= 1, do: "pointer-events-none opacity-50"}"}
              >
                <.icon name="hero-chevron-left" class="size-5" />
              </.link>

              <button class="size-10 rounded-xl bg-primary text-white font-bold text-sm flex items-center justify-center shadow-lg shadow-primary/20">
                {@page}
              </button>

              <.link
                patch={~p"/customers?page=#{@page + 1}&search=#{@search}"}
                class={"size-10 rounded-xl border border-zinc-200 dark:border-zinc-700 flex items-center justify-center text-zinc-400 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-all #{if @page >= @total_pages, do: "pointer-events-none opacity-50"}"}
              >
                <.icon name="hero-chevron-right" class="size-5" />
              </.link>
            </div>
          </div>
        </div>
      </div>


    <!-- Slide-in Customer Detail Panel -->
      <div
        :if={@selected_customer}
        class="fixed right-0 top-0 bottom-0 w-[420px] bg-white dark:bg-zinc-900 border-l border-zinc-200 dark:border-zinc-700 shadow-2xl z-50 flex flex-col animate-in slide-in-from-right duration-300"
      >
        <!-- Panel Header -->
        <div class="p-6 border-b border-zinc-200 dark:border-zinc-700">
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-center gap-4">
              <div class="size-14 rounded-2xl bg-primary flex items-center justify-center text-white font-bold text-xl shadow-lg shadow-primary/20">
                {customer_initials(@selected_customer.name)}
              </div>
              <div>
                <h2 class="text-xl font-bold text-zinc-900 dark:text-white">
                  {@selected_customer.name}
                </h2>
                <p class="text-sm text-zinc-500">{@selected_customer.source || "Direct Customer"}</p>
              </div>
            </div>
            <button
              phx-click="close_panel"
              class="size-8 rounded-lg hover:bg-zinc-100 dark:hover:bg-zinc-800 flex items-center justify-center text-zinc-400 hover:text-zinc-600 transition-all"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>

          <div class="flex items-center gap-3">
            <.link patch={~p"/customers/#{@selected_customer}/edit"} class="flex-1">
              <button class="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-zinc-700 dark:text-zinc-200 bg-zinc-100 dark:bg-zinc-800 rounded-xl hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-all">
                <.icon name="hero-pencil" class="size-4" /> Edit Profile
              </button>
            </.link>
            <.link navigate={~p"/jobs/new?customer_id=#{@selected_customer.id}"} class="flex-1">
              <button class="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-bold text-white bg-primary rounded-xl shadow-lg shadow-primary/20 hover:brightness-110 transition-all">
                <.icon name="hero-plus" class="size-4" /> New Job
              </button>
            </.link>
          </div>
        </div>

    <!-- Panel Tabs -->
        <div class="flex border-b border-zinc-200 dark:border-zinc-700 px-6">
          <button
            phx-click="change_tab"
            phx-value-tab="overview"
            class={[
              "px-4 py-3 text-sm font-semibold border-b-2 transition-all -mb-px",
              @panel_tab == "overview" && "text-primary border-primary",
              @panel_tab != "overview" && "text-zinc-500 border-transparent hover:text-zinc-700"
            ]}
          >
            Overview
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="jobs"
            class={[
              "px-4 py-3 text-sm font-semibold border-b-2 transition-all -mb-px",
              @panel_tab == "jobs" && "text-primary border-primary",
              @panel_tab != "jobs" && "text-zinc-500 border-transparent hover:text-zinc-700"
            ]}
          >
            Jobs
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="billing"
            class={[
              "px-4 py-3 text-sm font-semibold border-b-2 transition-all -mb-px",
              @panel_tab == "billing" && "text-primary border-primary",
              @panel_tab != "billing" && "text-zinc-500 border-transparent hover:text-zinc-700"
            ]}
          >
            Billing
          </button>
        </div>

    <!-- Panel Content -->
        <div class="flex-1 overflow-y-auto p-6 space-y-6">
          <%= if @panel_tab == "overview" do %>
            <!-- Stats Cards -->
            <div class="grid grid-cols-2 gap-4">
              <div class="p-4 bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl">
                <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 mb-1">
                  Lifetime Value
                </p>
                <p class="text-2xl font-black text-zinc-900 dark:text-white">$0.00</p>
              </div>
              <div class="p-4 bg-zinc-50 dark:bg-zinc-800/50 rounded-2xl">
                <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 mb-1">
                  Outstanding
                </p>
                <p class="text-2xl font-black text-primary">$0.00</p>
              </div>
            </div>

    <!-- Contact Information -->
            <div>
              <h3 class="text-[11px] font-black uppercase tracking-widest text-zinc-400 mb-4">
                Contact Information
              </h3>
              <div class="space-y-4">
                <div class="flex items-start gap-3">
                  <.icon name="hero-map-pin" class="text-zinc-400 size-5" />
                  <div>
                    <p class="text-xs font-bold text-zinc-500 uppercase tracking-wide">
                      Service Address
                    </p>
                    <p class="text-sm text-zinc-900 dark:text-white">
                      {Customer.full_address(@selected_customer)}
                    </p>
                  </div>
                </div>
                <div class="flex items-start gap-3">
                  <.icon name="hero-envelope" class="text-zinc-400 size-5" />
                  <div>
                    <p class="text-xs font-bold text-zinc-500 uppercase tracking-wide">
                      Email Address
                    </p>
                    <a
                      href={"mailto:#{@selected_customer.email}"}
                      class="text-sm text-primary hover:underline"
                    >
                      {@selected_customer.email}
                    </a>
                  </div>
                </div>
                <div class="flex items-start gap-3">
                  <.icon name="hero-phone" class="text-zinc-400 size-5" />
                  <div>
                    <p class="text-xs font-bold text-zinc-500 uppercase tracking-wide">Phone</p>
                    <a
                      href={"tel:#{@selected_customer.phone}"}
                      class="text-sm text-primary hover:underline"
                    >
                      {@selected_customer.phone}
                    </a>
                  </div>
                </div>
              </div>
            </div>

    <!-- Recent Jobs -->
            <div>
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-[11px] font-black uppercase tracking-widest text-zinc-400">
                  Recent Jobs
                </h3>
                <.link
                  navigate={~p"/jobs?customer_id=#{@selected_customer.id}"}
                  class="text-xs font-bold text-primary hover:underline"
                >
                  View All
                </.link>
              </div>
              <div class="space-y-3">
                <p class="text-sm text-zinc-500 dark:text-zinc-400 italic">
                  No jobs found for this customer
                </p>
              </div>
            </div>

    <!-- Notes -->
            <%= if @selected_customer.notes do %>
              <div>
                <h3 class="text-[11px] font-black uppercase tracking-widest text-zinc-400 mb-3">
                  Notes
                </h3>
                <p class="text-sm text-zinc-700 dark:text-zinc-300">{@selected_customer.notes}</p>
              </div>
            <% end %>

    <!-- Special Instructions -->
            <%= if @selected_customer.gate_code || @selected_customer.special_instructions do %>
              <div>
                <h3 class="text-[11px] font-black uppercase tracking-widest text-zinc-400 mb-3">
                  Special Instructions
                </h3>
                <%= if @selected_customer.gate_code do %>
                  <div class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-300 mb-2">
                    <.icon name="hero-key" class="text-zinc-400 size-5" /> Gate Code:
                    <span class="font-bold">{@selected_customer.gate_code}</span>
                  </div>
                <% end %>
                <%= if @selected_customer.special_instructions do %>
                  <p class="text-sm text-zinc-700 dark:text-zinc-300">
                    {@selected_customer.special_instructions}
                  </p>
                <% end %>
              </div>
            <% end %>
          <% end %>

          <%= if @panel_tab == "jobs" do %>
            <div class="space-y-4">
              <%= if @customer_jobs == [] do %>
                <div class="text-center py-6">
                  <.icon name="hero-briefcase" class="size-6" />
                  <p class="text-sm text-zinc-500 dark:text-zinc-400">
                    No jobs found for this customer.
                  </p>
                </div>
              <% else %>
                <%= for job <- @customer_jobs do %>
                  <div
                    class="p-4 bg-zinc-50 dark:bg-zinc-800/50 rounded-xl border border-zinc-200 dark:border-zinc-700 hover:border-primary/50 transition-colors group cursor-pointer"
                    phx-click={JS.navigate(~p"/jobs/#{job.id}")}
                  >
                    <div class="flex items-start justify-between mb-2">
                      <div>
                        <div class="flex items-center gap-2 mb-1">
                          <span class="text-xs font-bold text-zinc-500">{job.number}</span>
                          <span class={job_status_badge(job.status)}>{job.status}</span>
                        </div>
                        <h4 class="text-sm font-bold text-zinc-900 dark:text-white group-hover:text-primary transition-colors">
                          {job.title}
                        </h4>
                      </div>
                      <.icon name="hero-chevron-right" class="text-zinc-400 size-5" />
                    </div>
                    <div class="flex items-center gap-4 text-xs text-zinc-500">
                      <div class="flex items-center gap-1">
                        <.icon name="hero-calendar" class="size-3.5" />
                        {job.scheduled_date || "Unscheduled"}
                      </div>
                      <div class="flex items-center gap-1">
                        <.icon name="hero-banknotes" class="size-3.5" />
                        {format_currency(job.quoted_amount)}
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>

              <.link navigate={~p"/jobs/new?customer_id=#{@selected_customer.id}"}>
                <button class="w-full flex items-center justify-center gap-2 px-4 py-3 text-sm font-bold text-primary bg-primary/10 rounded-xl hover:bg-primary/20 transition-all mt-4">
                  <.icon name="hero-plus" class="size-5" /> Create New Job
                </button>
              </.link>
            </div>
          <% end %>

          <%= if @panel_tab == "billing" do %>
            <div class="space-y-6">
              <div>
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-[11px] font-black uppercase tracking-widest text-zinc-400">
                    Payment Methods
                  </h3>
                  <button class="text-xs font-bold text-primary hover:underline">+ Add New</button>
                </div>
                <p class="text-sm text-zinc-500 dark:text-zinc-400 italic">
                  No payment methods on file
                </p>
              </div>

              <div>
                <h3 class="text-[11px] font-black uppercase tracking-widest text-zinc-400 mb-4">
                  Billing History
                </h3>
                <p class="text-sm text-zinc-500 dark:text-zinc-400 italic">No invoices found</p>
              </div>
            </div>
          <% end %>
        </div>

    <!-- Panel Footer -->
        <div class="p-4 border-t border-zinc-200 dark:border-zinc-700">
          <button
            phx-click="delete"
            phx-value-id={@selected_customer.id}
            data-confirm="Are you sure you want to archive this customer?"
            class="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-xl transition-all"
          >
            <.icon name="hero-archive-box" class="size-5" /> Archive Customer
          </button>
        </div>
      </div>

    <!-- Slide-in Form Panel (for New/Edit) -->
      <div
        :if={@show_form_panel}
        class="fixed right-0 top-0 bottom-0 w-[480px] bg-white dark:bg-zinc-900 border-l border-zinc-200 dark:border-zinc-700 shadow-2xl z-50 flex flex-col animate-in slide-in-from-right duration-300"
      >
        <!-- Form Panel Header -->
        <div class="p-6 border-b border-zinc-200 dark:border-zinc-700 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-bold text-zinc-900 dark:text-white">{@page_title}</h2>
            <p class="text-sm text-zinc-500 mt-1">Fill in the customer details below</p>
          </div>
          <button
            phx-click={JS.patch(~p"/customers")}
            class="size-8 rounded-lg hover:bg-zinc-100 dark:hover:bg-zinc-800 flex items-center justify-center text-zinc-400 hover:text-zinc-600 transition-all"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>

    <!-- Form Content -->
        <div class="flex-1 overflow-y-auto p-6">
          <.live_component
            module={FieldHubWeb.CustomerLive.FormComponent}
            id={@customer.id || :new}
            title={@page_title}
            action={@live_action}
            customer={@customer}
            current_organization={@current_organization}
            patch={~p"/customers"}
          />
        </div>
      </div>
    </div>
    """
  end
end
