defmodule FieldHubWeb.LandingComponents do
  use FieldHubWeb, :html

  # import FieldHubWeb.CoreComponents

  @doc """
  The main navigation header for the landing page.
  """
  attr :current_user, :any, default: nil
  attr :current_scope, :any, default: nil

  def header(assigns) do
    ~H"""
    <nav class="fixed w-full z-50 transition-all duration-300 backdrop-blur-xl bg-[rgb(var(--bg))]/80 border-b border-[rgb(var(--border))]">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center h-20">
          <!-- Logo -->
          <div class="flex items-center gap-2">
            <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shadow-lg shadow-indigo-500/20">
              <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
              </svg>
            </div>
            <div class="leading-tight">
              <div class="text-lg font-extrabold tracking-tight">FieldHub</div>
              <div class="text-xs text-[rgb(var(--muted2))] -mt-0.5">Dispatch • Mobile • Billing</div>
            </div>
          </div>

          <!-- Desktop Menu -->
          <div class="hidden md:flex items-center gap-8">
            <a href="#features" class="text-sm font-medium text-[rgb(var(--muted))] hover:text-[rgb(var(--fg))] transition-colors">Features</a>
            <a href="#how" class="text-sm font-medium text-[rgb(var(--muted))] hover:text-[rgb(var(--fg))] transition-colors">How it works</a>
            <a href="#pricing" class="text-sm font-medium text-[rgb(var(--muted))] hover:text-[rgb(var(--fg))] transition-colors">Pricing</a>
            <a href="#faq" class="text-sm font-medium text-[rgb(var(--muted))] hover:text-[rgb(var(--fg))] transition-colors">FAQ</a>
          </div>

          <!-- Right actions -->
          <div class="flex items-center gap-3">
            <!-- Theme toggle -->
            <button
              id="themeToggle"
              type="button"
              class="inline-flex items-center gap-2 rounded-full px-3 py-2 text-sm font-semibold
                     border border-[rgb(var(--border))] bg-[rgb(var(--panel))]/70 hover:bg-[rgb(var(--panel))]
                     shadow-sm shadow-black/5 transition"
              aria-label="Toggle theme"
            >
              <svg id="sunIcon" class="w-4 h-4 hidden [data-theme=dark]:inline text-[rgb(var(--muted))]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M12 3v2m0 14v2m9-9h-2M5 12H3m15.364-6.364-1.414 1.414M7.05 16.95l-1.414 1.414M16.95 16.95l1.414 1.414M7.05 7.05 5.636 5.636M12 8a4 4 0 100 8 4 4 0 000-8z"/>
              </svg>
              <svg id="moonIcon" class="w-4 h-4 [data-theme=light]:inline hidden dark:hidden text-[rgb(var(--muted))]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M21 12.79A9 9 0 1111.21 3a7 7 0 109.79 9.79z"/>
              </svg>
              <!-- Fallback for simple toggling if custom variant fails -->
              <svg id="moonIconSimple" class="w-4 h-4 text-[rgb(var(--muted))] dark-hidden-logic" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                 <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12.79A9 9 0 1111.21 3a7 7 0 109.79 9.79z"/>
              </svg>
              <span class="text-[rgb(var(--muted))]">Theme</span>
            </button>

            <%= if @current_scope && @current_scope.user do %>
              <div class="flex flex-col items-end mr-2">
                <span class="text-[10px] text-[rgb(var(--muted2))]"><%= @current_scope.user.email %></span>
                <div class="flex gap-3">
                  <a href={~p"/dashboard"} class="hidden sm:block text-xs font-bold text-[rgb(var(--fg))] hover:text-indigo-500 transition-colors">
                    Dashboard
                  </a>
                  <a href={~p"/users/settings"} class="hidden sm:block text-xs font-bold text-[rgb(var(--muted))] hover:text-[rgb(var(--fg))] transition-colors">
                    Settings
                  </a>
                  <.link href={~p"/users/log-out"} method="delete" class="hidden sm:block text-xs font-bold text-[rgb(var(--muted))] hover:text-[rgb(var(--fg))] transition-colors">
                    Log out
                  </.link>
                </div>
              </div>
            <% else %>
              <a href="/users/log-in" class="hidden sm:block text-sm font-semibold text-[rgb(var(--muted))] hover:text-[rgb(var(--fg))] transition-colors">
                Log in
              </a>
            <% end %>

            <a
              href="/users/register"
              class="group relative inline-flex items-center justify-center px-6 py-2.5 text-sm font-extrabold text-white
                     bg-indigo-600 rounded-full hover:bg-indigo-500 transition-all duration-200
                     shadow-lg shadow-indigo-600/25 focus:outline-none focus:ring-2 focus:ring-[rgb(var(--ring))] focus:ring-offset-2 focus:ring-offset-[rgb(var(--bg))]"
            >
              <span class="absolute inset-0 rounded-full opacity-0 group-hover:opacity-25 bg-[linear-gradient(110deg,rgba(255,255,255,.55),transparent_45%)] transition-opacity"></span>
              Start free trial
              <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0-5 5M6 12h12"></path>
              </svg>
            </a>
          </div>
        </div>
      </div>
    </nav>
    <style>
      /* Temporary utility for SSR theme icons if custom variant isn't processed yet */
      [data-theme="dark"] #moonIconSimple { display: none; }
      [data-theme="light"] #sunIcon { display: none; }
      [data-theme="dark"] #sunIcon { display: inline-block; }
    </style>
    """
  end

  @doc """
  The footer for the landing page.
  """
  def footer(assigns) do
    ~H"""
    <footer class="border-t border-[rgb(var(--border))] py-12 bg-[rgb(var(--bg))]">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-8">
          <div class="flex items-center gap-3">
            <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
              <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
              </svg>
            </div>
            <div>
              <div class="font-extrabold">FieldHub</div>
              <div class="text-sm text-[rgb(var(--muted))]">Dispatch and field execution, unified.</div>
            </div>
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-8 text-sm">
            <div>
              <div class="font-extrabold mb-3">Product</div>
              <ul class="space-y-2 text-[rgb(var(--muted))]">
                <li><a href="#features" class="hover:text-[rgb(var(--fg))]">Features</a></li>
                <li><a href="#pricing" class="hover:text-[rgb(var(--fg))]">Pricing</a></li>
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">API</a></li>
              </ul>
            </div>
            <div>
              <div class="font-extrabold mb-3">Company</div>
              <ul class="space-y-2 text-[rgb(var(--muted))]">
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">About</a></li>
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">Blog</a></li>
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">Careers</a></li>
              </ul>
            </div>
            <div>
              <div class="font-extrabold mb-3">Support</div>
              <ul class="space-y-2 text-[rgb(var(--muted))]">
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">Docs</a></li>
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">Status</a></li>
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">Contact</a></li>
              </ul>
            </div>
            <div>
              <div class="font-extrabold mb-3">Legal</div>
              <ul class="space-y-2 text-[rgb(var(--muted))]">
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">Privacy</a></li>
                <li><a href="#" class="hover:text-[rgb(var(--fg))]">Terms</a></li>
              </ul>
            </div>
          </div>
        </div>

        <div class="mt-10 pt-8 border-t border-[rgb(var(--border))] text-center text-sm text-[rgb(var(--muted2))]">
          <p>&copy; 2026 FieldHub Platform. All rights reserved.</p>
        </div>
      </div>
    </footer>
    """
  end
end
