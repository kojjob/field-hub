defmodule FieldHubWeb.Components.Skeletons do
  @moduledoc """
  Skeleton loading components for better perceived performance.
  These provide visual placeholders while content is loading.
  """
  use Phoenix.Component

  @doc """
  A generic skeleton pulse animation wrapper.
  """
  attr :class, :string, default: ""
  slot :inner_block

  def skeleton(assigns) do
    ~H"""
    <div class={"animate-pulse #{@class}"}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Skeleton for KPI cards matching DashboardComponents.kpi_card.
  """
  attr :count, :integer, default: 4

  def kpi_cards_skeleton(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
      <div
        :for={_ <- 1..@count}
        class="animate-pulse bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm"
      >
        <div class="flex items-center justify-between mb-4">
          <div class="size-11 rounded-xl bg-zinc-200 dark:bg-zinc-700"></div>
          <div class="h-6 w-16 bg-zinc-200 dark:bg-zinc-700 rounded-lg"></div>
        </div>
        <div class="space-y-2">
          <div class="h-3 w-24 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
          <div class="h-8 w-32 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Skeleton for a table with rows.
  """
  attr :rows, :integer, default: 5
  attr :columns, :integer, default: 5

  def table_skeleton(assigns) do
    ~H"""
    <div class="animate-pulse bg-white dark:bg-zinc-900 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden">
      <%!-- Header --%>
      <div class="px-8 py-6 border-b border-zinc-200 dark:border-zinc-800 flex items-center justify-between">
        <div class="space-y-2">
          <div class="h-5 w-40 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
          <div class="h-3 w-56 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        </div>
        <div class="h-9 w-24 bg-zinc-200 dark:bg-zinc-700 rounded-xl"></div>
      </div>
      <%!-- Table header --%>
      <div class="bg-zinc-50 dark:bg-zinc-800/50 px-8 py-4 flex gap-8">
        <div :for={_ <- 1..@columns} class="h-3 w-20 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
      </div>
      <%!-- Table rows --%>
      <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
        <div :for={_ <- 1..@rows} class="px-8 py-4 flex items-center gap-8">
          <div :for={_ <- 1..@columns} class="h-4 w-24 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Skeleton for a list of items (e.g., technicians sidebar).
  """
  attr :count, :integer, default: 4

  def list_skeleton(assigns) do
    ~H"""
    <div class="animate-pulse space-y-4">
      <div :for={_ <- 1..@count} class="flex items-center gap-4">
        <div class="size-10 rounded-full bg-zinc-200 dark:bg-zinc-700"></div>
        <div class="flex-1 space-y-2">
          <div class="h-4 w-28 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
          <div class="h-3 w-20 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        </div>
        <div class="size-3 rounded-full bg-zinc-200 dark:bg-zinc-700"></div>
      </div>
    </div>
    """
  end

  @doc """
  Skeleton for a card with content.
  """
  attr :class, :string, default: ""

  def card_skeleton(assigns) do
    ~H"""
    <div class={"animate-pulse bg-white dark:bg-zinc-900 p-6 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm #{@class}"}>
      <div class="space-y-4">
        <div class="h-5 w-32 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        <div class="space-y-2">
          <div class="h-3 w-full bg-zinc-200 dark:bg-zinc-700 rounded"></div>
          <div class="h-3 w-3/4 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
          <div class="h-3 w-1/2 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Skeleton for chart areas.
  """
  attr :height, :string, default: "h-64"

  def chart_skeleton(assigns) do
    ~H"""
    <div class="animate-pulse bg-white dark:bg-zinc-900 p-8 rounded-[32px] border border-zinc-200 dark:border-zinc-800 shadow-sm">
      <div class="flex items-center justify-between mb-8">
        <div class="space-y-2">
          <div class="h-5 w-40 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
          <div class="h-3 w-56 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        </div>
        <div class="flex gap-4">
          <div class="h-3 w-20 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
          <div class="h-3 w-20 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        </div>
      </div>
      <div class={"#{@height} bg-zinc-100 dark:bg-zinc-800 rounded-lg flex items-end gap-2 p-4"}>
        <div
          :for={h <- [40, 60, 45, 75, 55, 80, 50, 70, 65, 85, 60, 90]}
          class="flex-1 bg-zinc-200 dark:bg-zinc-700 rounded-t"
          style={"height: #{h}%"}
        >
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Skeleton for page header.
  """
  def page_header_skeleton(assigns) do
    ~H"""
    <div class="animate-pulse flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div class="space-y-2">
        <div class="h-2 w-16 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        <div class="h-8 w-48 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
        <div class="h-3 w-64 bg-zinc-200 dark:bg-zinc-700 rounded"></div>
      </div>
      <div class="flex gap-3">
        <div class="h-10 w-32 bg-zinc-200 dark:bg-zinc-700 rounded-xl"></div>
        <div class="h-10 w-24 bg-zinc-200 dark:bg-zinc-700 rounded-xl"></div>
      </div>
    </div>
    """
  end

  @doc """
  Full page loading skeleton with all common elements.
  """
  def page_skeleton(assigns) do
    ~H"""
    <div class="space-y-10 pb-20">
      <.page_header_skeleton />
      <.kpi_cards_skeleton />
      <.table_skeleton />
    </div>
    """
  end
end
