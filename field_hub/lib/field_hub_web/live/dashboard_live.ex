defmodule FieldHubWeb.DashboardLive do
  @moduledoc """
  Main dashboard LiveView.

  Shows overview of jobs, technicians, and key metrics for the organization.
  """
  use FieldHubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Operations Overview")
     |> assign(:current_nav, :dashboard)}
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
            Management Overview
          </p>
          <h2 class="text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
            {task_singular} Operations
          </h2>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
            <.icon name="hero-calendar" class="size-5" /> Jan 16, 2024
          </button>
          <button class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all border-b-2">
            <.icon name="hero-funnel" class="size-5" /> Filters
          </button>
          <.link navigate={~p"/jobs/new"}>
            <button class="flex items-center gap-2 px-5 py-2.5 bg-primary hover:brightness-110 text-white rounded-xl font-bold text-sm shadow-xl shadow-primary/20 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1">
              <.icon name="hero-plus" class="size-5" /> Create New Job
            </button>
          </.link>
        </div>
      </div>

    <!-- KPI Cards Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        <FieldHubWeb.DashboardComponents.kpi_card
          label="Today's Revenue"
          value="$12,840.00"
          change="+14.2%"
          icon="payments"
          variant={:simple}
        />
        <FieldHubWeb.DashboardComponents.kpi_card
          label="Customer Satisfaction"
          value="4.9/5.0"
          icon="star"
          variant={:stars}
        />
        <FieldHubWeb.DashboardComponents.kpi_card
          label={"Open #{task_plural}"}
          value="18"
          progress={65}
          variant={:progress}
          icon="confirmation_number"
          subtext="65% toward daily goal"
        />
        <FieldHubWeb.DashboardComponents.kpi_card
          label="Monthly Growth"
          value="+28%"
          icon="trending_up"
          variant={:avatars}
        />
      </div>

    <!-- Middle Section: Utilization & Activity -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <div class="xl:col-span-2">
          <FieldHubWeb.DashboardComponents.utilization_chart />
        </div>
        <div class="xl:col-span-1">
          <FieldHubWeb.DashboardComponents.live_activity_feed />
        </div>
      </div>

    <!-- Bottom Section: Priority Jobs -->
      <FieldHubWeb.DashboardComponents.priority_jobs_table />
    </div>
    """
  end
end
