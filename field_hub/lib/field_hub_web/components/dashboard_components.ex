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
  attr :jobs, :list, default: []

  def priority_jobs_table(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
      <div class="p-8 border-b border-zinc-100 dark:border-zinc-800 flex items-center justify-between">
        <div>
          <h3 class="text-xl font-black text-zinc-900 dark:text-white tracking-tight">
            Next 5 Priority Jobs
          </h3>
          <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-widest mt-1">
            Dispatch Queue • Real-time
          </p>
        </div>
        <.link
          navigate="/jobs"
          class="px-5 py-2.5 bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-xl text-xs font-black text-zinc-600 dark:text-zinc-300 flex items-center gap-2 hover:bg-zinc-100 transition-all"
        >
          View All Jobs <.icon name="hero-arrow-right" class="size-4" />
        </.link>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead>
            <tr class="text-[10px] font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-widest border-b border-zinc-50 dark:border-zinc-800">
              <th class="px-8 py-5">Job Details</th>
              <th class="px-8 py-5">Technician</th>
              <th class="px-8 py-5">Schedule</th>
              <th class="px-8 py-5 text-center">Status</th>
              <th class="px-8 py-5"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-50 dark:divide-zinc-800/50 text-dashboard">
            <%= if @jobs == [] do %>
              <tr>
                <td colspan="5" class="px-8 py-12 text-center">
                  <div class="flex flex-col items-center gap-3 text-zinc-400">
                    <.icon name="hero-clipboard-document-list" class="size-10" />
                    <p class="text-sm font-medium">No priority jobs scheduled</p>
                  </div>
                </td>
              </tr>
            <% else %>
              <%= for job <- @jobs do %>
                <tr class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/20 transition-all duration-300">
                  <td class="px-8 py-6">
                    <div class="flex items-center gap-4">
                      <div class={["w-1 h-10 rounded-full", status_indicator_color(job.status)]}></div>
                      <div>
                        <p class="text-[15px] font-black text-zinc-900 dark:text-white group-hover:text-primary transition-colors">
                          #{job.number} - {job.title}
                        </p>
                        <p class="text-[12px] text-zinc-500 dark:text-zinc-400 font-bold mt-0.5">
                          {job.service_address || job.customer.name}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td class="px-8 py-6">
                    <div class="flex items-center gap-3">
                      <div class="size-9 rounded-xl border-2 border-white dark:border-zinc-800 shadow-sm overflow-hidden group-hover:scale-110 transition-transform bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
                        <%= if job.technician do %>
                          <span class="text-xs font-bold text-zinc-600 dark:text-zinc-300">
                            {String.first(job.technician.name)}
                          </span>
                        <% else %>
                          <.icon name="hero-user" class="size-4 text-zinc-400" />
                        <% end %>
                      </div>
                      <span class="text-sm font-black text-zinc-700 dark:text-zinc-300">
                        {(job.technician && job.technician.name) || "Unassigned"}
                      </span>
                    </div>
                  </td>
                  <td class="px-8 py-6">
                    <p class="text-[14px] font-black text-zinc-900 dark:text-white leading-tight">
                      {format_schedule(job.scheduled_date)}
                    </p>
                    <div class="flex items-center gap-1.5 mt-1">
                      <div class="size-1.5 rounded-full bg-zinc-200 dark:bg-zinc-700"></div>
                      <p class="text-[11px] text-zinc-500 dark:text-zinc-400 font-bold uppercase tracking-wider">
                        Est. {format_duration(job.estimated_duration)}
                      </p>
                    </div>
                  </td>
                  <td class="px-8 py-6">
                    <div class="flex justify-center">
                      <span class={[
                        "px-3.5 py-1.5 rounded-xl text-[10px] font-black border tracking-widest shadow-sm",
                        status_badge_class(job.status)
                      ]}>
                        {String.upcase(job.status || "pending")}
                      </span>
                    </div>
                  </td>
                  <td class="px-8 py-6 text-right">
                    <.link
                      navigate={"/jobs/#{job.number}"}
                      class="size-10 flex items-center justify-center rounded-xl hover:bg-white dark:hover:bg-zinc-800 text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition-all border border-transparent hover:border-zinc-200"
                    >
                      <.icon name="hero-arrow-right" class="size-5" />
                    </.link>
                  </td>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp status_indicator_color("in_progress"), do: "bg-amber-500"
  defp status_indicator_color("en_route"), do: "bg-amber-500"
  defp status_indicator_color("scheduled"), do: "bg-primary"
  defp status_indicator_color("pending"), do: "bg-zinc-400"
  defp status_indicator_color(_), do: "bg-zinc-400"

  defp status_badge_class("in_progress"), do: "text-amber-600 bg-amber-500/10 border-amber-500/20"
  defp status_badge_class("en_route"), do: "text-amber-600 bg-amber-500/10 border-amber-500/20"
  defp status_badge_class("scheduled"), do: "text-primary bg-primary/10 border-primary/20"
  defp status_badge_class(_), do: "text-zinc-500 bg-zinc-100 border-zinc-200"

  defp format_schedule(nil), do: "Not scheduled"

  defp format_schedule(date) do
    today = Date.utc_today()
    tomorrow = Date.add(today, 1)

    cond do
      Date.compare(date, today) == :eq -> "Today"
      Date.compare(date, tomorrow) == :eq -> "Tomorrow"
      true -> Calendar.strftime(date, "%b %d, %Y")
    end
  end

  defp format_duration(nil), do: "TBD"
  defp format_duration(minutes) when minutes < 60, do: "#{minutes}m"

  defp format_duration(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    if mins > 0, do: "#{hours}h #{mins}m", else: "#{hours}h"
  end

  @doc """
  Financial health overview component.
  """
  attr :stats, :map, required: true

  def billing_overview(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 p-8 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm h-full flex flex-col gap-8">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-xl font-black text-zinc-900 dark:text-white tracking-tight">
            Financial Health
          </h3>
          <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-widest">
            Invoicing & Revenue Stats
          </p>
        </div>
        <div class="size-12 rounded-2xl bg-emerald-500/10 flex items-center justify-center">
          <.icon name="hero-banknotes" class="size-6 text-emerald-500" />
        </div>
      </div>

      <div class="grid grid-cols-2 gap-6">
        <div class="space-y-1 p-5 rounded-2xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-100 dark:border-zinc-800">
          <p class="text-[10px] font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-widest">
            Total Paid
          </p>
          <p class="text-2xl font-black text-emerald-600 tracking-tighter">
            ${format_large_money(@stats.total_paid)}
          </p>
        </div>
        <div class="space-y-1 p-5 rounded-2xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-100 dark:border-zinc-800">
          <p class="text-[10px] font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-widest">
            Outstanding
          </p>
          <p class="text-2xl font-black text-amber-600 tracking-tighter">
            ${format_large_money(@stats.outstanding)}
          </p>
        </div>
      </div>

      <div class="space-y-4 flex-1">
        <div class="flex items-center justify-between text-xs font-bold">
          <span class="text-zinc-500 uppercase tracking-widest">Billing Progress</span>
          <span class="text-zinc-900 dark:text-white">{billing_progress(@stats)}%</span>
        </div>
        <div class="h-3 w-full bg-zinc-100 dark:bg-zinc-800 rounded-full overflow-hidden flex gap-0.5">
          <div
            class="h-full bg-emerald-500 rounded-l-full transition-all duration-1000"
            style={"width: #{billing_progress(@stats)}%"}
          >
          </div>
          <div
            class="h-full bg-amber-500 transition-all duration-1000"
            style={"width: #{outstanding_percent(@stats)}%"}
          >
          </div>
          <div class="h-full flex-1 bg-zinc-200 dark:bg-zinc-700 rounded-r-full"></div>
        </div>
        <div class="flex gap-4">
          <div class="flex items-center gap-2">
            <div class="size-2 rounded-full bg-emerald-500"></div>
            <span class="text-[10px] font-black text-zinc-400 uppercase tracking-widest">Paid</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="size-2 rounded-full bg-amber-500"></div>
            <span class="text-[10px] font-black text-zinc-400 uppercase tracking-widest">
              Pending
            </span>
          </div>
        </div>
      </div>

      <button class="w-full py-4 rounded-2xl bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 text-sm font-black hover:brightness-110 transition-all shadow-xl shadow-zinc-900/10 active:scale-[0.98]">
        Download Fiscal Report
      </button>
    </div>
    """
  end

  defp format_large_money(nil), do: "0.00"

  defp format_large_money(%Decimal{} = amount) do
    cond do
      Decimal.gt?(amount, 1_000_000) ->
        Decimal.div(amount, 1_000_000)
        |> Decimal.round(1)
        |> Decimal.to_string(:normal)
        |> Kernel.<>("M")

      Decimal.gt?(amount, 1_000) ->
        Decimal.div(amount, 1_000)
        |> Decimal.round(1)
        |> Decimal.to_string(:normal)
        |> Kernel.<>("K")

      true ->
        Decimal.round(amount, 2) |> Decimal.to_string(:normal)
    end
  end

  defp format_large_money(amount) when is_number(amount) do
    if amount >= 1000 do
      "#{Float.round(amount / 1000, 1)}K"
    else
      :erlang.float_to_binary(amount / 1, decimals: 2)
    end
  end

  defp billing_progress(stats) do
    total = stats.total_invoiced |> Decimal.to_float()
    paid = stats.total_paid |> Decimal.to_float()
    if total > 0, do: round(paid / total * 100), else: 0
  end

  defp outstanding_percent(stats) do
    total = stats.total_invoiced |> Decimal.to_float()
    outstanding = stats.outstanding |> Decimal.to_float()
    if total > 0, do: round(outstanding / total * 100), else: 0
  end

  @doc """
  Revenue trend chart component.
  """
  attr :data, :list, default: []

  def revenue_trend_chart(assigns) do
    # Convert data to chart-friendly format with normalized heights
    chart_data = normalize_chart_data(assigns.data)
    assigns = assign(assigns, :chart_data, chart_data)

    ~H"""
    <div class="bg-white dark:bg-zinc-900 p-8 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-10 h-full">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-xl font-black text-zinc-900 dark:text-white tracking-tight">
            Revenue Performance
          </h3>
          <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-widest mt-1">
            Weekly Cycle Comparison
          </p>
        </div>
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-primary/10 border border-primary/20 text-[10px] font-black text-primary uppercase tracking-wider">
            Current Week
          </div>
          <div class="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-[10px] font-black text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
            Previous
          </div>
        </div>
      </div>

      <div class="flex-1 flex items-end justify-between px-2 gap-5 group mt-5">
        <%= for %{day: day, current_height: h1, previous_height: h2} <- @chart_data do %>
          <div class="flex-1 flex flex-col items-center gap-6 group/bar h-full">
            <div class="w-full flex-1 flex flex-row items-end justify-center gap-1.5">
              <div
                class="w-3 bg-primary rounded-full transition-all duration-700 group-hover/bar:scale-y-110 group-hover/bar:brightness-110 shadow-lg shadow-primary/20"
                style={"height: #{h1}%"}
              >
              </div>
              <div
                class="w-3 bg-zinc-100 dark:bg-zinc-800 rounded-full transition-all duration-1000 delay-100"
                style={"height: #{h2}%"}
              >
              </div>
            </div>
            <span class="text-[11px] font-black text-zinc-400 dark:text-zinc-500 tracking-widest group-hover/bar:text-primary transition-colors">
              {day}
            </span>
          </div>
        <% end %>
      </div>

      <div class="pt-8 border-t border-zinc-50 dark:border-zinc-800 flex items-center justify-between">
        <div class="flex items-center gap-6">
          <div class="space-y-1">
            <p class="text-[10px] font-black text-zinc-400 uppercase tracking-widest">Avg daily</p>
            <p class="text-lg font-black text-zinc-900 dark:text-white">{format_average(@data)}</p>
          </div>
          <div class="space-y-1">
            <p class="text-[10px] font-black text-zinc-400 uppercase tracking-widest">Peak week</p>
            <p class="text-lg font-black text-zinc-900 dark:text-white">{format_total(@data)}</p>
          </div>
        </div>
        <div class="flex -space-x-2">
          <img
            :for={i <- 1..3}
            src={"https://i.pravatar.cc/150?u=#{i+10}"}
            class="size-8 rounded-full border-2 border-white dark:border-zinc-900 object-cover"
          />
        </div>
      </div>
    </div>
    """
  end

  defp normalize_chart_data([]), do: default_chart_data()

  defp normalize_chart_data(data) do
    # Find max value to normalize heights
    max_val =
      data
      |> Enum.flat_map(fn %{current: c, previous: p} ->
        [Decimal.to_float(c || Decimal.new(0)), Decimal.to_float(p || Decimal.new(0))]
      end)
      |> Enum.max(fn -> 1 end)

    max_val = if max_val == 0, do: 1, else: max_val

    Enum.map(data, fn %{day: day, current: current, previous: previous} ->
      %{
        day: day,
        current_height: round(Decimal.to_float(current || Decimal.new(0)) / max_val * 100),
        previous_height: round(Decimal.to_float(previous || Decimal.new(0)) / max_val * 100)
      }
    end)
  end

  defp default_chart_data do
    for day <- ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"] do
      %{day: day, current_height: 10, previous_height: 5}
    end
  end

  defp format_average([]), do: "$0"

  defp format_average(data) do
    total =
      Enum.reduce(data, Decimal.new(0), fn %{current: c}, acc ->
        Decimal.add(acc, c || Decimal.new(0))
      end)

    avg = Decimal.div(total, Decimal.new(length(data)))
    "$#{Decimal.to_string(Decimal.round(avg, 0), :normal)}"
  end

  defp format_total([]), do: "$0"

  defp format_total(data) do
    total =
      Enum.reduce(data, Decimal.new(0), fn %{current: c}, acc ->
        Decimal.add(acc, c || Decimal.new(0))
      end)

    if Decimal.gt?(total, Decimal.new(1000)) do
      k = Decimal.div(total, Decimal.new(1000)) |> Decimal.round(1)
      "$#{Decimal.to_string(k, :normal)}K"
    else
      "$#{Decimal.to_string(Decimal.round(total, 0), :normal)}"
    end
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
