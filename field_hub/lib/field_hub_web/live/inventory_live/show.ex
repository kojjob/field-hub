defmodule FieldHubWeb.InventoryLive.Show do
  use FieldHubWeb, :live_view

  alias FieldHub.Inventory

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    org_id = user.organization_id

    socket =
      socket
      |> assign(:org_id, org_id)
      |> assign(:current_nav, :inventory)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    part = Inventory.get_part!(socket.assigns.org_id, id)

    {:noreply,
     socket
     |> assign(:page_title, part.name)
     |> assign(:part, part)}
  end

  @impl true
  def handle_event("adjust_stock", %{"adjustment" => adjustment}, socket) do
    adj = String.to_integer(adjustment)
    part = socket.assigns.part

    case Inventory.adjust_stock(part, adj) do
      {:ok, updated_part} ->
        {:noreply,
         socket
         |> assign(:part, updated_part)
         |> put_flash(:info, "Stock adjusted")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to adjust stock")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center gap-2 text-sm text-zinc-500 dark:text-zinc-400">
        <.link navigate={~p"/inventory"} class="font-semibold hover:text-zinc-900 dark:hover:text-white transition-colors">
          Inventory
        </.link>
        <.icon name="hero-chevron-right" class="h-4 w-4" />
        <span class="font-semibold text-zinc-900 dark:text-white">{@part.name}</span>
      </div>

      <div class="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-white">{@part.name}</h1>
          <p class="text-sm text-zinc-500">{@part.sku || "No SKU"}</p>
        </div>

        <.link
          navigate={~p"/inventory/#{@part.id}/edit"}
          class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-200 font-semibold hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors"
        >
          <.icon name="hero-pencil-square" class="h-5 w-5" />
          Edit Part
        </.link>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Info -->
        <div class="lg:col-span-2 space-y-6">
          <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6">
            <h3 class="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-4">Details</h3>

            <dl class="grid grid-cols-2 gap-4">
              <div>
                <dt class="text-xs text-zinc-500">Category</dt>
                <dd class="text-sm font-semibold text-zinc-900 dark:text-white capitalize">{@part.category}</dd>
              </div>
              <div>
                <dt class="text-xs text-zinc-500">Unit Price</dt>
                <dd class="text-sm font-semibold text-teal-600">{format_money(@part.unit_price)}</dd>
              </div>
              <div class="col-span-2">
                <dt class="text-xs text-zinc-500">Description</dt>
                <dd class="text-sm text-zinc-700 dark:text-zinc-300 mt-1">
                  {@part.description || "No description"}
                </dd>
              </div>
            </dl>
          </div>
        </div>

        <!-- Stock Panel -->
        <div class="space-y-6">
          <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-6">
            <h3 class="text-sm font-semibold text-zinc-500 uppercase tracking-wide mb-4">Stock Level</h3>

            <div class="text-center py-4">
              <p class={[
                "text-4xl font-bold",
                @part.quantity_on_hand <= @part.reorder_point && "text-amber-600",
                @part.quantity_on_hand > @part.reorder_point && "text-zinc-900 dark:text-white"
              ]}>
                {@part.quantity_on_hand}
              </p>
              <p class="text-xs text-zinc-500 mt-1">units in stock</p>

              <%= if @part.quantity_on_hand <= @part.reorder_point do %>
                <div class="mt-3 px-3 py-2 rounded-lg bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/20">
                  <p class="text-xs font-semibold text-amber-700 dark:text-amber-400">
                    Low stock! Reorder point: {@part.reorder_point}
                  </p>
                </div>
              <% end %>
            </div>

            <div class="border-t border-zinc-100 dark:border-zinc-800 pt-4 mt-4">
              <p class="text-xs text-zinc-500 mb-2">Quick Adjust</p>
              <div class="flex gap-2">
                <button
                  phx-click="adjust_stock"
                  phx-value-adjustment="-1"
                  class="flex-1 px-3 py-2 rounded-lg bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400 font-semibold text-sm hover:bg-red-100 dark:hover:bg-red-500/20 transition-colors"
                >
                  -1
                </button>
                <button
                  phx-click="adjust_stock"
                  phx-value-adjustment="1"
                  class="flex-1 px-3 py-2 rounded-lg bg-green-50 dark:bg-green-500/10 text-green-600 dark:text-green-400 font-semibold text-sm hover:bg-green-100 dark:hover:bg-green-500/20 transition-colors"
                >
                  +1
                </button>
              </div>
              <div class="flex gap-2 mt-2">
                <button
                  phx-click="adjust_stock"
                  phx-value-adjustment="-10"
                  class="flex-1 px-3 py-2 rounded-lg bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300 font-semibold text-sm hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors"
                >
                  -10
                </button>
                <button
                  phx-click="adjust_stock"
                  phx-value-adjustment="10"
                  class="flex-1 px-3 py-2 rounded-lg bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300 font-semibold text-sm hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors"
                >
                  +10
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_money(nil), do: "$0.00"
  defp format_money(%Decimal{} = amount), do: "$#{Decimal.round(amount, 2)}"
end
