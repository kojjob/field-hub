defmodule FieldHubWeb.DashboardComponents do
  use FieldHubWeb, :html

  @doc """
  Sidebar navigation for the dashboard.
  """
  attr :current_user, :any, required: true
  def sidebar(assigns) do
    ~H"""
    <aside class="w-68 flex-shrink-0 border-r border-fsm-border-light dark:border-slate-800 bg-white dark:bg-fsm-sidebar-dark flex flex-col hidden lg:flex">
      <div class="p-6 border-b border-fsm-border-light dark:border-slate-800">
        <div class="flex items-center gap-3">
          <div class="size-9 bg-fsm-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-fsm-primary/20">
            <span class="material-symbols-outlined notranslate text-[22px]">grid_view</span>
          </div>
          <div class="flex flex-col">
            <h1 class="text-lg font-extrabold leading-tight text-slate-900 dark:text-white tracking-tight">
              FieldHub
            </h1>
            <p class="text-[10px] text-fsm-primary font-bold tracking-[0.1em] uppercase leading-none mt-0.5">
              Enterprise
            </p>
          </div>
        </div>
      </div>

      <nav class="flex-1 px-4 py-8 space-y-1 overflow-y-auto scrollbar-hide">
        <.nav_heading label="Core" />
        <.nav_item icon="dashboard" label="Dashboard" uri={~p"/dashboard"} active={true} />
        <.nav_item icon="calendar_month" label="Schedule" uri={~p"/dispatch"} />
        <.nav_item icon="map" label="Dispatch Map" uri={~p"/dispatch"} />
        <.nav_item icon="confirmation_number" label="Jobs" uri={~p"/jobs"} />
        <.nav_item icon="engineering" label="Technicians" uri={~p"/technicians"} />
        <.nav_item icon="people" label="Customers" uri={~p"/customers"} />
        <.nav_item icon="bar_chart" label="Reports" uri="#" />

        <div class="pt-6">
          <.nav_heading label="Administration" />
          <.nav_item icon="auto_stories" label="Terminology" uri={~p"/settings/terminology"} />
          <.nav_item icon="palette" label="Branding" uri={~p"/settings/branding"} />
          <.nav_item icon="account_tree" label="Workflows" uri={~p"/settings/workflows"} />
          <.nav_item icon="tune" label="Custom Fields" uri={~p"/settings/custom-fields"} />
          <.nav_item icon="settings" label="Settings" uri="#" />
        </div>
      </nav>

      <div class="p-4 border-t border-fsm-border-light dark:border-slate-800 mt-auto">
        <div class="bg-slate-50 dark:bg-slate-800/50 p-3.5 rounded-2xl flex items-center gap-3 border border-slate-100 dark:border-slate-700/50 group transition-all">
          <div class="relative">
            <div
              class="size-10 rounded-full bg-cover bg-center border-2 border-fsm-primary/30 dark:border-slate-800"
              style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuAcPmwW185XBfb0X5bdHqxPAesi50Um4o4vD_xAcDkQ8KUho5p-wvgep4S_uZakcnjOHhoDDnRfnsTucGWrXo2MIQeBZWUnyUiHaOYD-myWUY3GOS2HPFeHNOfmcQUADE2Js_upYoaluGyO7oATwIDNsr4GdZuV2lnmAIG4olW7v6Qtlp1zLoNFUou8ddI_R1R1CRDTV5usU6AQ7cWJRS_3Drg3YMC5przJxkIsgDhUNLEExU4EeFQnAfc5be2DiBrBHhG1T8xvp6w');"
            >
            </div>
            <div class="absolute -bottom-0.5 -right-0.5 size-3.5 bg-emerald-500 border-2 border-white dark:border-slate-800 rounded-full"></div>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-xs font-bold truncate text-slate-900 dark:text-white">
              <%= @current_user.email %>
            </p>
            <p class="text-[10px] text-slate-500 dark:text-slate-400 uppercase font-bold tracking-wider">
              System Admin
            </p>
          </div>
          <button class="text-slate-400 hover:text-fsm-primary transition-colors">
            <span class="material-symbols-outlined notranslate text-[20px]">logout</span>
          </button>
        </div>
      </div>
    </aside>
    """
  end

  defp nav_heading(assigns) do
    ~H"""
    <p class="px-4 mb-2 text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-[0.2em]">
      <%= @label %>
    </p>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :uri, :string, default: "#"

  defp nav_item(assigns) do
    ~H"""
    <a
      href={@uri}
      class={[
        "flex items-center gap-3.5 px-4 py-2.5 rounded-xl transition-all duration-200 cursor-pointer group relative overflow-hidden",
        @active && "bg-fsm-primary text-white shadow-xl shadow-fsm-primary/20",
        !@active && "text-slate-500 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-fsm-primary"
      ]}
    >
      <span class="material-symbols-outlined notranslate text-[22px] z-10 font-light opacity-90 truncate tracking-tight overflow-hidden"><%= @icon %></span>
      <p class="text-[13px] font-bold tracking-tight z-10 truncate"><%= @label %></p>
      <div :if={@active} class="absolute inset-0 bg-gradient-to-r from-white/0 to-white/10"></div>
    </a>
    """
  end

  @doc """
  Global header for the dashboard content area.
  """
  attr :current_user, :any, required: true
  def header(assigns) do
    ~H"""
    <header class="h-18 flex-shrink-0 flex items-center justify-between px-8 bg-white dark:bg-fsm-sidebar-dark border-b border-fsm-border-light dark:border-slate-800 backdrop-blur-md sticky top-0 z-30">
      <div class="flex items-center flex-1 max-w-xl">
        <div class="relative w-full group">
          <span class="material-symbols-outlined notranslate absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-fsm-primary transition-colors text-[20px]">
            search
          </span>
          <div class="absolute right-4 top-1/2 -translate-y-1/2 flex items-center gap-1">
            <span class="px-1.5 py-0.5 rounded border border-slate-200 dark:border-slate-700 text-[10px] font-bold text-slate-400 dark:text-slate-500">
              CMD+K
            </span>
          </div>
          <input
            class="w-full pl-12 pr-16 py-3 bg-slate-50 dark:bg-slate-800/40 border-none rounded-2xl text-sm focus:ring-2 focus:ring-fsm-primary/20 placeholder:text-slate-400 transition-all text-slate-900 dark:text-white"
            placeholder="Search jobs, tech ID, or customers..."
            type="text"
          />
        </div>
      </div>

      <div class="flex items-center gap-5 ml-8">
        <div class="flex items-center gap-2">
          <!-- Theme Toggle -->
          <button
            id="themeToggle"
            class="size-10 flex items-center justify-center text-slate-400 hover:text-fsm-primary hover:bg-slate-50 dark:hover:bg-slate-800 rounded-xl transition-all"
          >
            <span class="material-symbols-outlined notranslate text-[22px] dark:hidden">dark_mode</span>
            <span class="material-symbols-outlined notranslate text-[22px] hidden dark:block">light_mode</span>
          </button>

          <!-- Notifications Dropdown -->
          <div class="relative group">
            <button class="relative size-10 flex items-center justify-center text-slate-400 hover:text-fsm-primary hover:bg-slate-50 dark:hover:bg-slate-800 rounded-xl transition-all group">
              <span class="material-symbols-outlined notranslate text-[24px]">notifications</span>
              <span class="absolute top-2.5 right-2.5 size-2 bg-red-500 rounded-full ring-2 ring-white dark:ring-[#0f172a]"></span>
            </button>

            <!-- Dropdown Menu -->
            <div class="absolute right-0 mt-2 w-80 bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-100 dark:border-slate-800 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 transform origin-top-right group-hover:translate-y-0 translate-y-2">
              <div class="p-4 border-b border-slate-50 dark:border-slate-800 flex items-center justify-between">
                <h4 class="text-sm font-black text-slate-900 dark:text-white">Notifications</h4>
                <span class="text-[10px] font-bold text-fsm-primary uppercase bg-fsm-primary/10 px-2 py-0.5 rounded">2 New</span>
              </div>
              <div class="max-h-96 overflow-y-auto">
                <div class="p-4 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors cursor-pointer border-b border-slate-50 dark:border-slate-800">
                  <div class="flex gap-3">
                    <div class="size-8 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center flex-shrink-0">
                      <span class="material-symbols-outlined notranslate text-lg">warning</span>
                    </div>
                    <div>
                      <p class="text-xs font-bold text-slate-900 dark:text-white">Delayed Response Alert</p>
                      <p class="text-[11px] text-slate-500 mt-0.5">Job #1019 has been unassigned for 45 mins.</p>
                      <p class="text-[9px] text-slate-400 mt-1 font-semibold uppercase">5 mins ago</p>
                    </div>
                  </div>
                </div>
              </div>
              <div class="p-3 text-center">
                <button class="text-xs font-bold text-fsm-primary hover:underline">View all alerts</button>
              </div>
            </div>
          </div>

          <!-- User Dropdown -->
          <div class="relative group ml-1">
            <button class="flex items-center gap-2 p-1.5 pl-1.5 pr-3 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-full transition-all border border-transparent hover:border-slate-100 dark:hover:border-slate-700">
              <div class="size-8 rounded-full bg-slate-200 dark:bg-slate-700 overflow-hidden border border-slate-100 dark:border-slate-600">
                <img src="https://lh3.googleusercontent.com/aida-public/AB6AXuAcPmwW185XBfb0X5bdHqxPAesi50Um4o4vD_xAcDkQ8KUho5p-wvgep4S_uZakcnjOHhoDDnRfnsTucGWrXo2MIQeBZWUnyUiHaOYD-myWUY3GOS2HPFeHNOfmcQUADE2Js_upYoaluGyO7oATwIDNsr4GdZuV2lnmAIG4olW7v6Qtlp1zLoNFUou8ddI_R1R1CRDTV5usU6AQ7cWJRS_3Drg3YMC5przJxkIsgDhUNLEExU4EeFQnAfc5be2DiBrBHhG1T8xvp6w" />
              </div>
              <span class="material-symbols-outlined notranslate text-slate-400 text-lg group-hover:rotate-180 transition-transform duration-300">expand_more</span>
            </button>

            <!-- Dropdown Menu -->
            <div class="absolute right-0 mt-2 w-64 bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-100 dark:border-slate-800 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 transform origin-top-right group-hover:translate-y-0 translate-y-2">
              <div class="p-4 border-b border-slate-50 dark:border-slate-800">
                <p class="text-xs font-black text-slate-900 dark:text-white truncate"><%= @current_user.email %></p>
                <p class="text-[10px] text-slate-400 uppercase font-bold tracking-wider mt-0.5">System Admin</p>
              </div>
              <div class="p-2">
                <a href={~p"/users/settings"} class="flex items-center gap-3 px-3 py-2 rounded-xl text-sm font-semibold text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-fsm-primary transition-colors">
                  <span class="material-symbols-outlined notranslate text-[20px]">person_outline</span>
                  My Profile
                </a>
                <a href="#" class="flex items-center gap-3 px-3 py-2 rounded-xl text-sm font-semibold text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-fsm-primary transition-colors">
                  <span class="material-symbols-outlined notranslate text-[20px]">settings_suggest</span>
                  Organization Settings
                </a>
              </div>
              <div class="p-2 border-t border-slate-50 dark:border-slate-800">
                 <.link href={~p"/users/log-out"} method="delete" class="flex items-center gap-3 px-3 py-2 rounded-xl text-sm font-bold text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors">
                  <span class="material-symbols-outlined notranslate text-[20px]">logout</span>
                  Sign Out
                </.link>
              </div>
            </div>
          </div>

          <!-- Create Button -->
          <button class="flex items-center gap-2 px-5 py-2.5 bg-fsm-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-fsm-primary/20 transition-all ml-2">
            <span class="material-symbols-outlined notranslate text-[20px]">add</span>
            Create New Job
          </button>
        </div>
      </div>
    </header>
    """
  end

  @doc """
  Advanced KPI entry card based on the design image.
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :change, :string, default: nil
  attr :icon, :string, default: nil
  attr :variant, :atom, default: :simple, values: [:simple, :progress, :avatars, :stars]
  attr :progress, :integer, default: nil
  attr :subtext, :string, default: nil

  def kpi_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-fsm-sidebar-dark p-6 rounded-[24px] border border-fsm-border-light dark:border-slate-800/50 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
      <div class="flex items-center justify-between">
        <div class="size-11 rounded-xl bg-fsm-primary/10 flex items-center justify-center">
          <span class="material-symbols-outlined notranslate text-fsm-primary text-[22px]">
            <%= @icon || "analytics" %>
          </span>
        </div>
        <%= if @change do %>
          <span class="text-[12px] font-black text-emerald-500 bg-emerald-500/10 px-2 py-1 rounded-lg">
            <%= @change %>
          </span>
        <% end %>
      </div>

      <div class="space-y-1">
        <p class="text-[12px] font-bold text-slate-400 dark:text-slate-500 tracking-tight">
          <%= @label %>
        </p>
        <p class="text-3xl font-black text-slate-900 dark:text-white tracking-tighter">
          <%= @value %>
        </p>
      </div>

      <div :if={@variant == :progress} class="space-y-2 mt-auto">
        <div class="w-full h-1.5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
          <div class="h-full bg-fsm-primary rounded-full" style={"width: #{@progress}%"}></div>
        </div>
        <p :if={@subtext} class="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider">
          <%= @subtext %>
        </p>
      </div>

      <div :if={@variant == :avatars} class="flex items-center -space-x-2 mt-auto">
        <img
          :for={i <- 1..3}
          src={"https://i.pravatar.cc/150?u=#{i}"}
          class="size-8 rounded-full border-2 border-white dark:border-fsm-sidebar-dark object-cover"
        />
        <div class="size-8 rounded-full border-2 border-white dark:border-fsm-sidebar-dark bg-slate-100 dark:bg-slate-700 flex items-center justify-center text-[10px] font-black text-slate-500">
          +12
        </div>
      </div>

      <div :if={@variant == :stars} class="flex items-center gap-1 mt-auto">
        <span :for={_ <- 1..5} class="material-symbols-outlined notranslate text-amber-400 text-[16px] fill-current">
          star
        </span>
      </div>

      <!-- Mini Chart Placeholder (for Revenue) -->
      <div :if={@variant == :simple && @icon == "payments"} class="flex items-end gap-1 h-8 mt-auto px-1">
        <div :for={h <- [40, 60, 30, 80, 50]} class="flex-1 bg-fsm-primary/20 group-hover:bg-fsm-primary/40 rounded-sm transition-colors" style={"height: #{h}%"}></div>
        <div class="flex-1 bg-fsm-primary rounded-sm" style="height: 100%"></div>
      </div>
    </div>
    """
  end

  @doc """
  Weekly utilization chart component.
  """
  def utilization_chart(assigns) do
    ~H"""
    <div class="bg-white dark:bg-fsm-sidebar-dark p-8 rounded-[32px] border border-fsm-border-light dark:border-slate-800/50 shadow-sm flex flex-col gap-8 h-[400px]">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-lg font-black text-slate-900 dark:text-white tracking-tight">
            Technician Utilization
          </h3>
          <p class="text-xs font-bold text-slate-400 dark:text-slate-500">Weekly efficiency by region</p>
        </div>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2 text-[10px] font-bold text-slate-400 uppercase tracking-widest">
            <div class="size-2 rounded-full bg-fsm-primary"></div>
            North
          </div>
          <div class="flex items-center gap-2 text-[10px] font-bold text-slate-400 uppercase tracking-widest">
            <div class="size-2 rounded-full bg-slate-300 dark:bg-slate-700"></div>
            South
          </div>
        </div>
      </div>

      <div class="flex-1 flex items-end justify-between px-2 gap-4 pb-2">
        <%= for {day, h1, h2} <- [{"MON", 60, 40}, {"TUE", 80, 50}, {"WED", 100, 30}, {"THU", 70, 45}, {"FRI", 90, 60}, {"SAT", 30, 10}, {"SUN", 20, 5}] do %>
          <div class="flex-1 flex flex-col items-center gap-4 group h-full">
            <div class="w-full flex-1 flex flex-col-reverse gap-0.5 min-h-[140px]">
              <div
                class="w-full bg-fsm-primary rounded-t-lg group-hover:brightness-110 transition-all"
                style={"height: #{h1}%"}
              >
              </div>
              <div class="w-full bg-fsm-primary/20 dark:bg-fsm-primary/10 rounded-b-lg" style={"height: #{h2}%"}>
              </div>
            </div>
            <span class="text-[10px] font-black text-slate-400 dark:text-slate-500 tracking-wider flex-shrink-0">
              <%= day %>
            </span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Live activity widget container.
  """
  def live_activity_feed(assigns) do
    ~H"""
    <div class="bg-white dark:bg-fsm-sidebar-dark rounded-[32px] border border-fsm-border-light dark:border-slate-800/50 shadow-sm overflow-hidden flex flex-col h-[400px]">
      <div class="p-6 border-b border-fsm-border-light dark:border-slate-800 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <div class="size-2 rounded-full bg-red-500 animate-pulse"></div>
          <h3 class="text-sm font-black text-slate-900 dark:text-white uppercase tracking-wider">
            Live Activity
          </h3>
        </div>
        <button class="text-[10px] font-black text-fsm-primary hover:underline uppercase tracking-widest">
          View All
        </button>
      </div>
      <div class="flex-1 overflow-y-auto p-4 space-y-2 scrollbar-hide">
        <.activity_feed_item
          title="Job #12804 Completed"
          time="4 mins ago"
          icon="check_circle"
          icon_color="text-emerald-500"
        >
          Tech: Marcus J. • "Customer signed and paid via app."
        </.activity_feed_item>

        <.activity_feed_item
          title="Unassigned Emergency"
          time="12 mins ago"
          icon="error"
          icon_color="text-red-500"
        >
          Sewer Leak • No technician available in Zone 4.
        </.activity_feed_item>

        <.activity_feed_item
          title="Tech Arrived: Sarah L."
          time="18 mins ago"
          icon="location_on"
          icon_color="text-fsm-primary"
        >
          Job #12811 • Client: Henderson Residence
        </.activity_feed_item>

        <.activity_feed_item
          title="Estimate Sent"
          time="32 mins ago"
          icon="send"
          icon_color="text-slate-400"
        >
          Job #12815 • Amt: $1,450.00 • Pending approval
        </.activity_feed_item>
      </div>
    </div>
    """
  end

  defp activity_feed_item(assigns) do
    ~H"""
    <div class="p-4 flex gap-4 hover:bg-slate-50 dark:hover:bg-slate-800/20 transition-all group rounded-2xl">
      <div class="size-10 rounded-full bg-slate-50 dark:bg-slate-800 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
        <span class={["material-symbols-outlined notranslate text-[20px]", @icon_color]}>
          <%= @icon %>
        </span>
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-baseline justify-between mb-0.5 gap-2">
          <p class="text-[13px] font-black text-slate-900 dark:text-white truncate">
            <%= @title %>
          </p>
          <p class="text-[10px] text-slate-400 dark:text-slate-500 font-bold flex-shrink-0">
            <%= @time %>
          </p>
        </div>
        <p class="text-[11px] text-slate-500 dark:text-slate-400 leading-snug line-clamp-2">
          <%= render_slot(@inner_block) %>
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Priority jobs table component.
  """
  def priority_jobs_table(assigns) do
    ~H"""
    <div class="bg-white dark:bg-fsm-sidebar-dark rounded-[32px] border border-fsm-border-light dark:border-slate-800/50 shadow-sm overflow-hidden mt-8">
      <div class="p-6 border-b border-fsm-border-light dark:border-slate-800 flex items-center justify-between">
        <h3 class="text-lg font-black text-slate-900 dark:text-white tracking-tight">
          Next 5 Priority Jobs
        </h3>
        <button class="flex items-center gap-2 text-xs font-bold text-slate-400 hover:text-fsm-primary transition-colors">
          Sorted by Priority <span class="material-symbols-outlined text-sm">expand_more</span>
        </button>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead>
            <tr class="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest border-b border-fsm-border-light dark:border-slate-800">
              <th class="px-8 py-4">Job Details</th>
              <th class="px-8 py-4">Technician</th>
              <th class="px-8 py-4">Schedule</th>
              <th class="px-8 py-4 text-center">Status</th>
              <th class="px-8 py-4"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50 dark:divide-slate-800/50">
            <%= for {id, name, loc, tech, time, status, status_class, color} <- [
              {"#12818", "HVAC Repair", "Downtown Medical Center", "Elena Rossi", "Today, 14:00", "ON THE WAY", "text-amber-600 bg-amber-500/10 border-amber-500/20", "bg-red-500"},
              {"#12819", "Electrical Panel", "Sunrise Apartments", "James Wilson", "Today, 15:30", "SCHEDULED", "text-fsm-primary bg-fsm-primary/10 border-fsm-primary/20", "bg-fsm-primary"}
            ] do %>
              <tr class="group hover:bg-slate-50 dark:hover:bg-slate-800/20 transition-colors">
                <td class="px-8 py-6">
                  <div class="flex items-center gap-4">
                    <div class={[ "w-1 h-10 rounded-full", color ]}></div>
                    <div>
                      <p class="text-[14px] font-black text-slate-900 dark:text-white">
                        <%= id %> - <%= name %>
                      </p>
                      <p class="text-[11px] text-slate-500 dark:text-slate-400 font-medium">
                        <%= loc %>
                      </p>
                    </div>
                  </div>
                </td>
                <td class="px-8 py-6">
                  <div class="flex items-center gap-3">
                    <img
                      src={"https://i.pravatar.cc/150?u=#{tech}"}
                      class="size-8 rounded-full object-cover border-2 border-slate-100 dark:border-slate-700 shadow-sm"
                    />
                    <span class="text-xs font-bold text-slate-700 dark:text-slate-300"><%= tech %></span>
                  </div>
                </td>
                <td class="px-8 py-6">
                  <p class="text-[13px] font-bold text-slate-900 dark:text-white leading-tight">
                    <%= time %>
                  </p>
                  <p class="text-[10px] text-slate-500 dark:text-slate-400 font-medium italic mt-0.5">
                    Duration: 2h 30m
                  </p>
                </td>
                <td class="px-8 py-6">
                  <div class="flex justify-center">
                    <span class={["px-3 py-1 rounded-lg text-[9px] font-black border tracking-wider", status_class]}>
                      <%= status %>
                    </span>
                  </div>
                </td>
                <td class="px-8 py-6 text-right">
                  <button class="size-8 flex items-center justify-center text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors">
                    <span class="material-symbols-outlined notranslate">more_vert</span>
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @doc """
  Live activity item matching the design.
  """
  attr :title, :string, required: true
  attr :time, :string, required: true
  attr :icon, :string, required: true
  attr :icon_class, :string, default: "text-fsm-primary"
  slot :description, required: true
  slot :tags

  def activity_item(assigns) do
    ~H"""
    <div class="p-5 flex items-start gap-4 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-all group">
      <div class="size-11 rounded-2xl bg-slate-50 dark:bg-slate-800/50 flex items-center justify-center flex-shrink-0 border border-slate-100 dark:border-slate-700/50 group-hover:border-fsm-primary/30 transition-colors">
        <span class={["material-symbols-outlined notranslate", @icon_class]}><%= @icon %></span>
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between mb-0.5">
          <p class="text-sm font-bold text-slate-900 dark:text-white"><%= @title %></p>
          <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest"><%= @time %></span>
        </div>
        <div class="text-[13px] leading-relaxed text-slate-600 dark:text-slate-400">
          <%= render_slot(@description) %>
        </div>
        <div :if={@tags != []} class="mt-3 flex items-center gap-2">
          <%= render_slot(@tags) %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Job card in the smart queue.
  """
  attr :status, :string, required: true
  attr :wait_time, :string, required: true
  attr :title, :string, required: true
  attr :location, :string, required: true
  attr :status_class, :string, default: "text-fsm-primary bg-fsm-primary/10"

  def queue_job_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-slate-800/50 p-5 rounded-2xl border border-fsm-border-light dark:border-slate-700/50 custom-shadow hover:border-fsm-primary/30 transition-all group">
      <div class="flex justify-between items-start mb-3">
        <span class={["text-[10px] font-black px-2.5 py-1 rounded-lg uppercase tracking-tight", @status_class]}>
          <%= @status %>
        </span>
        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest"><%= @wait_time %></span>
      </div>
      <h4 class="text-[15px] font-bold text-slate-900 dark:text-white leading-snug group-hover:text-fsm-primary transition-colors cursor-pointer">
        <%= @title %>
      </h4>
      <p class="text-xs text-slate-500 mt-1.5 line-clamp-1 flex items-center gap-1">
        <span class="material-symbols-outlined notranslate text-[14px]">location_on</span>
        <%= @location %>
      </p>
      <div class="mt-5 pt-5 border-t border-slate-50 dark:border-slate-700/50 flex gap-2">
        <button class="flex-1 text-xs font-bold py-2.5 rounded-xl bg-fsm-primary text-white hover:brightness-110 shadow-lg shadow-fsm-primary/15 transition-all">
          Quick Assign
        </button>
        <button class="px-3 py-2 border border-slate-100 dark:border-slate-700/50 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-400 hover:text-slate-600 transition-all">
          <span class="material-symbols-outlined notranslate text-[18px]">more_vert</span>
        </button>
      </div>
    </div>
    """
  end
end
