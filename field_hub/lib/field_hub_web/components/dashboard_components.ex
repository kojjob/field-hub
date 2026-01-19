defmodule FieldHubWeb.DashboardComponents do
  use FieldHubWeb, :html

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
    <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
      <div class="flex items-center justify-between">
        <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
          <.icon
            name={
              Map.get(
                %{
                  "payments" => "hero-banknotes",
                  "star" => "hero-star",
                  "confirmation_number" => "hero-ticket",
                  "trending_up" => "hero-document-chart-bar"
                },
                @icon,
                "hero-chart-bar"
              )
            }
            class="text-primary size-6"
          />
        </div>
        <%= if @change do %>
          <span class="text-[12px] font-black text-emerald-500 bg-emerald-500/10 px-2 py-1 rounded-lg">
            {@change}
          </span>
        <% end %>
      </div>

      <div class="space-y-1">
        <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
          {@label}
        </p>
        <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
          {@value}
        </p>
      </div>

      <div :if={@variant == :progress} class="space-y-2 mt-auto">
        <div class="w-full h-1.5 bg-zinc-100 dark:bg-zinc-800 rounded-full overflow-hidden">
          <div class="h-full bg-primary rounded-full" style={"width: #{@progress}%"}></div>
        </div>
        <p
          :if={@subtext}
          class="text-[10px] text-zinc-400 dark:text-zinc-500 font-bold uppercase tracking-wider"
        >
          {@subtext}
        </p>
      </div>

      <div :if={@variant == :avatars} class="flex items-center -space-x-2 mt-auto">
        <img
          :for={i <- 1..3}
          src={"https://i.pravatar.cc/150?u=#{i}"}
          class="size-8 rounded-full border-2 border-white dark:border-zinc-900 object-cover"
        />
        <div class="size-8 rounded-full border-2 border-white dark:border-zinc-900 bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center text-[10px] font-black text-zinc-500">
          +12
        </div>
      </div>

      <div :if={@variant == :stars} class="flex items-center gap-1 mt-auto">
        <.icon :for={_ <- 1..5} name="hero-star" class="text-amber-400 size-4 fill-current" />
      </div>
      
    <!-- Mini Chart Placeholder (for Revenue) -->
      <div
        :if={@variant == :simple && @icon == "payments"}
        class="flex items-end gap-1 h-8 mt-auto px-1"
      >
        <div
          :for={h <- [40, 60, 30, 80, 50]}
          class="flex-1 bg-primary/20 group-hover:bg-primary/40 rounded-sm transition-colors"
          style={"height: #{h}%"}
        >
        </div>
        <div class="flex-1 bg-primary rounded-sm" style="height: 100%"></div>
      </div>
    </div>
    """
  end

  @doc """
  Weekly utilization chart component.
  """
  def utilization_chart(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 p-8 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-8 h-[400px]">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
            Technician Utilization
          </h3>
          <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500">
            Weekly efficiency by region
          </p>
        </div>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2 text-[10px] font-bold text-zinc-400 uppercase tracking-widest">
            <div class="size-2 rounded-full bg-primary"></div>
            North
          </div>
          <div class="flex items-center gap-2 text-[10px] font-bold text-zinc-400 uppercase tracking-widest">
            <div class="size-2 rounded-full bg-zinc-300 dark:bg-zinc-700"></div>
            South
          </div>
        </div>
      </div>

      <div class="flex-1 flex items-end justify-between px-2 gap-4 pb-2">
        <%= for {day, h1, h2} <- [{"MON", 60, 40}, {"TUE", 80, 50}, {"WED", 100, 30}, {"THU", 70, 45}, {"FRI", 90, 60}, {"SAT", 30, 10}, {"SUN", 20, 5}] do %>
          <div class="flex-1 flex flex-col items-center gap-4 group h-full">
            <div class="w-full flex-1 flex flex-col-reverse gap-0.5 min-h-[140px]">
              <div
                class="w-full bg-primary rounded-t-lg group-hover:brightness-110 transition-all"
                style={"height: #{h1}%"}
              >
              </div>
              <div
                class="w-full bg-primary/20 dark:bg-primary/10 rounded-b-lg"
                style={"height: #{h2}%"}
              >
              </div>
            </div>
            <span class="text-[10px] font-black text-zinc-400 dark:text-zinc-500 tracking-wider flex-shrink-0">
              {day}
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
    <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden flex flex-col h-[400px]">
      <div class="p-6 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <div class="size-2 rounded-full bg-red-500 animate-pulse"></div>
          <h3 class="text-sm font-black text-zinc-900 dark:text-white uppercase tracking-wider">
            Live Activity
          </h3>
        </div>
        <button class="text-[10px] font-black text-primary hover:underline uppercase tracking-widest">
          View All
        </button>
      </div>
      <div class="flex-1 overflow-y-auto p-4 space-y-2 scrollbar-hide">
        <.activity_feed_item
          title="Job #12804 Completed"
          time="4 mins ago"
          icon="hero-check-circle"
          icon_color="text-emerald-500"
        >
          Tech: Marcus J. • "Customer signed and paid via app."
        </.activity_feed_item>

        <.activity_feed_item
          title="Unassigned Emergency"
          time="12 mins ago"
          icon="hero-exclamation-circle"
          icon_color="text-red-500"
        >
          Sewer Leak • No technician available in Zone 4.
        </.activity_feed_item>

        <.activity_feed_item
          title="Tech Arrived: Sarah L."
          time="18 mins ago"
          icon="hero-map-pin"
          icon_color="text-primary"
        >
          Job #12811 • Client: Henderson Residence
        </.activity_feed_item>

        <.activity_feed_item
          title="Estimate Sent"
          time="32 mins ago"
          icon="hero-paper-airplane"
          icon_color="text-zinc-400"
        >
          Job #12815 • Amt: $1,450.00 • Pending approval
        </.activity_feed_item>
      </div>
    </div>
    """
  end

  defp activity_feed_item(assigns) do
    ~H"""
    <div class="p-4 flex gap-4 hover:bg-zinc-50 dark:hover:bg-zinc-800/20 transition-all group rounded-2xl">
      <div class="size-10 rounded-full bg-zinc-50 dark:bg-zinc-800 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
        <.icon name={@icon} class={["size-5", @icon_color]} />
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-baseline justify-between mb-0.5 gap-2">
          <p class="text-[13px] font-black text-zinc-900 dark:text-white truncate">
            {@title}
          </p>
          <p class="text-[10px] text-zinc-400 dark:text-zinc-500 font-bold flex-shrink-0">
            {@time}
          </p>
        </div>
        <p class="text-[11px] text-zinc-500 dark:text-zinc-400 leading-snug line-clamp-2">
          {render_slot(@inner_block)}
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
    <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden mt-8">
      <div class="p-6 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between">
        <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
          Next 5 Priority Jobs
        </h3>
        <button class="flex items-center gap-2 text-xs font-bold text-zinc-400 hover:text-primary transition-colors">
          Sorted by Priority <.icon name="hero-chevron-down" class="size-4" />
        </button>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead>
            <tr class="text-[10px] font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-widest border-b border-zinc-100 dark:border-zinc-800">
              <th class="px-8 py-4">Job Details</th>
              <th class="px-8 py-4">Technician</th>
              <th class="px-8 py-4">Schedule</th>
              <th class="px-8 py-4 text-center">Status</th>
              <th class="px-8 py-4"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-50 dark:divide-zinc-800/50">
            <%= for {id, name, loc, tech, time, status, status_class, color} <- [
              {"#12818", "HVAC Repair", "Downtown Medical Center", "Elena Rossi", "Today, 14:00", "ON THE WAY", "text-amber-600 bg-amber-500/10 border-amber-500/20", "bg-red-500"},
              {"#12819", "Electrical Panel", "Sunrise Apartments", "James Wilson", "Today, 15:30", "SCHEDULED", "text-primary bg-primary/10 border-primary/20", "bg-primary"}
            ] do %>
              <tr class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/20 transition-colors">
                <td class="px-8 py-6">
                  <div class="flex items-center gap-4">
                    <div class={["w-1 h-10 rounded-full", color]}></div>
                    <div>
                      <p class="text-[14px] font-black text-zinc-900 dark:text-white">
                        {id} - {name}
                      </p>
                      <p class="text-[11px] text-zinc-500 dark:text-zinc-400 font-medium">
                        {loc}
                      </p>
                    </div>
                  </div>
                </td>
                <td class="px-8 py-6">
                  <div class="flex items-center gap-3">
                    <img
                      src={"https://i.pravatar.cc/150?u=#{tech}"}
                      class="size-8 rounded-full object-cover border-2 border-zinc-100 dark:border-zinc-800 shadow-sm"
                    />
                    <span class="text-xs font-bold text-zinc-700 dark:text-zinc-300">{tech}</span>
                  </div>
                </td>
                <td class="px-8 py-6">
                  <p class="text-[13px] font-bold text-zinc-900 dark:text-white leading-tight">
                    {time}
                  </p>
                  <p class="text-[10px] text-zinc-500 dark:text-zinc-400 font-medium italic mt-0.5">
                    Duration: 2h 30m
                  </p>
                </td>
                <td class="px-8 py-6">
                  <div class="flex justify-center">
                    <span class={[
                      "px-3 py-1 rounded-lg text-[9px] font-black border tracking-wider",
                      status_class
                    ]}>
                      {status}
                    </span>
                  </div>
                </td>
                <td class="px-8 py-6 text-right">
                  <button class="size-8 flex items-center justify-center text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200 transition-colors">
                    <.icon name="hero-ellipsis-vertical" class="size-5" />
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
  attr :icon_class, :string, default: "text-primary"
  slot :description, required: true
  slot :tags

  def activity_item(assigns) do
    ~H"""
    <div class="p-5 flex items-start gap-4 hover:bg-zinc-50 dark:hover:bg-zinc-800/30 transition-all group">
      <div class="size-11 rounded-2xl bg-zinc-50 dark:bg-zinc-800/50 flex items-center justify-center flex-shrink-0 border border-zinc-200 dark:border-zinc-800 group-hover:border-primary/30 transition-colors">
        <.icon name={@icon} class={["size-5", @icon_class]} />
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between mb-0.5">
          <p class="text-sm font-bold text-zinc-900 dark:text-white">{@title}</p>
          <span class="text-[10px] font-bold text-zinc-400 uppercase tracking-widest">{@time}</span>
        </div>
        <div class="text-[13px] leading-relaxed text-zinc-600 dark:text-zinc-400">
          {render_slot(@description)}
        </div>
        <div :if={@tags != []} class="mt-3 flex items-center gap-2">
          {render_slot(@tags)}
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
  attr :status_class, :string, default: "text-primary bg-primary/10"

  def queue_job_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 p-5 rounded-2xl border border-zinc-200 dark:border-zinc-800 shadow-sm hover:border-primary/30 transition-all group">
      <div class="flex justify-between items-start mb-3">
        <span class={[
          "text-[10px] font-black px-2.5 py-1 rounded-lg uppercase tracking-tight",
          @status_class
        ]}>
          {@status}
        </span>
        <span class="text-[10px] font-bold text-zinc-400 uppercase tracking-widest">
          {@wait_time}
        </span>
      </div>
      <h4 class="text-[15px] font-bold text-zinc-900 dark:text-white leading-snug group-hover:text-primary transition-colors cursor-pointer">
        {@title}
      </h4>
      <p class="text-xs text-zinc-500 mt-1.5 line-clamp-1 flex items-center gap-1">
        <.icon name="hero-map-pin" class="size-3.5" />
        {@location}
      </p>
      <div class="mt-5 pt-5 border-t border-zinc-100 dark:border-zinc-800 flex gap-2">
        <button class="flex-1 text-xs font-bold py-2.5 rounded-xl bg-primary text-white hover:brightness-110 shadow-lg shadow-primary/15 transition-all">
          Quick Assign
        </button>
        <button class="px-3 py-2 border border-zinc-200 dark:border-zinc-800 rounded-xl hover:bg-zinc-50 dark:hover:bg-zinc-800 text-zinc-400 hover:text-zinc-600 transition-all">
          <.icon name="hero-ellipsis-vertical" class="size-5" />
        </button>
      </div>
    </div>
    """
  end
end
