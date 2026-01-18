defmodule FieldHubWeb.ReportLive.Index do
  use FieldHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Reports")
      |> assign(:current_nav, :reports)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10 pb-20">
      <!-- Page Heading -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            Analytics
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            Performance Reports
          </h2>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
            <.icon name="hero-calendar" class="size-5" /> Last 30 Days
          </button>
          <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
            <.icon name="hero-arrow-down-tray" class="size-5" /> Export
          </button>
        </div>
      </div>

      <!-- KPI Cards Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <!-- Avg Job Duration Card -->
        <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
          <div class="flex items-center justify-between">
            <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
              <.icon name="hero-clock" class="text-primary size-6" />
            </div>
            <span class="text-[12px] font-black text-emerald-500 bg-emerald-500/10 px-2 py-1 rounded-lg">
              -12min
            </span>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
              Avg Job Duration
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              1h 42m
            </p>
          </div>
          <p class="text-[10px] text-zinc-400 dark:text-zinc-500 font-bold uppercase tracking-wider mt-auto">
            12 min faster than last month
          </p>
        </div>

        <!-- First-Time Fix Rate Card -->
        <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
          <div class="flex items-center justify-between">
            <div class="size-11 rounded-xl bg-emerald-500/10 flex items-center justify-center">
              <.icon name="hero-wrench-screwdriver" class="text-emerald-500 size-6" />
            </div>
            <span class="text-[12px] font-black text-emerald-500 bg-emerald-500/10 px-2 py-1 rounded-lg">
              +2.3%
            </span>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
              First-Time Fix Rate
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              94.2%
            </p>
          </div>
          <div class="space-y-2 mt-auto">
            <div class="w-full h-1.5 bg-zinc-100 dark:bg-zinc-800 rounded-full overflow-hidden">
              <div class="h-full bg-emerald-500 rounded-full" style="width: 94%"></div>
            </div>
            <p class="text-[10px] text-zinc-400 dark:text-zinc-500 font-bold uppercase tracking-wider">
              Industry avg: 77%
            </p>
          </div>
        </div>

        <!-- Revenue per Technician Card -->
        <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
          <div class="flex items-center justify-between">
            <div class="size-11 rounded-xl bg-blue-500/10 flex items-center justify-center">
              <.icon name="hero-currency-dollar" class="text-blue-500 size-6" />
            </div>
            <span class="text-[12px] font-black text-emerald-500 bg-emerald-500/10 px-2 py-1 rounded-lg">
              +$420
            </span>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
              Revenue per Tech
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              $8,240
            </p>
          </div>
          <div class="flex items-end gap-1 h-8 mt-auto px-1">
            <div :for={h <- [50, 65, 55, 70, 60, 85]} class="flex-1 bg-blue-500/20 group-hover:bg-blue-500/40 rounded-sm transition-colors" style={"height: #{h}%"}></div>
          </div>
        </div>

        <!-- Avg Response Time Card -->
        <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
          <div class="flex items-center justify-between">
            <div class="size-11 rounded-xl bg-amber-500/10 flex items-center justify-center">
              <.icon name="hero-bolt" class="text-amber-500 size-6" />
            </div>
            <span class="text-[12px] font-black text-emerald-500 bg-emerald-500/10 px-2 py-1 rounded-lg">
              -8min
            </span>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
              Avg Response Time
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              28 min
            </p>
          </div>
          <div class="flex items-center gap-1 mt-auto">
            <.icon :for={_ <- 1..5} name="hero-star" class="text-amber-400 size-4 fill-current" />
            <span class="text-[10px] text-zinc-400 ml-2 font-bold">4.9 customer rating</span>
          </div>
        </div>
      </div>


      <!-- Charts Section -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <!-- Job Completion Trend -->
        <div class="xl:col-span-2 bg-white dark:bg-zinc-900 p-8 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <div class="flex items-center justify-between mb-8">
            <div>
              <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                Job Completion Trend
              </h3>
              <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500">
                Jobs completed per week (last 12 weeks)
              </p>
            </div>
            <div class="flex items-center gap-4">
              <div class="flex items-center gap-2 text-[10px] font-bold text-zinc-400 uppercase tracking-widest">
                <div class="size-2 rounded-full bg-primary"></div>
                Completed
              </div>
              <div class="flex items-center gap-2 text-[10px] font-bold text-zinc-400 uppercase tracking-widest">
                <div class="size-2 rounded-full bg-amber-400"></div>
                Callbacks
              </div>
            </div>
          </div>
          <!-- Chart -->
          <div class="h-64 flex items-end gap-3 px-4">
            <div :for={{jobs, i} <- Enum.with_index([12, 15, 18, 14, 22, 19, 25, 21, 28, 24, 30, 27])} class="flex-1 flex flex-col items-center gap-2">
              <div class="w-full flex flex-col gap-1 items-center">
                <div class="w-full bg-primary rounded-lg transition-colors hover:bg-primary/80" style={"height: #{jobs * 3}px"}></div>
                <div class="w-full bg-amber-400/60 rounded-lg" style={"height: #{rem(jobs, 5) + 2}px"}></div>
              </div>
              <span class="text-[9px] font-bold text-zinc-400">W{i + 1}</span>
            </div>
          </div>
        </div>

        <!-- Technician Performance -->
        <div class="xl:col-span-1 bg-white dark:bg-zinc-900 p-8 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
              Top Technicians
            </h3>
            <button class="text-xs font-bold text-primary hover:underline">
              View All
            </button>
          </div>
          <div class="space-y-4">
            <div :for={{name, jobs, rating} <- [{"Alex Johnson", 42, 4.9}, {"Mike Torres", 38, 4.8}, {"Chris Davis", 35, 4.7}, {"Sarah Kim", 31, 4.9}]} class="flex items-center gap-4">
              <img src={"https://i.pravatar.cc/150?u=#{name}"} class="size-10 rounded-full object-cover" />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-bold text-zinc-900 dark:text-white truncate">{name}</p>
                <p class="text-xs text-zinc-400">{jobs} jobs completed</p>
              </div>
              <div class="flex items-center gap-1 text-xs font-bold text-amber-500">
                <.icon name="hero-star" class="size-4 fill-current" />
                {rating}
              </div>
            </div>
          </div>
        </div>
      </div>


      <!-- Recent Activity Table -->
      <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
        <div class="px-8 py-6 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between">
          <div>
            <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
              Recent Completed Jobs
            </h3>
            <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500">
              Latest job completions this month
            </p>
          </div>
          <.link navigate={~p"/jobs"} class="text-sm font-bold text-primary hover:underline flex items-center gap-1">
            View All <.icon name="hero-arrow-right" class="size-4" />
          </.link>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-zinc-50 dark:bg-zinc-800/50">
              <tr>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">Job</th>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">Customer</th>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">Technician</th>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">Amount</th>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">Status</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
              <tr :for={{job, customer, tech, amount} <- [{"HVAC Maintenance", "John Smith", "Alex J.", "$450"}, {"Pipe Repair", "Sarah Connor", "Mike T.", "$280"}, {"Electrical Check", "Tom Wilson", "Chris D.", "$520"}, {"AC Installation", "Emily Brown", "Alex J.", "$1,200"}]} class="hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors">
                <td class="px-8 py-4 text-sm font-bold text-zinc-900 dark:text-white">{job}</td>
                <td class="px-8 py-4 text-sm text-zinc-600 dark:text-zinc-400">{customer}</td>
                <td class="px-8 py-4 text-sm text-zinc-600 dark:text-zinc-400">{tech}</td>
                <td class="px-8 py-4 text-sm font-bold text-zinc-900 dark:text-white">{amount}</td>
                <td class="px-8 py-4">
                  <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                    <div class="size-1.5 rounded-full bg-emerald-500"></div>
                    Completed
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
