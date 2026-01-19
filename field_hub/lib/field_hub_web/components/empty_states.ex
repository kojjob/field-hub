defmodule FieldHubWeb.Components.EmptyStates do
  @moduledoc """
  Empty state components for when there's no data to display.
  These provide helpful guidance and call-to-action buttons.
  """
  use Phoenix.Component
  import FieldHubWeb.CoreComponents, only: [icon: 1]

  @doc """
  Generic empty state with customizable content.
  """
  attr :title, :string, required: true
  attr :message, :string, required: true
  attr :icon_name, :string, default: "hero-inbox"
  attr :icon_bg_color, :string, default: "bg-primary/10"
  attr :icon_color, :string, default: "text-primary"
  attr :action_label, :string, default: nil
  attr :action_event, :string, default: nil
  attr :action_path, :string, default: nil
  attr :class, :string, default: ""

  def empty_state(assigns) do
    ~H"""
    <div class={"flex flex-col items-center justify-center py-16 px-4 #{@class}"}>
      <div class={"size-20 rounded-2xl #{@icon_bg_color} flex items-center justify-center mb-6"}>
        <.icon name={@icon_name} class={"size-10 #{@icon_color}"} />
      </div>
      <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2 text-center">
        {@title}
      </h3>
      <p class="text-sm text-zinc-500 dark:text-zinc-400 text-center max-w-md mb-6">
        {@message}
      </p>
      <button
        :if={@action_event}
        phx-click={@action_event}
        class="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-white font-bold text-sm rounded-xl hover:bg-primary/90 transition-all shadow-lg shadow-primary/25"
      >
        <.icon name="hero-plus" class="size-5" />
        {@action_label}
      </button>
      <.link
        :if={@action_path && !@action_event}
        navigate={@action_path}
        class="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-white font-bold text-sm rounded-xl hover:bg-primary/90 transition-all shadow-lg shadow-primary/25"
      >
        <.icon name="hero-plus" class="size-5" />
        {@action_label}
      </.link>
    </div>
    """
  end

  @doc """
  Empty state for no jobs.
  """
  attr :show_action, :boolean, default: true

  def no_jobs(assigns) do
    ~H"""
    <.empty_state
      title="No jobs yet"
      message="Create your first job to start tracking work orders, scheduling technicians, and managing your field service operations."
      icon_name="hero-clipboard-document-list"
      icon_bg_color="bg-blue-500/10"
      icon_color="text-blue-500"
      action_label={if @show_action, do: "Create First Job"}
      action_event={if @show_action, do: "new_job"}
    />
    """
  end

  @doc """
  Empty state for no customers.
  """
  attr :show_action, :boolean, default: true

  def no_customers(assigns) do
    ~H"""
    <.empty_state
      title="No customers yet"
      message="Add your first customer to start managing contacts, service locations, and job history all in one place."
      icon_name="hero-users"
      icon_bg_color="bg-emerald-500/10"
      icon_color="text-emerald-500"
      action_label={if @show_action, do: "Add First Customer"}
      action_event={if @show_action, do: "new_customer"}
    />
    """
  end

  @doc """
  Empty state for no technicians.
  """
  attr :show_action, :boolean, default: true

  def no_technicians(assigns) do
    ~H"""
    <.empty_state
      title="No technicians yet"
      message="Add technicians to your team to start dispatching jobs, tracking availability, and monitoring performance."
      icon_name="hero-wrench-screwdriver"
      icon_bg_color="bg-amber-500/10"
      icon_color="text-amber-500"
      action_label={if @show_action, do: "Add First Technician"}
      action_event={if @show_action, do: "new_technician"}
    />
    """
  end

  @doc """
  Empty state for no scheduled jobs (dispatch board).
  """
  def no_scheduled_jobs(assigns) do
    ~H"""
    <.empty_state
      title="Nothing scheduled"
      message="No jobs are scheduled for this date. Create a new job or drag an unscheduled job to the calendar."
      icon_name="hero-calendar"
      icon_bg_color="bg-purple-500/10"
      icon_color="text-purple-500"
    />
    """
  end

  @doc """
  Empty state for search results.
  """
  attr :query, :string, default: ""

  def no_search_results(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-16 px-4">
      <div class="size-20 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mb-6">
        <.icon name="hero-magnifying-glass" class="size-10 text-zinc-400" />
      </div>
      <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2 text-center">
        No results found
      </h3>
      <p class="text-sm text-zinc-500 dark:text-zinc-400 text-center max-w-md">
        <%= if @query != "" do %>
          No matches for "<span class="font-medium text-zinc-700 dark:text-zinc-300">{@query}</span>". Try adjusting your search or filters.
        <% else %>
          Try adjusting your search criteria or filters.
        <% end %>
      </p>
    </div>
    """
  end

  @doc """
  Empty state for no notifications.
  """
  def no_notifications(assigns) do
    ~H"""
    <.empty_state
      title="All caught up!"
      message="You have no new notifications. We'll let you know when something needs your attention."
      icon_name="hero-bell"
      icon_bg_color="bg-zinc-100 dark:bg-zinc-800"
      icon_color="text-zinc-400"
    />
    """
  end

  @doc """
  Empty state for no reports/analytics data.
  """
  def no_reports_data(assigns) do
    ~H"""
    <.empty_state
      title="No data available"
      message="There's no data to display for the selected time period. Try adjusting the date range or completing some jobs first."
      icon_name="hero-chart-bar"
      icon_bg_color="bg-indigo-500/10"
      icon_color="text-indigo-500"
    />
    """
  end

  @doc """
  Empty state for table with no filtered results.
  """
  attr :filter_type, :string, default: "filter"

  def no_filtered_results(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-12 px-4">
      <div class="size-16 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mb-4">
        <.icon name="hero-funnel" class="size-8 text-zinc-400" />
      </div>
      <h3 class="text-base font-bold text-zinc-900 dark:text-white mb-2 text-center">
        No matching results
      </h3>
      <p class="text-sm text-zinc-500 dark:text-zinc-400 text-center max-w-sm mb-4">
        No items match your current {@filter_type}. Try changing or clearing your filters.
      </p>
      <button
        phx-click="clear_filters"
        class="inline-flex items-center gap-2 px-4 py-2 text-primary font-bold text-sm hover:underline"
      >
        <.icon name="hero-x-mark" class="size-4" /> Clear Filters
      </button>
    </div>
    """
  end

  @doc """
  Compact inline empty state for smaller areas.
  """
  attr :message, :string, required: true
  attr :icon_name, :string, default: "hero-inbox"

  def inline_empty(assigns) do
    ~H"""
    <div class="flex items-center gap-3 py-8 px-4 text-zinc-400 dark:text-zinc-500">
      <.icon name={@icon_name} class="size-5" />
      <span class="text-sm">{@message}</span>
    </div>
    """
  end
end
