defmodule FieldHubWeb.Components.ErrorBoundary do
  @moduledoc """
  Error boundary components for graceful error handling in the UI.
  These provide user-friendly error messages and recovery options.
  """
  use Phoenix.Component
  import FieldHubWeb.CoreComponents, only: [icon: 1]

  @doc """
  A generic error boundary wrapper component.
  Displays an error message with optional retry action.
  """
  attr :title, :string, default: "Something went wrong"
  attr :message, :string, default: "We encountered an unexpected error. Please try again."
  attr :icon_name, :string, default: "hero-exclamation-triangle"
  attr :icon_color, :string, default: "text-amber-500"
  attr :show_retry, :boolean, default: true
  attr :retry_event, :string, default: "retry"
  attr :class, :string, default: ""

  def error_card(assigns) do
    ~H"""
    <div class={"bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm p-8 #{@class}"}>
      <div class="flex flex-col items-center text-center max-w-md mx-auto">
        <div class="size-16 rounded-2xl bg-amber-500/10 flex items-center justify-center mb-6">
          <.icon name={@icon_name} class={"size-8 #{@icon_color}"} />
        </div>
        <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2">
          {@title}
        </h3>
        <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-6">
          {@message}
        </p>
        <button
          :if={@show_retry}
          phx-click={@retry_event}
          class="inline-flex items-center gap-2 px-4 py-2.5 bg-primary text-white font-bold text-sm rounded-xl hover:bg-primary/90 transition-all"
        >
          <.icon name="hero-arrow-path" class="size-4" /> Try Again
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Inline error message for form fields or small areas.
  """
  attr :message, :string, required: true
  attr :class, :string, default: ""

  def inline_error(assigns) do
    ~H"""
    <div class={"flex items-center gap-2 text-red-500 text-sm #{@class}"}>
      <.icon name="hero-exclamation-circle" class="size-4 flex-shrink-0" />
      <span>{@message}</span>
    </div>
    """
  end

  @doc """
  Network error banner - typically shown at the top of the page.
  """
  attr :message, :string, default: "Connection lost. Please check your internet connection."
  attr :show_reconnect, :boolean, default: true

  def network_error_banner(assigns) do
    ~H"""
    <div class="bg-red-500/10 border border-red-500/20 rounded-xl p-4 mb-6">
      <div class="flex items-center gap-3">
        <div class="size-10 rounded-xl bg-red-500/20 flex items-center justify-center flex-shrink-0">
          <.icon name="hero-wifi" class="size-5 text-red-500" />
        </div>
        <div class="flex-1">
          <p class="text-sm font-bold text-red-600 dark:text-red-400">
            Connection Issue
          </p>
          <p class="text-xs text-red-500/80 dark:text-red-400/80">
            {@message}
          </p>
        </div>
        <button
          :if={@show_reconnect}
          phx-click="reconnect"
          class="px-3 py-1.5 bg-red-500 text-white text-xs font-bold rounded-lg hover:bg-red-600 transition-colors"
        >
          Reconnect
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Permission denied error for access control issues.
  """
  attr :resource, :string, default: "this page"
  attr :redirect_path, :string, default: "/dashboard"

  def permission_denied(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm p-8">
      <div class="flex flex-col items-center text-center max-w-md mx-auto">
        <div class="size-16 rounded-2xl bg-red-500/10 flex items-center justify-center mb-6">
          <.icon name="hero-lock-closed" class="size-8 text-red-500" />
        </div>
        <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2">
          Access Denied
        </h3>
        <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-6">
          You don't have permission to access {@resource}. Please contact your administrator if you believe this is a mistake.
        </p>
        <.link
          navigate={@redirect_path}
          class="inline-flex items-center gap-2 px-4 py-2.5 bg-primary text-white font-bold text-sm rounded-xl hover:bg-primary/90 transition-all"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Go Back
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  Not found error for missing resources.
  """
  attr :resource_type, :string, default: "page"
  attr :redirect_path, :string, default: "/dashboard"
  attr :redirect_label, :string, default: "Go to Dashboard"

  def not_found(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm p-8">
      <div class="flex flex-col items-center text-center max-w-md mx-auto">
        <div class="size-16 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center mb-6">
          <.icon name="hero-question-mark-circle" class="size-8 text-zinc-400" />
        </div>
        <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2">
          {@resource_type |> String.capitalize()} Not Found
        </h3>
        <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-6">
          The {@resource_type} you're looking for doesn't exist or may have been deleted.
        </p>
        <.link
          navigate={@redirect_path}
          class="inline-flex items-center gap-2 px-4 py-2.5 bg-primary text-white font-bold text-sm rounded-xl hover:bg-primary/90 transition-all"
        >
          <.icon name="hero-arrow-left" class="size-4" />
          {@redirect_label}
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  Server error component for 500-type errors.
  """
  attr :show_details, :boolean, default: false
  attr :error_id, :string, default: nil

  def server_error(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-900 rounded-[24px] border border-zinc-200 dark:border-zinc-800 shadow-sm p-8">
      <div class="flex flex-col items-center text-center max-w-md mx-auto">
        <div class="size-16 rounded-2xl bg-red-500/10 flex items-center justify-center mb-6">
          <.icon name="hero-server" class="size-8 text-red-500" />
        </div>
        <h3 class="text-lg font-bold text-zinc-900 dark:text-white mb-2">
          Server Error
        </h3>
        <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-4">
          Something went wrong on our end. Our team has been notified and is working on a fix.
        </p>
        <p :if={@error_id} class="text-xs text-zinc-400 dark:text-zinc-500 mb-6 font-mono">
          Error ID: {@error_id}
        </p>
        <div class="flex gap-3">
          <button
            phx-click="retry"
            class="inline-flex items-center gap-2 px-4 py-2.5 bg-primary text-white font-bold text-sm rounded-xl hover:bg-primary/90 transition-all"
          >
            <.icon name="hero-arrow-path" class="size-4" /> Try Again
          </button>
          <.link
            navigate="/dashboard"
            class="inline-flex items-center gap-2 px-4 py-2.5 bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300 font-bold text-sm rounded-xl hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-all"
          >
            Go to Dashboard
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
