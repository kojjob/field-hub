defmodule FieldHubWeb.TechLive.JobShow do
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs

  @impl true
  def mount(%{"number" => number}, _session, socket) do
    user = socket.assigns.current_scope.user
    org_id = user.organization_id
    job = Jobs.get_job_by_number!(org_id, number) |> FieldHub.Repo.preload([:customer])

    history =
      Jobs.list_jobs_for_customer(org_id, job.customer_id) |> Enum.reject(&(&1.id == job.id))

    technician = FieldHub.Dispatch.get_technician_by_user_id(user.id)

    {:ok,
     assign(socket,
       job: job,
       history: history,
       page_title: job.title,
       technician: technician,
       pending_status_action: nil,
       pending_status_meta: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl bg-gray-50 min-h-screen pb-24">
      <!-- Header with Back Button -->
      <div class="sticky top-0 z-10 bg-white border-b border-gray-200 px-4 py-3 flex items-center shadow-sm">
        <.link
          navigate={~p"/tech/dashboard"}
          class="mr-4 text-gray-500 hover:text-gray-700 transition-colors"
        >
          <.icon name="hero-arrow-left" class="w-6 h-6" />
        </.link>
        <h1 class="text-lg font-semibold text-gray-900 truncate">{@job.title}</h1>
      </div>

      <div class="p-4 space-y-4">
        <!-- Job Status & Number -->
        <div class="bg-white p-4 rounded-xl shadow-sm border border-gray-200">
          <div class="flex justify-between items-start mb-2">
            <div>
              <p class="text-xs font-bold text-gray-400 uppercase tracking-wider">
                Job #{@job.number}
              </p>
              <h2 class="text-xl font-bold text-gray-900 mt-1">{@job.title}</h2>
            </div>
            <span class={"inline-flex items-center px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide " <> status_color(@job.status)}>
              {String.replace(@job.status, "_", " ") |> String.capitalize()}
            </span>
          </div>

          <div class="flex items-center space-x-4 mt-4 pt-4 border-t border-gray-100 italic text-gray-600 text-sm">
            <div class="flex items-center">
              <.icon name="hero-calendar" class="w-4 h-4 mr-1.5 opacity-40" />
              {Calendar.strftime(@job.scheduled_date, "%b %d")}
            </div>
            <div class="flex items-center">
              <.icon name="hero-clock" class="w-4 h-4 mr-1.5 opacity-40" />
              {Calendar.strftime(@job.scheduled_start, "%I:%M%p")}
            </div>
          </div>
        </div>
        
    <!-- Action Bar (Sticky Bottom in Mobile) -->
        <div class="fixed bottom-0 left-0 right-0 p-4 bg-white/80 backdrop-blur-md border-t border-gray-200 z-20">
          <div class="max-w-2xl mx-auto flex space-x-3">
            {render_actions(assigns)}
          </div>
        </div>

        <.modal
          :if={@pending_status_action}
          id="status-confirm-modal"
          on_cancel={JS.push("cancel_status_confirm")}
        >
          <div class="space-y-2">
            <h3 class="text-lg font-black tracking-tight text-zinc-900 dark:text-white">
              {@pending_status_meta.title}
            </h3>
            <p class="text-sm text-zinc-600 dark:text-zinc-300 leading-relaxed">
              {@pending_status_meta.body}
            </p>
          </div>
          <:confirm>
            <button
              id="status-confirm-modal-confirm"
              phx-click="confirm_status_action"
              phx-value-action={@pending_status_action}
              class={@pending_status_meta.confirm_class}
            >
              {@pending_status_meta.confirm_label}
            </button>
          </:confirm>
          <:cancel>Cancel</:cancel>
        </.modal>
        
    <!-- Description -->
        <div class="bg-white p-4 rounded-xl shadow-sm border border-gray-200">
          <h3 class="text-sm font-bold text-gray-900 mb-2 flex items-center">
            <.icon name="hero-document-text" class="w-4 h-4 mr-2 text-primary" /> Description
          </h3>
          <p class="text-gray-700 text-sm leading-relaxed">
            {@job.description || "No description provided."}
          </p>
        </div>
        
    <!-- Customer Card -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="px-4 py-3 bg-gray-50 border-b border-gray-200 flex justify-between items-center">
            <h3 class="text-sm font-bold text-gray-900 flex items-center">
              <.icon name="hero-user" class="w-4 h-4 mr-2 text-primary" /> Customer
            </h3>
            <div class="flex space-x-2">
              <a
                href={"tel:#{@job.customer.phone}"}
                class="p-2.5 bg-primary/10 text-primary rounded-xl hover:bg-primary/20 active:scale-95 transition-all"
              >
                <.icon name="hero-phone" class="w-5 h-5" />
              </a>
              <a
                href={"#{map_link(@job)}"}
                target="_blank"
                class="p-2.5 bg-green-50 text-green-600 rounded-xl hover:bg-green-100 active:scale-95 transition-all"
              >
                <.icon name="hero-map-pin" class="w-5 h-5" />
              </a>
            </div>
          </div>
          <div class="p-4">
            <p class="font-bold text-gray-900 text-lg">{@job.customer.name}</p>
            <p class="text-sm text-gray-500 mt-1 flex items-start">
              <.icon name="hero-map-pin" class="w-4 h-4 mr-1 text-gray-300 shrink-0 mt-0.5" />
              {formatted_address(@job.customer)}
            </p>
            <div class="mt-4">
              <a
                href={"#{map_link(@job)}"}
                target="_blank"
                class="w-full flex justify-center items-center px-4 py-2.5 border border-primary shadow-sm text-sm font-bold rounded-xl text-primary bg-white hover:bg-primary/5 active:scale-[0.98] transition-all"
              >
                <.icon name="hero-map" class="w-4 h-4 mr-2" /> Navigate to Job
              </a>
            </div>
          </div>
        </div>
        
    <!-- Notes Section -->
        <%= if @job.technician_notes || @job.internal_notes do %>
          <div class="bg-yellow-50 p-4 rounded-xl shadow-sm border border-yellow-100 space-y-3">
            <h3 class="text-xs font-bold text-yellow-800 uppercase tracking-wider flex items-center">
              <.icon name="hero-information-circle" class="w-4 h-4 mr-2" /> Critical Notes
            </h3>
            <%= if @job.internal_notes do %>
              <div class="text-sm text-yellow-900 bg-white/50 p-2 rounded-lg">
                <span class="font-bold block text-xs opacity-60 mb-1">Dispatch Notes:</span>
                {@job.internal_notes}
              </div>
            <% end %>
            <%= if @job.technician_notes do %>
              <div class="text-sm text-yellow-900 bg-white/50 p-2 rounded-lg">
                <span class="font-bold block text-xs opacity-60 mb-1">Previous Tech Notes:</span>
                {@job.technician_notes}
              </div>
            <% end %>
          </div>
        <% end %>
        
    <!-- History Section -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200">
          <div class="px-4 py-3 border-b border-gray-100">
            <h3 class="text-sm font-bold text-gray-900 flex items-center">
              <.icon name="hero-clock" class="w-4 h-4 mr-2 text-primary" /> Service History
            </h3>
          </div>
          <div class="divide-y divide-gray-50">
            <%= if Enum.empty?(@history) do %>
              <div class="p-4 text-center text-sm text-gray-400">
                First time service at this location.
              </div>
            <% else %>
              <%= for h <- Enum.take(@history, 3) do %>
                <div class="p-4">
                  <div class="flex justify-between items-start mb-1">
                    <span class="text-xs font-bold text-gray-900">{h.title}</span>
                    <span class="text-[10px] text-gray-400 font-medium tracking-tight uppercase">
                      {Calendar.strftime(h.inserted_at, "%m/%d/%Y")}
                    </span>
                  </div>
                  <p class="text-xs text-gray-500 line-clamp-2">
                    {h.work_performed || "No work details recorded."}
                  </p>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>

        <div id="geolocation-tracking" phx-hook="Geolocation" data-auto-start="true"></div>
      </div>
    </div>
    """
  end

  defp render_actions(assigns) do
    ~H"""
    <%= case @job.status do %>
      <% "scheduled" -> %>
        <button
          id="tech-start-travel-btn"
          phx-click="open_status_confirm"
          phx-value-action="start_travel"
          class="flex-1 bg-primary text-white font-bold py-3.5 rounded-2xl shadow-lg shadow-primary/30 active:scale-[0.98] transition-all"
        >
          Start Travel
        </button>
      <% "dispatched" -> %>
        <button
          id="tech-start-travel-btn"
          phx-click="open_status_confirm"
          phx-value-action="start_travel"
          class="flex-1 bg-primary text-white font-bold py-3.5 rounded-2xl shadow-lg shadow-primary/30 active:scale-[0.98] transition-all"
        >
          Start Travel
        </button>
      <% "en_route" -> %>
        <button
          id="tech-arrive-btn"
          phx-click="open_status_confirm"
          phx-value-action="arrive"
          class="flex-1 bg-purple-600 text-white font-bold py-3.5 rounded-2xl shadow-lg shadow-purple-200 active:scale-[0.98] transition-all"
        >
          Arrived On Site
        </button>
      <% "on_site" -> %>
        <div class="flex gap-3 w-full">
          <button
            id="tech-start-work-btn"
            phx-click="open_status_confirm"
            phx-value-action="start_work"
            class="flex-1 bg-yellow-500 text-white font-bold py-3.5 rounded-2xl shadow-lg shadow-yellow-200 active:scale-[0.98] transition-all text-sm"
          >
            Start Work
          </button>
          <button
            id="tech-complete-job-btn"
            phx-click="complete_job"
            class="flex-1 bg-green-600 text-white font-bold py-3.5 rounded-2xl shadow-lg shadow-green-200 active:scale-[0.98] transition-all text-sm"
          >
            Complete
          </button>
        </div>
      <% "in_progress" -> %>
        <button
          id="tech-complete-job-btn"
          phx-click="complete_job"
          class="flex-1 bg-green-600 text-white font-bold py-3.5 rounded-2xl shadow-lg shadow-green-200 active:scale-[0.98] transition-all"
        >
          Complete Job
        </button>
      <% _ -> %>
        <div class="flex-1 text-center py-3 text-gray-400 font-medium">
          Job Status: {String.capitalize(@job.status)}
        </div>
    <% end %>
    """
  end

  @impl true
  def handle_event("update_location", %{"lat" => lat, "lng" => lng}, socket) do
    if socket.assigns.technician do
      FieldHub.Dispatch.update_technician_location(socket.assigns.technician, lat, lng)

      if socket.assigns.job.status == "en_route" do
        FieldHub.Jobs.broadcast_job_location_update(socket.assigns.job.id, lat, lng)
      end
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("location_error", params, socket) do
    IO.puts("Location error for technician #{socket.assigns.technician.id}: #{inspect(params)}")
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_status_confirm", %{"action" => action}, socket) do
    {:noreply,
     socket
     |> assign(:pending_status_action, action)
     |> assign(:pending_status_meta, status_confirm_meta(action))}
  end

  @impl true
  def handle_event("confirm_status_action", %{"action" => action}, socket) do
    socket = assign(socket, pending_status_action: nil, pending_status_meta: nil)

    {:noreply, apply_status_action(socket, action)}
  end

  @impl true
  def handle_event("cancel_status_confirm", _params, socket) do
    {:noreply, assign(socket, pending_status_action: nil, pending_status_meta: nil)}
  end

  @impl true
  def handle_event("start_travel", _, socket) do
    {:noreply, apply_status_action(socket, "start_travel")}
  end

  @impl true
  def handle_event("arrive", _, socket) do
    {:noreply, apply_status_action(socket, "arrive")}
  end

  @impl true
  def handle_event("start_work", _, socket) do
    {:noreply, apply_status_action(socket, "start_work")}
  end

  @impl true
  def handle_event("complete_job", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/tech/jobs/#{socket.assigns.job}/complete")}
  end

  defp apply_status_action(socket, "start_travel") do
    case Jobs.start_travel(socket.assigns.job) do
      {:ok, job} ->
        job = FieldHub.Repo.preload(job, [:customer])
        assign(socket, job: job)

      {:error, _} ->
        put_flash(socket, :error, "Could not update status")
    end
  end

  defp apply_status_action(socket, "arrive") do
    case Jobs.arrive_on_site(socket.assigns.job) do
      {:ok, job} ->
        job = FieldHub.Repo.preload(job, [:customer])
        assign(socket, job: job)

      {:error, _} ->
        put_flash(socket, :error, "Could not update status")
    end
  end

  defp apply_status_action(socket, "start_work") do
    case Jobs.start_work(socket.assigns.job) do
      {:ok, job} ->
        job = FieldHub.Repo.preload(job, [:customer])
        assign(socket, job: job)

      {:error, _} ->
        put_flash(socket, :error, "Could not update status")
    end
  end

  defp apply_status_action(socket, _), do: socket

  defp status_confirm_meta("start_travel") do
    %{
      title: "Start travel?",
      body: "This marks the job as en route and starts travel tracking.",
      confirm_label: "Start Travel",
      confirm_class:
        "px-5 py-2.5 rounded-xl text-sm font-bold text-white bg-primary hover:bg-primary/90 transition-all"
    }
  end

  defp status_confirm_meta("arrive") do
    %{
      title: "Confirm arrival?",
      body: "This marks the job as on site. Only confirm when you have arrived.",
      confirm_label: "Mark Arrived",
      confirm_class:
        "px-5 py-2.5 rounded-xl text-sm font-bold text-white bg-purple-600 hover:bg-purple-700 transition-all"
    }
  end

  defp status_confirm_meta("start_work") do
    %{
      title: "Start work now?",
      body: "This marks the job as in progress and begins time tracking.",
      confirm_label: "Start Work",
      confirm_class:
        "px-5 py-2.5 rounded-xl text-sm font-bold text-white bg-yellow-500 hover:bg-yellow-600 transition-all"
    }
  end

  defp status_confirm_meta(_action) do
    %{
      title: "Confirm status change",
      body: "Please confirm you want to update this job.",
      confirm_label: "Confirm",
      confirm_class:
        "px-5 py-2.5 rounded-xl text-sm font-bold text-white bg-primary hover:bg-primary/90 transition-all"
    }
  end

  defp status_color("scheduled"), do: "bg-primary/10 text-primary border border-primary/20"
  defp status_color("en_route"), do: "bg-purple-100 text-purple-700 border border-purple-200"
  defp status_color("in_progress"), do: "bg-yellow-100 text-yellow-700 border border-yellow-200"
  defp status_color("completed"), do: "bg-green-100 text-green-700 border border-green-200"
  defp status_color("cancelled"), do: "bg-red-100 text-red-700 border border-red-200"
  defp status_color(_), do: "bg-gray-100 text-gray-700 border border-gray-200"

  defp formatted_address(customer) do
    [customer.address_line1, customer.address_line2, customer.city, customer.state, customer.zip]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end

  defp map_link(job) do
    # Simple Google Maps link
    query = URI.encode_www_form(formatted_address(job.customer))
    "https://maps.google.com/?daddr=#{query}"
  end
end
