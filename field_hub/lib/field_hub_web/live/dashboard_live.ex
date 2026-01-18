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
     |> assign(:page_title, "Operations Overview")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden bg-fsm-bg-light dark:bg-fsm-bg-dark font-dashboard text-slate-900 dark:text-slate-100">
      <!-- Sidebar Navigation -->
      <FieldHubWeb.DashboardComponents.sidebar current_user={@current_scope.user} current_organization={@current_organization} />

      <!-- Main Content Area -->
      <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
        <FieldHubWeb.DashboardComponents.header current_user={@current_scope.user} />

        <main class="flex-1 overflow-y-auto bg-slate-50/30 dark:bg-fsm-bg-dark p-8 space-y-10 scrollbar-hide pb-20">
            <%
              org = @current_organization
              task_plural = FieldHub.Config.Terminology.get_label(org, :task, :plural)
              task_singular = FieldHub.Config.Terminology.get_label(org, :task, :singular)
            %>
          <!-- Page Heading -->
          <div class="flex items-center justify-between">
            <div>
              <p class="text-[10px] font-black text-fsm-primary uppercase tracking-[0.2em] mb-1">
                Management Overview
              </p>
              <h2 class="text-3xl font-black tracking-tighter text-slate-900 dark:text-white">
                <%= task_singular %> Operations
              </h2>
            </div>
            <div class="flex items-center gap-3">
              <button class="bg-white dark:bg-slate-800 border border-fsm-border-light dark:border-slate-700 text-slate-600 dark:text-slate-300 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:bg-slate-50 transition-all">
                <span class="material-symbols-outlined text-[20px]">calendar_today</span>
                Jan 16, 2024
              </button>
              <button class="bg-slate-900 dark:bg-fsm-primary text-white px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 hover:brightness-110 transition-all">
                <span class="material-symbols-outlined text-[20px]">filter_list</span>
                Filters
              </button>
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
        </main>
      </div>
    </div>
    """
  end
end
