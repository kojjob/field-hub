defmodule FieldHubWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use FieldHubWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides a single dark/light theme toggle.
  """
  def theme_toggle(assigns) do
    ~H"""
    <button
      id="theme-toggle-btn"
      type="button"
      class="group relative inline-flex h-9 w-9 items-center justify-center rounded-xl bg-zinc-100 dark:bg-zinc-800 text-zinc-500 hover:text-primary dark:text-zinc-400 dark:hover:text-primary transition-all duration-200"
      phx-click={JS.dispatch("phx:set-theme")}
      data-phx-theme="toggle"
    >
      <span class="sr-only">Toggle theme</span>
      <.icon
        name="hero-sun"
        class="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0"
      />
      <.icon
        name="hero-moon"
        class="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100"
      />
    </button>
    """
  end

  @doc """
  Renders the user dropdown menu for the navbar.
  """
  attr :current_user, :map, required: true
  attr :current_organization, :map, default: nil

  def user_dropdown(assigns) do
    ~H"""
    <div class="relative ml-3">
      <div>
        <button
          type="button"
          class="flex items-center gap-x-3 rounded-full p-1 lg:rounded-xl lg:p-1.5 lg:pr-2.5 text-sm font-semibold leading-6 text-zinc-900 dark:text-zinc-100 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-all duration-200 group focus:outline-none focus:ring-2 focus:ring-primary/20"
          id="user-menu-button"
          phx-click={
            JS.toggle(
              to: "#user-menu",
              in:
                {"transition ease-out duration-100", "transform opacity-0 scale-95",
                 "transform opacity-100 scale-100"},
              out:
                {"transition ease-in duration-75", "transform opacity-100 scale-100",
                 "transform opacity-0 scale-95"}
            )
          }
          phx-click-away={JS.hide(to: "#user-menu")}
        >
          <div class="relative h-9 w-9">
            <img
              class="h-9 w-9 rounded-full bg-zinc-50 border border-zinc-200 dark:border-zinc-700 object-cover"
              src={
                @current_user.avatar_url ||
                  "https://ui-avatars.com/api/?name=#{@current_user.name || @current_user.email}&background=10b981&color=fff"
              }
              alt=""
            />
            <span class="absolute bottom-0 right-0 block h-2.5 w-2.5 rounded-full bg-primary ring-2 ring-white dark:ring-zinc-900">
            </span>
          </div>

          <span class="hidden lg:flex lg:flex-col lg:items-start text-left">
            <span
              class="text-sm font-bold text-zinc-700 dark:text-zinc-200 group-hover:text-zinc-900 dark:group-hover:text-white transition-colors"
              aria-hidden="true"
            >
              {@current_user.name || @current_user.email}
            </span>
            <span class="text-[10px] font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide leading-none">
              {if @current_organization,
                do: @current_organization.brand_name || "Enterprise",
                else: "Admin"}
            </span>
          </span>
          <.icon
            name="hero-chevron-down"
            class="hidden lg:block h-4 w-4 text-zinc-400 group-hover:text-zinc-600 dark:text-zinc-500 dark:group-hover:text-zinc-300 transition-colors ml-1"
          />
        </button>
      </div>

      <div
        id="user-menu"
        class="hidden absolute right-0 z-20 mt-2.5 w-72 origin-top-right rounded-2xl bg-white dark:bg-zinc-900 shadow-2xl ring-1 ring-zinc-900/5 focus:outline-none border border-zinc-100 dark:border-zinc-800 divide-y divide-zinc-100 dark:divide-zinc-800 overflow-hidden"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="user-menu-button"
        tabindex="-1"
      >
        <!-- User Info Header -->
        <div class="px-5 py-4 bg-zinc-50/50 dark:bg-zinc-800/30">
          <p class="text-sm text-zinc-900 dark:text-zinc-100 font-bold truncate">
            Signed in as
          </p>
          <p class="text-sm text-zinc-500 dark:text-zinc-400 font-medium truncate mt-0.5">
            {@current_user.email}
          </p>
        </div>

    <!-- Account Section -->
        <div class="py-1">
          <div class="px-3 py-1.5 text-xs font-semibold text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
            Account
          </div>
          <.link
            navigate={~p"/users/settings"}
            class="group flex items-center px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
            role="menuitem"
            tabindex="-1"
          >
            <.icon
              name="hero-user-circle"
              class="mr-3 h-5 w-5 text-zinc-400 group-hover:text-primary transition-colors"
            /> Your Profile
          </.link>
          <.link
            navigate={~p"/users/settings"}
            class="group flex items-center px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
            role="menuitem"
            tabindex="-1"
          >
            <.icon
              name="hero-cog"
              class="mr-3 h-5 w-5 text-zinc-400 group-hover:text-primary transition-colors"
            /> Settings
          </.link>
        </div>

    <!-- Organization Section -->
        <%= if @current_organization do %>
          <div class="py-1">
            <div class="px-3 py-1.5 text-xs font-semibold text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
              {@current_organization.brand_name || "Organization"}
            </div>
            <.link
              navigate={~p"/settings/branding"}
              class="group flex items-center px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
              role="menuitem"
              tabindex="-1"
            >
              <.icon
                name="hero-building-office"
                class="mr-3 h-5 w-5 text-zinc-400 group-hover:text-primary transition-colors"
              /> Company Profile
            </.link>
            <.link
              navigate={~p"/technicians"}
              class="group flex items-center px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
              role="menuitem"
              tabindex="-1"
            >
              <.icon
                name="hero-users"
                class="mr-3 h-5 w-5 text-zinc-400 group-hover:text-primary transition-colors"
              /> Team Members
            </.link>
          </div>
        <% end %>

    <!-- Help Section -->
        <div class="py-1">
          <.link
            href="#"
            class="group flex items-center px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
            role="menuitem"
            tabindex="-1"
          >
            <.icon
              name="hero-lifebuoy"
              class="mr-3 h-5 w-5 text-zinc-400 group-hover:text-primary transition-colors"
            /> Help Center
          </.link>
          <.link
            href="#"
            class="group flex items-center px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
            role="menuitem"
            tabindex="-1"
          >
            <.icon
              name="hero-book-open"
              class="mr-3 h-5 w-5 text-zinc-400 group-hover:text-primary transition-colors"
            /> API Documentation
          </.link>
        </div>

    <!-- Logout -->
        <div class="py-1">
          <.link
            href={~p"/users/log-out"}
            method="delete"
            class="group flex items-center px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 dark:hover:bg-red-900/10 transition-colors"
            role="menuitem"
            tabindex="-1"
          >
            <.icon
              name="hero-arrow-right-on-rectangle"
              class="mr-3 h-5 w-5 text-red-500 group-hover:text-red-600 transition-colors"
            /> Sign out
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the notification dropdown for the navbar.
  """
  def notification_dropdown(assigns) do
    ~H"""
    <div class="relative ml-2 sm:ml-3">
      <div>
        <button
          type="button"
          class="relative p-2 text-zinc-400 hover:text-primary dark:hover:text-primary hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-xl transition-all duration-200"
          id="notifications-button"
          phx-click={
            JS.toggle(
              to: "#notifications-menu",
              in:
                {"transition ease-out duration-100", "transform opacity-0 scale-95",
                 "transform opacity-100 scale-100"},
              out:
                {"transition ease-in duration-75", "transform opacity-100 scale-100",
                 "transform opacity-0 scale-95"}
            )
          }
          phx-click-away={JS.hide(to: "#notifications-menu")}
        >
          <span class="sr-only">View notifications</span>
          <.icon name="hero-bell" class="h-5 w-5 sm:h-6 sm:w-6" />
          <span class="absolute top-2 right-2 flex h-2 w-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75">
            </span>
            <span class="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
          </span>
        </button>
      </div>

      <div
        id="notifications-menu"
        class="hidden absolute right-0 z-10 mt-2.5 w-80 origin-top-right rounded-2xl bg-white dark:bg-zinc-900 shadow-2xl ring-1 ring-zinc-900/5 focus:outline-none border border-zinc-100 dark:border-zinc-800 overflow-hidden"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="notifications-button"
        tabindex="-1"
      >
        <div class="px-4 py-3 border-b border-zinc-100 dark:border-zinc-800 flex items-center justify-between">
          <h3 class="text-sm font-bold text-zinc-900 dark:text-zinc-100">Notifications</h3>
          <span class="text-[10px] font-black uppercase tracking-wider text-primary dark:text-primary bg-primary/10 dark:bg-primary/20 px-2 py-0.5 rounded-full">
            3 New
          </span>
        </div>

        <div class="max-h-96 overflow-y-auto">
          <!-- Notification Items (Placeholders) -->
          <div
            :for={i <- 1..3}
            class="px-4 py-3 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 cursor-pointer border-b border-zinc-50 dark:border-zinc-800/50 last:border-0 transition-colors"
          >
            <div class="flex gap-3">
              <div class="size-8 rounded-full bg-primary/10 dark:bg-primary/20 flex items-center justify-center shrink-0">
                <.icon name="hero-check-circle" class="size-5 text-primary dark:text-primary" />
              </div>
              <div class="space-y-1">
                <p class="text-sm text-zinc-900 dark:text-zinc-100 font-semibold leading-tight">
                  Job #10{i} completed
                </p>
                <p class="text-xs text-zinc-500 dark:text-zinc-400">
                  Technician Alex finished the installation at 12:45 PM.
                </p>
                <p class="text-[10px] text-zinc-400 font-medium uppercase">2 mins ago</p>
              </div>
            </div>
          </div>
        </div>

        <div class="p-3 bg-zinc-50 dark:bg-zinc-800/50 text-center border-t border-zinc-100 dark:border-zinc-800">
          <a href="#" class="text-xs font-bold text-primary dark:text-primary hover:underline">
            View all notifications
          </a>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the efficient, collapsible sidebar.
  """
  attr :current_user, :map, required: true
  attr :active_tab, :atom, default: nil
  attr :collapsed, :boolean, default: false

  slot :header
  slot :groups
  slot :footer

  def sidebar(assigns) do
    ~H"""
    <!-- Mobile Sidebar Overlay -->
    <div
      id="mobile-sidebar-backdrop"
      class="fixed inset-0 z-50 bg-zinc-900/80 backdrop-blur-sm lg:hidden hidden"
      aria-hidden="true"
      phx-click={
        JS.hide(to: "#mobile-sidebar-backdrop")
        |> JS.hide(to: "#mobile-sidebar-panel", transition: "translate-x-full")
      }
    >
    </div>

    <!-- Mobile Sidebar Panel -->
    <div
      id="mobile-sidebar-panel"
      class="fixed inset-y-0 left-0 z-50 w-72 bg-white dark:bg-zinc-900 shadow-2xl transform -translate-x-full transition-transform duration-300 ease-in-out lg:hidden hidden"
    >
      <div class="flex h-full flex-col overflow-y-auto px-6 py-6">
        {render_slot(@header)}
        <nav class="flex-1 space-y-8 mt-8">
          {render_slot(@groups)}
        </nav>
        <div class="mt-auto">
          {render_slot(@footer, %{context: :mobile})}
        </div>
      </div>
    </div>

    <!-- Desktop Sidebar -->
    <div
      id="desktop-sidebar"
      class={[
        "hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:flex-col border-r border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 transition-all duration-300 ease-in-out",
        if(@collapsed, do: "w-[64px]", else: "w-72")
      ]}
    >
      <!-- Header -->
      <div class={[
        "flex h-16 shrink-0 items-center transition-all duration-300",
        if(@collapsed, do: "justify-center px-0", else: "justify-between px-6")
      ]}>
        {render_slot(@header)}
      </div>

    <!-- Nav -->
      <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-6 scrollbar-hide">
        {render_slot(@groups)}
      </nav>

    <!-- Footer -->
      <div class={[
        "shrink-0 border-t border-zinc-200 dark:border-zinc-800 transition-all duration-300",
        if(@collapsed, do: "p-2", else: "p-4")
      ]}>
        {render_slot(@footer, %{context: :desktop})}
      </div>
    </div>
    """
  end

  @doc """
  Renders a specific sidebar nav item.
  """
  attr :navigate, :string, required: true
  attr :active, :boolean, default: false
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :collapsed, :boolean, default: false

  def sidebar_item(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "group relative flex items-center rounded-lg transition-all duration-200 outline-none focus-visible:ring-2 focus-visible:ring-teal-500",
        if(@collapsed,
          do: "justify-center p-2",
          else: "gap-x-3 px-3 py-2"
        ),
        if(@active,
          do: "bg-teal-50 text-teal-600 dark:bg-teal-500/10 dark:text-teal-400",
          else:
            "text-zinc-500 hover:bg-zinc-200/60 dark:text-zinc-400 dark:hover:bg-zinc-800 hover:text-zinc-900 dark:hover:text-zinc-200"
        )
      ]}
      data-tooltip={if @collapsed, do: @label, else: nil}
      phx-hook={if @collapsed, do: "SidebarTooltip", else: nil}
    >
      <.icon
        name={@icon}
        class={[
          "transition-colors duration-200",
          if(@collapsed, do: "h-6 w-6", else: "h-5 w-5"),
          if(@active,
            do: "text-teal-600 dark:text-teal-400",
            else: "text-zinc-400 group-hover:text-zinc-600 dark:group-hover:text-zinc-300"
          )
        ]}
      />
      <span :if={!@collapsed} class="text-sm font-medium leading-6 truncate">
        {@label}
      </span>

    <!-- Collapsed Active Indicator -->
      <span
        :if={@collapsed and @active}
        class="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-teal-600 dark:bg-teal-400 rounded-r-full"
      >
      </span>
    </.link>
    """
  end

  @doc """
  Renders a labelled group of sidebar items.
  """
  attr :label, :string, default: nil
  attr :collapsed, :boolean, default: false
  slot :inner_block, required: true

  def sidebar_group(assigns) do
    ~H"""
    <div class="space-y-1">
      <h3
        :if={@label && !@collapsed}
        class="px-3 text-xs font-semibold leading-6 text-zinc-400 uppercase tracking-wider mb-2"
      >
        {@label}
      </h3>
      <div :if={@label && @collapsed} class="h-px w-8 mx-auto bg-zinc-200 dark:bg-zinc-800 mb-2">
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the sidebar header/branding area.
  """
  attr :collapsed, :boolean, default: false

  def sidebar_header(assigns) do
    ~H"""
    <div class="flex items-center w-full">
      <.link navigate={~p"/dashboard"} class="flex items-center gap-x-3 group outline-none">
        <div class={[
          "flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-indigo-600 transition-all duration-300 shadow-lg shadow-indigo-500/20 group-hover:scale-105",
          if(@collapsed, do: "mx-auto", else: "")
        ]}>
          <.icon name="hero-bolt" class="h-5 w-5 text-white" />
        </div>
        <span
          :if={!@collapsed}
          class="text-lg font-bold tracking-tight text-zinc-900 dark:text-white group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors"
        >
          FieldHub
        </span>
      </.link>
    </div>
    """
  end

  @doc """
  Renders the user account footer item.
  """
  attr :current_user, :map, required: true
  attr :collapsed, :boolean, default: false

  def user_account_item(assigns) do
    ~H"""
    <div class={[
      "flex items-center gap-x-3 rounded-lg transition-colors",
      if(@collapsed,
        do: "justify-center",
        else: "px-3 py-2 hover:bg-zinc-50 dark:hover:bg-zinc-800/50"
      )
    ]}>
      <img
        class="h-8 w-8 rounded-full bg-zinc-50 ring-2 ring-white dark:ring-zinc-800"
        src={@current_user.avatar_url || "https://ui-avatars.com/api/?name=#{@current_user.email}"}
        alt=""
      />
      <div :if={!@collapsed} class="flex flex-col min-w-0">
        <span class="truncate text-sm font-semibold text-zinc-900 dark:text-zinc-100">
          {@current_user.name || "User"}
        </span>
        <span class="truncate text-xs text-zinc-500 dark:text-zinc-400">
          {@current_user.email}
        </span>
      </div>
      <!-- Settings/Logout Actions could go here or in a dropdown triggered by this -->
    </div>
    """
  end

  @doc """
  Renders the sidebar toggle button.
  """
  attr :collapsed, :boolean, default: false

  def sidebar_toggle(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="toggle_sidebar"
      class="group flex h-8 w-8 items-center justify-center rounded-lg text-zinc-400 hover:bg-zinc-100 dark:text-zinc-500 dark:hover:bg-zinc-800 transition-colors"
      aria-label={if @collapsed, do: "Expand sidebar", else: "Collapse sidebar"}
    >
      <.icon
        name="hero-chevron-left"
        class={[
          "h-5 w-5 transition-transform duration-300",
          if(@collapsed, do: "rotate-180", else: "")
        ]}
      />
    </button>
    """
  end
end
