defmodule FieldHubWeb.ReportLive.Index do
  use FieldHubWeb, :live_view

  alias FieldHub.Reports

  @range_days 30

  @impl true
  def mount(_params, _session, socket) do
    range = default_range()

    {kpis, tech_stats, trend, recent_jobs} =
      case socket.assigns[:current_scope] do
        %FieldHub.Accounts.Scope{} = current_scope ->
          {
            Reports.get_kpis(current_scope, range),
            Reports.get_technician_performance(current_scope, range),
            Reports.get_job_completion_trend(current_scope, range),
            Reports.get_recent_completed_jobs(current_scope, 6)
          }

        _ ->
          {
            %{
              total_revenue: Decimal.new(0),
              completed_jobs_count: 0,
              avg_job_duration_minutes: 0
            },
            [],
            [],
            []
          }
      end

    revenue_per_tech =
      case {kpis.total_revenue, length(tech_stats)} do
        {%Decimal{} = total_revenue, tech_count} when tech_count > 0 ->
          Decimal.div(total_revenue, Decimal.new(tech_count))

        _ ->
          Decimal.new(0)
      end

    trend_points = Enum.take(trend, -12)

    socket =
      socket
      |> assign(:page_title, "Reports")
      |> assign(:current_nav, :reports)
      |> assign(:range, range)
      |> assign(:range_days, @range_days)
      |> assign(:kpis, kpis)
      |> assign(:revenue_per_tech, revenue_per_tech)
      |> assign(:trend_points, trend_points)
      |> assign(:top_techs, Enum.take(tech_stats, 4))
      |> assign(:recent_jobs, recent_jobs)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <% {start_date, end_date} = @range %>
    <% export_href =
      ~p"/reports/export?start=#{Date.to_iso8601(start_date)}&end=#{Date.to_iso8601(end_date)}" %>

    <div id="reports-page" class="space-y-10 pb-20">
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
          <button
            id="reports-range-btn"
            class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2"
          >
            <.icon name="hero-calendar" class="size-5" /> Last {@range_days} Days
          </button>
          <.link
            id="reports-export-btn"
            href={export_href}
            class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2"
          >
            <.icon name="hero-arrow-down-tray" class="size-5" /> Export
          </.link>
        </div>
      </div>
      
    <!-- KPI Cards Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
          <div class="flex items-center justify-between">
            <div class="size-11 rounded-xl bg-blue-500/10 flex items-center justify-center">
              <.icon name="hero-currency-dollar" class="text-blue-500 size-6" />
            </div>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
              Total Revenue
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              {format_currency(@kpis.total_revenue)}
            </p>
          </div>
          <p class="text-[10px] text-zinc-400 dark:text-zinc-500 font-bold uppercase tracking-wider mt-auto">
            Completed jobs only
          </p>
        </div>

        <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
          <div class="flex items-center justify-between">
            <div class="size-11 rounded-xl bg-primary/10 flex items-center justify-center">
              <.icon name="hero-check-circle" class="text-primary size-6" />
            </div>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
              Completed Jobs
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              {@kpis.completed_jobs_count}
            </p>
          </div>
          <p class="text-[10px] text-zinc-400 dark:text-zinc-500 font-bold uppercase tracking-wider mt-auto">
            Last {@range_days} days
          </p>
        </div>

        <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
          <div class="flex items-center justify-between">
            <div class="size-11 rounded-xl bg-amber-500/10 flex items-center justify-center">
              <.icon name="hero-clock" class="text-amber-500 size-6" />
            </div>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
              Avg Job Duration
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              {format_duration_minutes(@kpis.avg_job_duration_minutes)}
            </p>
          </div>
          <p class="text-[10px] text-zinc-400 dark:text-zinc-500 font-bold uppercase tracking-wider mt-auto">
            Based on jobs with timestamps
          </p>
        </div>

        <div class="bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm flex flex-col gap-5 group transition-all hover:translate-y-[-2px]">
          <div class="flex items-center justify-between">
            <div class="size-11 rounded-xl bg-emerald-500/10 flex items-center justify-center">
              <.icon name="hero-user-group" class="text-emerald-500 size-6" />
            </div>
          </div>
          <div class="space-y-1">
            <p class="text-[12px] font-bold text-zinc-400 dark:text-zinc-500 tracking-tight">
              Revenue per Technician
            </p>
            <p class="text-3xl font-black text-zinc-900 dark:text-white tracking-tighter">
              {format_currency(@revenue_per_tech)}
            </p>
          </div>
          <p class="text-[10px] text-zinc-400 dark:text-zinc-500 font-bold uppercase tracking-wider mt-auto">
            Across active techs in period
          </p>
        </div>
      </div>
      
    <!-- Charts Section -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <div class="xl:col-span-2 bg-white dark:bg-zinc-900 p-8 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <div class="flex items-center justify-between mb-8">
            <div>
              <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
                Job Completion Trend
              </h3>
              <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500">
                Completed jobs per day (last 12 days)
              </p>
            </div>
          </div>

          <% max_count = Enum.max([1 | Enum.map(@trend_points, & &1.count)]) %>

          <div id="reports-trend-chart" class="h-64 flex items-end gap-3 px-4">
            <div :for={point <- @trend_points} class="flex-1 flex flex-col items-center gap-2">
              <div class="w-full flex flex-col gap-1 items-center">
                <div
                  class="w-full bg-primary rounded-lg transition-colors hover:bg-primary/80"
                  style={"height: #{round((point.count / max_count) * 180) + 8}px"}
                  title={"#{point.count} completed"}
                >
                </div>
              </div>
              <span class="text-[9px] font-bold text-zinc-400">{format_date_short(point.date)}</span>
            </div>
          </div>
        </div>

        <div class="xl:col-span-1 bg-white dark:bg-zinc-900 p-8 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-black text-zinc-900 dark:text-white tracking-tight">
              Top Technicians
            </h3>
          </div>

          <div class="space-y-4">
            <div :for={tech <- @top_techs} class="flex items-center gap-4">
              <img
                src={tech_avatar_url(tech)}
                class="size-10 rounded-full object-cover bg-zinc-100 dark:bg-zinc-800"
                alt=""
              />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-bold text-zinc-900 dark:text-white truncate">{tech.name}</p>
                <p class="text-xs text-zinc-400">
                  {tech.jobs_completed} jobs • {format_currency(tech.total_revenue)}
                </p>
              </div>
            </div>

            <%= if @top_techs == [] do %>
              <div class="text-sm text-zinc-500 dark:text-zinc-400">
                No technician stats yet.
              </div>
            <% end %>
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
              Latest job completions
            </p>
          </div>
          <.link
            navigate={~p"/jobs"}
            class="text-sm font-bold text-primary hover:underline flex items-center gap-1"
          >
            View All <.icon name="hero-arrow-right" class="size-4" />
          </.link>
        </div>

        <div class="overflow-x-auto">
          <table id="reports-recent-jobs-table" class="w-full">
            <thead class="bg-zinc-50 dark:bg-zinc-800/50">
              <tr>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">
                  Job
                </th>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">
                  Customer
                </th>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">
                  Technician
                </th>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">
                  Amount
                </th>
                <th class="px-8 py-4 text-left text-[10px] font-black text-zinc-500 uppercase tracking-widest">
                  Status
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
              <tr
                :for={job <- @recent_jobs}
                class="hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
              >
                <td class="px-8 py-4 text-sm font-bold text-zinc-900 dark:text-white">{job.title}</td>
                <td class="px-8 py-4 text-sm text-zinc-600 dark:text-zinc-400">
                  {(job.customer && job.customer.name) || "—"}
                </td>
                <td class="px-8 py-4 text-sm text-zinc-600 dark:text-zinc-400">
                  {(job.technician && job.technician.name) || "—"}
                </td>
                <td class="px-8 py-4 text-sm font-bold text-zinc-900 dark:text-white">
                  {format_currency(job.actual_amount)}
                </td>
                <td class="px-8 py-4">
                  <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                    <div class="size-1.5 rounded-full bg-emerald-500"></div>
                    Completed
                  </span>
                </td>
              </tr>

              <%= if @recent_jobs == [] do %>
                <tr>
                  <td class="px-8 py-6 text-sm text-zinc-500 dark:text-zinc-400" colspan="5">
                    No completed jobs yet.
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp default_range do
    today = Date.utc_today()
    {Date.add(today, -@range_days), today}
  end

  defp format_date_short(%Date{} = date), do: Calendar.strftime(date, "%b %d")
  defp format_date_short(_), do: "—"

  defp format_duration_minutes(nil), do: "0m"

  defp format_duration_minutes(minutes) when is_integer(minutes) and minutes >= 60 do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)

    if mins == 0 do
      "#{hours}h"
    else
      "#{hours}h #{mins}m"
    end
  end

  defp format_duration_minutes(minutes) when is_integer(minutes) and minutes > 0,
    do: "#{minutes}m"

  defp format_duration_minutes(_), do: "0m"

  defp format_currency(nil), do: "$0.00"

  defp format_currency(%Decimal{} = amount) do
    amount = Decimal.round(amount, 2)
    "$#{Decimal.to_string(amount, :normal)}"
  end

  defp format_currency(amount) when is_number(amount) do
    "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"
  end

  defp format_currency(_), do: "$0.00"

  defp tech_avatar_url(%{avatar_url: url}) when is_binary(url) and url != "", do: url

  defp tech_avatar_url(%{name: name}) do
    "https://ui-avatars.com/api/?name=#{URI.encode_www_form(name || "Tech")}&background=10b981&color=fff"
  end
end
