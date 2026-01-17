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
     |> assign(:page_title, "Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-8 px-4 max-w-7xl mx-auto">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white">
          Welcome to FieldHub!
        </h1>
        <p class="mt-2 text-gray-600 dark:text-gray-400">
          Your field service dispatch hub is ready. Let's get started!
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0 p-3 bg-blue-100 dark:bg-blue-900 rounded-lg">
              <svg
                class="h-6 w-6 text-blue-600 dark:text-blue-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Today's Jobs</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white">0</p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0 p-3 bg-green-100 dark:bg-green-900 rounded-lg">
              <svg
                class="h-6 w-6 text-green-600 dark:text-green-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17 20h5v-2a3 3 0 00-3-3h-2m-3-2a3 3 0 100-6 3 3 0 000 6z"
                />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Active Technicians</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white">0</p>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0 p-3 bg-purple-100 dark:bg-purple-900 rounded-lg">
              <svg
                class="h-6 w-6 text-purple-600 dark:text-purple-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400">Weekly Revenue</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white">$0</p>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 text-center">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">
          Get Started with FieldHub
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 max-w-3xl mx-auto">
          <div class="p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
            <div class="text-3xl mb-2">👷</div>
            <h3 class="font-medium">Add Technicians</h3>
            <p class="text-sm text-gray-500">Add your field workers</p>
          </div>
          <div class="p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
            <div class="text-3xl mb-2">🏢</div>
            <h3 class="font-medium">Add Customers</h3>
            <p class="text-sm text-gray-500">Import your customer base</p>
          </div>
          <div class="p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
            <div class="text-3xl mb-2">📋</div>
            <h3 class="font-medium">Create Jobs</h3>
            <p class="text-sm text-gray-500">Schedule your first job</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
