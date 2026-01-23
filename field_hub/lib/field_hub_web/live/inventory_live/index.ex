defmodule FieldHubWeb.InventoryLive.Index do
  use FieldHubWeb, :live_view

  alias FieldHub.Inventory
  alias FieldHub.Inventory.Part

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    org_id = user.organization_id

    parts = Inventory.list_parts(org_id)
    stats = Inventory.get_inventory_stats(org_id)

    socket =
      socket
      |> assign(:org_id, org_id)
      |> assign(:parts, parts)
      |> assign(:stats, stats)
      |> assign(:search, "")
      |> assign(:page_title, "Inventory")
      |> assign(:current_nav, :inventory)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Inventory")
    |> assign(:part, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Part")
    |> assign(:part, %Part{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    part = Inventory.get_part!(socket.assigns.org_id, id)

    socket
    |> assign(:page_title, "Edit #{part.name}")
    |> assign(:part, part)
  end

  @impl true
  def handle_event("search", %{"value" => search}, socket) do
    parts =
      if String.length(search) >= 2 do
        Inventory.search_parts(socket.assigns.org_id, search)
      else
        Inventory.list_parts(socket.assigns.org_id)
      end

    {:noreply, assign(socket, parts: parts, search: search)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    part = Inventory.get_part!(socket.assigns.org_id, id)

    case Inventory.delete_part(part) do
      {:ok, _} ->
        parts = Inventory.list_parts(socket.assigns.org_id)
        {:noreply, socket |> put_flash(:info, "Part deleted") |> assign(:parts, parts)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete part")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-white">Inventory</h1>
          <p class="text-sm text-zinc-500 dark:text-zinc-400">Manage parts and materials</p>
        </div>

        <.link
          navigate={~p"/inventory/new"}
          class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-teal-600 text-white font-semibold shadow-lg hover:bg-teal-700 transition-colors"
        >
          <.icon name="hero-plus" class="h-5 w-5" />
          Add Part
        </.link>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-5">
          <p class="text-xs font-semibold text-zinc-500 uppercase tracking-wide">Total Parts</p>
          <p class="text-2xl font-bold text-zinc-900 dark:text-white mt-1">{@stats.total_parts}</p>
        </div>
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-5">
          <p class="text-xs font-semibold text-zinc-500 uppercase tracking-wide">Inventory Value</p>
          <p class="text-2xl font-bold text-teal-600 mt-1">{format_money(@stats.total_value)}</p>
        </div>
        <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-5">
          <p class="text-xs font-semibold text-zinc-500 uppercase tracking-wide">Low Stock</p>
          <p class={["text-2xl font-bold mt-1", @stats.low_stock_count > 0 && "text-amber-600" || "text-zinc-900 dark:text-white"]}>
            {@stats.low_stock_count}
          </p>
        </div>
      </div>

      <!-- Search -->
      <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-4">
        <div class="relative">
          <.icon name="hero-magnifying-glass" class="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-zinc-400" />
          <input
            type="text"
            placeholder="Search parts by name, SKU, or category..."
            value={@search}
            phx-keyup="search"
            phx-debounce="300"
            class="w-full pl-10 pr-4 py-2.5 rounded-xl bg-zinc-50 dark:bg-zinc-800 border-0 text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 focus:ring-2 focus:ring-teal-500"
          />
        </div>
      </div>

      <!-- Parts Table -->
      <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 overflow-hidden">
        <table class="w-full">
          <thead class="bg-zinc-50 dark:bg-zinc-800/50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wide">Part</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wide">SKU</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-zinc-500 uppercase tracking-wide">Category</th>
              <th class="px-6 py-3 text-right text-xs font-semibold text-zinc-500 uppercase tracking-wide">Price</th>
              <th class="px-6 py-3 text-right text-xs font-semibold text-zinc-500 uppercase tracking-wide">Stock</th>
              <th class="px-6 py-3 text-right text-xs font-semibold text-zinc-500 uppercase tracking-wide">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <%= if @parts == [] do %>
              <tr>
                <td colspan="6" class="px-6 py-12 text-center">
                  <.icon name="hero-cube" class="h-12 w-12 text-zinc-300 dark:text-zinc-600 mx-auto mb-3" />
                  <p class="text-sm font-medium text-zinc-500">No parts found</p>
                  <p class="text-xs text-zinc-400 mt-1">Add your first part to get started</p>
                </td>
              </tr>
            <% else %>
              <%= for part <- @parts do %>
                <tr class="hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors">
                  <td class="px-6 py-4">
                    <.link navigate={~p"/inventory/#{part.id}"} class="hover:text-teal-600 transition-colors">
                      <p class="font-semibold text-zinc-900 dark:text-white">{part.name}</p>
                      <%= if part.description do %>
                        <p class="text-xs text-zinc-500 truncate max-w-xs">{part.description}</p>
                      <% end %>
                    </.link>
                  </td>
                  <td class="px-6 py-4 text-sm text-zinc-600 dark:text-zinc-300">
                    {part.sku || "-"}
                  </td>
                  <td class="px-6 py-4">
                    <span class="inline-flex px-2 py-1 text-xs font-medium rounded-full bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300 capitalize">
                      {part.category}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-right text-sm font-semibold text-zinc-900 dark:text-white">
                    {format_money(part.unit_price)}
                  </td>
                  <td class="px-6 py-4 text-right">
                    <span class={[
                      "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                      part.quantity_on_hand <= part.reorder_point && "bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-400",
                      part.quantity_on_hand > part.reorder_point && "bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400"
                    ]}>
                      {part.quantity_on_hand}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <.link navigate={~p"/inventory/#{part.id}/edit"} class="p-2 hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-lg transition-colors">
                        <.icon name="hero-pencil-square" class="h-4 w-4 text-zinc-500" />
                      </.link>
                      <button
                        phx-click="delete"
                        phx-value-id={part.id}
                        data-confirm="Are you sure you want to delete this part?"
                        class="p-2 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
                      >
                        <.icon name="hero-trash" class="h-4 w-4 text-red-500" />
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal for new/edit -->
    <.modal :if={@live_action in [:new, :edit]} id="part-modal" show on_cancel={JS.patch(~p"/inventory")}>
      <.live_component
        module={FieldHubWeb.InventoryLive.FormComponent}
        id={@part.id || :new}
        title={@page_title}
        action={@live_action}
        part={@part}
        org_id={@org_id}
        patch={~p"/inventory"}
      />
    </.modal>
    """
  end

  defp format_money(nil), do: "$0.00"
  defp format_money(%Decimal{} = amount), do: "$#{Decimal.round(amount, 2)}"
  defp format_money(amount) when is_number(amount), do: "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"
end
