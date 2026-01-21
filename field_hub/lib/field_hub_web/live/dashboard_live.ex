defmodule FieldHubWeb.DashboardLive do
  @moduledoc """
  Main dashboard LiveView.

  Shows overview of jobs, technicians, and key metrics for the organization.
  """
  use FieldHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope
    org_id = current_scope.user.organization_id

    # Billing stats
    billing_stats = FieldHub.Billing.get_invoice_stats(org_id)

    # Job stats
    open_jobs_count = FieldHub.Jobs.count_jobs_by_status(org_id, ["unscheduled", "scheduled"])
    in_progress_jobs_count = FieldHub.Jobs.count_jobs_by_status(org_id, ["dispatched", "en_route", "on_site", "in_progress"])

    {:ok,
     socket
     |> assign(:page_title, "Operations Overview")
     |> assign(:current_nav, :dashboard)
     |> assign(:billing_stats, billing_stats)
     |> assign(:open_jobs_count, open_jobs_count)
     |> assign(:in_progress_jobs_count, in_progress_jobs_count)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10 pb-20">
      <% org = @current_organization
      task_plural = FieldHub.Config.Terminology.get_label(org, :task, :plural)
      task_singular = FieldHub.Config.Terminology.get_label(org, :task, :singular) %>
      <!-- Page Heading -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p class="text-[10px] font-black text-primary uppercase tracking-[0.2em] mb-1">
            Operations Intelligence
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            {task_singular} & Billing Overview
          </h2>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <div class="px-4 py-2.5 bg-zinc-100 dark:bg-zinc-800 rounded-xl text-sm font-bold border border-zinc-200 dark:border-zinc-700 flex items-center gap-2">
            <div class="size-2 rounded-full bg-emerald-500 animate-pulse"></div>
            <span class="text-zinc-600 dark:text-zinc-400">System Live</span>
          </div>
          <.link navigate={~p"/jobs/new"}>
            <button class="flex items-center gap-2 px-5 py-2.5 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1">
              <.icon name="hero-plus" class="size-5" /> New {task_singular}
            </button>
          </.link>
        </div>
      </div>

    <!-- KPI Row -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <FieldHubWeb.DashboardComponents.kpi_card
          label="Total Revenue"
          value={"$#{format_money(@billing_stats.total_invoiced)}"}
          change="+12.5%"
          icon="payments"
          variant={:simple}
        />
        <FieldHubWeb.DashboardComponents.kpi_card
          label={"Active #{task_plural}"}
          value={"#{@in_progress_jobs_count}"}
          icon="bolt"
          variant={:progress}
          progress={75}
        />
        <FieldHubWeb.DashboardComponents.kpi_card
          label="Outstanding"
          value={"$#{format_money(@billing_stats.outstanding)}"}
          icon="error_outline"
          variant={:simple}
        />
        <FieldHubWeb.DashboardComponents.kpi_card
          label={"#{task_singular} Completion"}
          value="98.2%"
          change="+2.4%"
          icon="check_circle"
          variant={:simple}
        />
      </div>

    <!-- Middle Intelligence Grid -->
      <div class="grid grid-cols-1 xl:grid-cols-12 gap-8 mt-10">
        <!-- Billing Insights -->
        <div class="xl:col-span-4">
          <FieldHubWeb.DashboardComponents.billing_overview stats={@billing_stats} />
        </div>

    <!-- Revenue Performance -->
        <div class="xl:col-span-8">
          <FieldHubWeb.DashboardComponents.revenue_trend_chart />
        </div>
      </div>

    <!-- Bottom Section: Workflows & Activity -->
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <div class="lg:col-span-8">
          <FieldHubWeb.DashboardComponents.priority_jobs_table />
        </div>
        <div class="lg:col-span-4">
          <FieldHubWeb.DashboardComponents.live_activity_feed />
        </div>
      </div>
    </div>
    """
  end

  defp format_money(nil), do: "0.00"
  defp format_money(%Decimal{} = amount), do: Decimal.to_string(Decimal.round(amount, 2), :normal)
  defp format_money(amount) when is_number(amount), do: :erlang.float_to_binary(amount / 1, decimals: 2)
  defp format_money(_), do: "0.00"
end
