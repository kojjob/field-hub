defmodule FieldHubWeb.JobLive.Show do
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs
  alias FieldHub.Jobs.JobEvent
  alias FieldHub.Dispatch.Broadcaster
  alias FieldHub.Repo

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    org_id = current_user.organization_id

    socket =
      socket
      |> assign(:current_organization, %FieldHub.Accounts.Organization{id: org_id})
      |> assign(:current_user, current_user)
      |> assign(:current_nav, :jobs)
      |> assign(:job_events, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"number" => number}, _, socket) do
    org_id = socket.assigns.current_organization.id

    if connected?(socket) do
      Broadcaster.subscribe_to_org(org_id)
    end

    job =
      Jobs.get_job_by_number!(org_id, number)
      |> Repo.preload([:customer, :technician])

    job_events = load_job_events(job.id)

    {:noreply,
     socket
     |> assign(:page_title, "Job ##{job.number}")
     |> assign(:job, job)
     |> assign(:job_events, job_events)}
  end

  # Real-time updates
  @impl true
  def handle_info({:job_updated, updated_job}, socket) do
    if updated_job.id == socket.assigns.job.id do
      job =
        Jobs.get_job!(socket.assigns.current_organization.id, updated_job.id)
        |> Repo.preload([:customer, :technician])

      job_events = load_job_events(job.id)

      {:noreply,
       socket
       |> assign(:job, job)
       |> assign(:job_events, job_events)
       |> assign(:page_title, "Job ##{job.number}")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({FieldHubWeb.JobLive.FormComponent, {:saved, job}}, socket) do
    # The saved job might not have preloads, so reload.
    handle_info({:job_updated, job}, socket)
  end

  # Catch-all for other messages we might subscribe to but don't care about here
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("generate_invoice", _params, socket) do
    {:noreply, put_flash(socket, :info, "Invoice generation is coming soon.")}
  end

  def handle_event("support_email_update", _params, socket) do
    {:noreply, put_flash(socket, :info, "Status update flow coming soon.")}
  end

  def handle_event("support_text_eta", _params, socket) do
    {:noreply, put_flash(socket, :info, "ETA text flow coming soon.")}
  end

  def handle_event("chat_technician", _params, socket) do
    {:noreply, put_flash(socket, :info, "Technician chat is coming soon.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <% checklist_items = checklist_items(@job) %>
    <% completed = checklist_completed_count(checklist_items) %>
    <% total = length(checklist_items) %>
    <% percent = checklist_progress_percent(completed, total) %>
    <% activity_events = recent_events(@job_events) %>
    <% map_query = map_query(@job) %>

    <div class="flex h-[calc(100vh-4rem)] overflow-hidden relative">
      <div class="flex-1 flex flex-col min-w-0 overflow-y-auto">
        <div class="space-y-6 p-6 pb-20">
          <!-- Header -->
          <div class="space-y-4">
            <div class="flex items-center gap-2 text-sm text-zinc-500 dark:text-zinc-400">
              <.link
                navigate={~p"/jobs"}
                class="font-semibold hover:text-zinc-900 dark:hover:text-white transition-colors"
              >
                Jobs
              </.link>
              <.icon name="hero-chevron-right" class="size-4 text-zinc-400" />
              <span class="font-semibold text-zinc-900 dark:text-white">##{@job.number}</span>
            </div>

            <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
              <div class="flex items-center gap-3">
                <h1 class="text-2xl sm:text-3xl font-black tracking-tighter text-zinc-900 dark:text-white">
                  Job ##{@job.number}
                </h1>
                <span class={[
                  "inline-flex items-center rounded-full px-3 py-1 text-[11px] font-black tracking-wide ring-1 ring-inset",
                  status_color(@job.status)
                ]}>
                  {String.upcase(status_label(@job.status))}
                </span>
              </div>

              <div class="flex items-center gap-2 flex-wrap">
                <.link
                  navigate={~p"/jobs/#{@job}/edit"}
                  class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 text-zinc-700 dark:text-zinc-200 text-sm font-bold hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-all"
                >
                  <.icon name="hero-pencil-square" class="size-5" /> Edit Job
                </.link>

                <.link
                  navigate={~p"/dispatch"}
                  class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 text-zinc-700 dark:text-zinc-200 text-sm font-bold hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-all"
                >
                  <.icon name="hero-paper-airplane" class="size-5" /> Dispatch
                </.link>

                <button
                  id="job-generate-invoice"
                  type="button"
                  phx-click="generate_invoice"
                  class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-primary text-white text-sm font-bold shadow-lg shadow-primary/20 hover:brightness-110 transition-all border-b-4 border-emerald-800 active:border-b-0 active:translate-y-1"
                >
                  <.icon name="hero-document-arrow-down" class="size-5" /> Generate Invoice
                </button>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <!-- Left column -->
            <div class="lg:col-span-8 space-y-6">
              <!-- Job Overview -->
              <div
                id="job-overview"
                class="bg-white dark:bg-zinc-900 rounded-[28px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden"
              >
                <div class="p-6 border-b border-zinc-100 dark:border-zinc-800 flex items-center gap-3">
                  <div class="size-10 rounded-2xl bg-primary/10 flex items-center justify-center">
                    <.icon name="hero-clipboard-document-check" class="size-5 text-primary" />
                  </div>
                  <div>
                    <h3 class="text-base font-black text-zinc-900 dark:text-white tracking-tight">
                      Job Overview
                    </h3>
                    <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                      Customer, description, and location
                    </p>
                  </div>
                </div>

                <div class="p-6 grid grid-cols-1 lg:grid-cols-12 gap-6">
                  <div class="lg:col-span-4 space-y-2">
                    <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
                      Customer
                    </p>

                    <%= if @job.customer do %>
                      <.link
                        navigate={~p"/customers/#{@job.customer}"}
                        class="text-sm font-black text-zinc-900 dark:text-white hover:text-primary transition-colors"
                      >
                        {@job.customer.name}
                      </.link>
                      <p
                        :if={present?(@job.customer.phone)}
                        class="text-xs text-zinc-500 dark:text-zinc-400"
                      >
                        Contact: {@job.customer.phone}
                      </p>
                    <% else %>
                      <p class="text-sm font-bold text-zinc-600 dark:text-zinc-300">
                        No customer linked
                      </p>
                    <% end %>
                  </div>

                  <div class="lg:col-span-4 space-y-2">
                    <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
                      Description
                    </p>
                    <p class="text-sm text-zinc-700 dark:text-zinc-200 whitespace-pre-line">
                      {blank_fallback(@job.description, "No description provided.")}
                    </p>
                  </div>

                  <div class="lg:col-span-4 space-y-3">
                    <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
                      Site Location
                    </p>

                    <div class="h-28 rounded-2xl overflow-hidden border border-zinc-200 dark:border-zinc-700 bg-zinc-100 dark:bg-zinc-900 relative">
                      <%= if map_query do %>
                        <iframe
                          title="Job location map"
                          class="absolute inset-0 h-full w-full"
                          src={google_maps_embed_url(map_query)}
                          loading="lazy"
                          referrerpolicy="no-referrer-when-downgrade"
                          allowfullscreen
                        />

                        <div class="absolute inset-0 pointer-events-none bg-gradient-to-t from-zinc-950/15 via-transparent to-transparent" />

                        <a
                          href={google_maps_url(map_query)}
                          target="_blank"
                          rel="noreferrer"
                          class="absolute top-3 right-3 inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-white/90 dark:bg-zinc-950/40 backdrop-blur border border-zinc-200/60 dark:border-zinc-700 text-xs font-black text-zinc-700 dark:text-zinc-100 hover:brightness-105 transition-all"
                        >
                          View Large Map
                        </a>
                      <% else %>
                        <div class="absolute inset-0 flex items-center justify-center">
                          <div class="size-11 rounded-2xl bg-white/80 dark:bg-zinc-950/30 backdrop-blur flex items-center justify-center border border-white/60 dark:border-zinc-700">
                            <.icon name="hero-map" class="size-6 text-primary" />
                          </div>
                        </div>
                      <% end %>
                    </div>

                    <div class="flex items-start gap-2 text-xs text-zinc-600 dark:text-zinc-300">
                      <.icon name="hero-map-pin" class="size-4 text-zinc-400 mt-0.5" />
                      <span>{service_address(@job)}</span>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Checklist & Tasks -->
              <div
                id="job-checklist"
                class="bg-white dark:bg-zinc-900 rounded-[28px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden"
              >
                <div class="p-6 border-b border-zinc-100 dark:border-zinc-800 flex items-center justify-between gap-4">
                  <div class="flex items-center gap-3">
                    <div class="size-10 rounded-2xl bg-primary/10 flex items-center justify-center">
                      <.icon name="hero-check-circle" class="size-5 text-primary" />
                    </div>
                    <div>
                      <h3 class="text-base font-black text-zinc-900 dark:text-white tracking-tight">
                        Checklist & Tasks
                      </h3>
                      <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                        {completed} of {total} completed
                      </p>
                    </div>
                  </div>

                  <div class="w-44">
                    <div class="h-2 rounded-full bg-zinc-100 dark:bg-zinc-800 overflow-hidden">
                      <div
                        class="h-full rounded-full bg-primary transition-all"
                        style={"width: #{percent}%;"}
                      />
                    </div>
                  </div>
                </div>

                <div class="divide-y divide-zinc-100 dark:divide-zinc-800">
                  <%= if checklist_items == [] do %>
                    <div class="p-6">
                      <div class="rounded-2xl border border-dashed border-zinc-200 dark:border-zinc-700 bg-zinc-50/40 dark:bg-zinc-800/20 p-6 text-center">
                        <p class="text-sm font-bold text-zinc-700 dark:text-zinc-200">
                          No checklist items yet
                        </p>
                        <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                          Add checklist items via job metadata.
                        </p>
                      </div>
                    </div>
                  <% else %>
                    <%= for item <- checklist_items do %>
                      <div class="p-4 sm:p-5 flex items-center justify-between gap-3 hover:bg-zinc-50 dark:hover:bg-zinc-800/40 transition-colors">
                        <div class="flex items-center gap-3 min-w-0">
                          <div class={[
                            "size-6 rounded-full border flex items-center justify-center shrink-0",
                            checklist_done?(item) && "bg-primary/10 border-primary/20",
                            !checklist_done?(item) &&
                              "bg-white dark:bg-zinc-900 border-zinc-200 dark:border-zinc-700"
                          ]}>
                            <%= if checklist_done?(item) do %>
                              <.icon name="hero-check" class="size-4 text-primary" />
                            <% end %>
                          </div>

                          <p class={[
                            "text-sm font-semibold truncate",
                            checklist_done?(item) && "text-zinc-500 line-through",
                            !checklist_done?(item) && "text-zinc-900 dark:text-white"
                          ]}>
                            {checklist_title(item)}
                          </p>
                        </div>

                        <span
                          :if={checklist_badge(item)}
                          class="text-[10px] font-black uppercase tracking-widest px-2 py-1 rounded-full bg-primary/10 text-primary border border-primary/20 shrink-0"
                        >
                          {checklist_badge(item)}
                        </span>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
              
    <!-- Field Evidence & Media -->
              <div
                id="job-media"
                class="bg-white dark:bg-zinc-900 rounded-[28px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden"
              >
                <div class="p-6 border-b border-zinc-100 dark:border-zinc-800 flex items-center justify-between gap-4">
                  <div class="flex items-center gap-3">
                    <div class="size-10 rounded-2xl bg-primary/10 flex items-center justify-center">
                      <.icon name="hero-photo" class="size-5 text-primary" />
                    </div>
                    <div>
                      <h3 class="text-base font-black text-zinc-900 dark:text-white tracking-tight">
                        Field Evidence & Media
                      </h3>
                      <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                        Photos and signatures
                      </p>
                    </div>
                  </div>

                  <a
                    :if={@job.photos != []}
                    href="#"
                    class="text-xs font-black text-primary hover:underline"
                  >
                    Download all ({length(@job.photos)})
                  </a>
                </div>

                <div class="p-6">
                  <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                    <%= for photo <- @job.photos do %>
                      <a
                        href={photo}
                        target="_blank"
                        rel="noreferrer"
                        class="group aspect-square rounded-2xl overflow-hidden border border-zinc-200 dark:border-zinc-700 bg-zinc-50 dark:bg-zinc-800/40 hover:shadow-md transition-all"
                      >
                        <img
                          src={photo}
                          class="h-full w-full object-cover group-hover:scale-[1.02] transition-transform"
                          alt=""
                        />
                      </a>
                    <% end %>

                    <div
                      :if={present?(@job.customer_signature)}
                      class="aspect-square rounded-2xl border border-dashed border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-900 flex flex-col items-center justify-center gap-2"
                    >
                      <.icon name="hero-pencil" class="size-6 text-zinc-400" />
                      <p class="text-xs font-bold text-zinc-600 dark:text-zinc-300">Signature</p>
                    </div>

                    <div
                      :if={@job.photos == [] && !present?(@job.customer_signature)}
                      class="col-span-2 sm:col-span-4 rounded-2xl border border-dashed border-zinc-200 dark:border-zinc-700 bg-zinc-50/40 dark:bg-zinc-800/20 p-8 text-center"
                    >
                      <p class="text-sm font-bold text-zinc-700 dark:text-zinc-200">
                        No media uploaded yet
                      </p>
                      <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                        Photos and signatures will appear here once captured.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Activity Log -->
              <div
                id="job-activity"
                class="bg-white dark:bg-zinc-900 rounded-[28px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden"
              >
                <div class="p-6 border-b border-zinc-100 dark:border-zinc-800 flex items-center gap-3">
                  <div class="size-10 rounded-2xl bg-primary/10 flex items-center justify-center">
                    <.icon name="hero-clock" class="size-5 text-primary" />
                  </div>
                  <div>
                    <h3 class="text-base font-black text-zinc-900 dark:text-white tracking-tight">
                      Activity Log
                    </h3>
                    <p class="text-xs font-bold text-zinc-400 dark:text-zinc-500 uppercase tracking-wide">
                      Status changes and updates
                    </p>
                  </div>
                </div>

                <div class="p-6 space-y-4">
                  <%= if activity_events == [] do %>
                    <div class="rounded-2xl border border-dashed border-zinc-200 dark:border-zinc-700 bg-zinc-50/40 dark:bg-zinc-800/20 p-6 text-center">
                      <p class="text-sm font-bold text-zinc-700 dark:text-zinc-200">
                        No activity yet
                      </p>
                      <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                        Job events will show here as dispatch updates roll in.
                      </p>
                    </div>
                  <% else %>
                    <%= for event <- activity_events do %>
                      <div class="flex items-start gap-3">
                        <div class="mt-0.5 size-8 rounded-2xl bg-primary/10 flex items-center justify-center shrink-0">
                          <.icon name={event_icon(event.event_type)} class="size-4 text-primary" />
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-sm font-bold text-zinc-900 dark:text-white">
                            {event_title(event.event_type)}
                          </p>
                          <p class="text-xs text-zinc-500 dark:text-zinc-400">
                            {event_detail(event)}
                          </p>
                        </div>
                        <p class="text-[11px] text-zinc-400 dark:text-zinc-500 shrink-0">
                          {format_event_time(event.inserted_at)}
                        </p>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
            
    <!-- Right column -->
            <div class="lg:col-span-4 space-y-6">
              <!-- Technician -->
              <div
                id="job-tech"
                class="bg-white dark:bg-zinc-900 rounded-[28px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden"
              >
                <div class="p-6 border-b border-zinc-100 dark:border-zinc-800">
                  <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
                    Technician
                  </p>
                </div>

                <div class="p-6">
                  <%= if @job.technician do %>
                    <div class="flex items-center gap-3">
                      <img
                        class="size-10 rounded-2xl border border-zinc-200 dark:border-zinc-700 object-cover"
                        src={technician_avatar(@job.technician)}
                        alt=""
                      />
                      <div class="flex-1">
                        <p class="text-sm font-black text-zinc-900 dark:text-white">
                          {@job.technician.name}
                        </p>
                        <p class="text-[11px] text-zinc-500 dark:text-zinc-400">
                          {technician_presence_label(@job.technician)}
                        </p>
                      </div>
                    </div>

                    <div class="mt-4 grid grid-cols-2 gap-2">
                      <button
                        type="button"
                        phx-click="chat_technician"
                        class="inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-200 dark:border-zinc-700 text-xs font-black text-zinc-700 dark:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all"
                      >
                        <.icon name="hero-chat-bubble-left-right" class="size-4" /> Chat
                      </button>

                      <a
                        href={"tel:" <> (present?(@job.technician.phone) && @job.technician.phone || "")}
                        class={[
                          "inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-zinc-50 dark:bg-zinc-800/50 border border-zinc-200 dark:border-zinc-700 text-xs font-black text-zinc-700 dark:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-all",
                          !present?(@job.technician.phone) && "pointer-events-none opacity-50"
                        ]}
                      >
                        <.icon name="hero-phone" class="size-4" /> Call
                      </a>
                    </div>
                  <% else %>
                    <p class="text-sm font-bold text-zinc-600 dark:text-zinc-300">Unassigned</p>
                  <% end %>
                </div>
              </div>
              
    <!-- Financials -->
              <div
                id="job-financials"
                class="bg-white dark:bg-zinc-900 rounded-[28px] border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden"
              >
                <div class="p-6 border-b border-zinc-100 dark:border-zinc-800 flex items-center justify-between">
                  <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
                    Financials
                  </p>
                  <span class={[
                    "text-[10px] font-black uppercase tracking-widest px-2 py-1 rounded-full border",
                    payment_status_badge(@job.payment_status)
                  ]}>
                    {payment_status_label(@job.payment_status)}
                  </span>
                </div>

                <div class="p-6 space-y-4">
                  <div class="flex items-center justify-between text-sm">
                    <p class="text-zinc-500 dark:text-zinc-400 font-semibold">Quoted</p>
                    <p class="text-zinc-900 dark:text-white font-black">
                      {format_money(@job.quoted_amount)}
                    </p>
                  </div>

                  <div class="flex items-center justify-between text-sm">
                    <p class="text-zinc-500 dark:text-zinc-400 font-semibold">Actual</p>
                    <p class="text-zinc-900 dark:text-white font-black">
                      {format_money(@job.actual_amount)}
                    </p>
                  </div>

                  <div class="pt-3 border-t border-zinc-100 dark:border-zinc-800 flex items-end justify-between">
                    <div>
                      <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
                        Total
                      </p>
                      <p class="text-xl font-black text-primary">{format_money(job_total(@job))}</p>
                    </div>

                    <div class="text-right">
                      <p class="text-[10px] font-black uppercase tracking-widest text-zinc-400 dark:text-zinc-500">
                        Estimate
                      </p>
                      <p class="text-sm font-black text-zinc-900 dark:text-white">
                        {@job.estimated_duration_minutes} min
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Customer Support -->
              <div
                id="job-support"
                class="rounded-[28px] bg-primary text-white shadow-xl shadow-primary/25 overflow-hidden"
              >
                <div class="p-6 border-b border-white/15">
                  <p class="text-[10px] font-black uppercase tracking-widest text-white/70">
                    Customer Support
                  </p>
                  <p class="mt-2 text-sm font-bold text-white/90">
                    Quick communication triggers for customer updates.
                  </p>
                </div>

                <div class="p-6 space-y-3">
                  <button
                    type="button"
                    phx-click="support_email_update"
                    class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white/15 hover:bg-white/20 border border-white/15 text-sm font-black transition-all"
                  >
                    <.icon name="hero-envelope" class="size-5" /> Email Status Update
                  </button>

                  <button
                    type="button"
                    phx-click="support_text_eta"
                    class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white/15 hover:bg-white/20 border border-white/15 text-sm font-black transition-all"
                  >
                    <.icon name="hero-chat-bubble-left" class="size-5" /> Text ETA to Client
                  </button>
                </div>
              </div>

              <div class="px-2">
                <div class="flex items-center gap-2 text-xs text-zinc-400 dark:text-zinc-500">
                  <.icon name="hero-shield-check" class="size-4" />
                  <span class="font-semibold">Insured & certified job</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_job_events(job_id) do
    JobEvent.for_job(job_id)
    |> Repo.all()
    |> Repo.preload([:actor, :technician])
  end

  defp checklist_items(job) do
    metadata = job.metadata || %{}

    cond do
      is_list(metadata["checklist"]) -> metadata["checklist"]
      is_list(metadata["checklist_items"]) -> metadata["checklist_items"]
      true -> []
    end
  end

  defp checklist_title(%{"title" => title}) when is_binary(title), do: title
  defp checklist_title(%{title: title}) when is_binary(title), do: title
  defp checklist_title(other), do: Phoenix.Naming.humanize(to_string(other))

  defp checklist_done?(%{"done" => done}), do: done == true
  defp checklist_done?(%{done: done}), do: done == true
  defp checklist_done?(%{"completed" => completed}), do: completed == true
  defp checklist_done?(%{completed: completed}), do: completed == true
  defp checklist_done?(_), do: false

  defp checklist_badge(%{"badge" => badge}) when is_binary(badge) and badge != "", do: badge
  defp checklist_badge(%{badge: badge}) when is_binary(badge) and badge != "", do: badge
  defp checklist_badge(_), do: nil

  defp checklist_completed_count(items) do
    Enum.count(items, &checklist_done?/1)
  end

  defp checklist_progress_percent(_completed, 0), do: 0

  defp checklist_progress_percent(completed, total)
       when is_integer(completed) and is_integer(total) and total > 0 do
    div(completed * 100, total)
  end

  defp checklist_progress_percent(_, _), do: 0

  defp recent_events(events) do
    events
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> Enum.take(6)
  end

  defp event_icon("created"), do: "hero-sparkles"
  defp event_icon("assigned"), do: "hero-user-plus"
  defp event_icon("unassigned"), do: "hero-user-minus"
  defp event_icon("scheduled"), do: "hero-calendar"
  defp event_icon("rescheduled"), do: "hero-calendar-days"
  defp event_icon("status_changed"), do: "hero-arrows-right-left"
  defp event_icon("travel_started"), do: "hero-truck"
  defp event_icon("arrived"), do: "hero-map-pin"
  defp event_icon("work_started"), do: "hero-play"
  defp event_icon("completed"), do: "hero-check-badge"
  defp event_icon("cancelled"), do: "hero-x-circle"
  defp event_icon(_), do: "hero-bell"

  defp event_title(type) when is_binary(type) do
    type
    |> String.replace("_", " ")
    |> Phoenix.Naming.humanize()
  end

  defp event_title(_), do: "Update"

  defp event_detail(event) do
    cond do
      event.technician && event.technician.name ->
        "By #{event.technician.name}"

      event.actor && event.actor.email ->
        "By #{event.actor.email}"

      true ->
        ""
    end
  end

  defp format_event_time(nil), do: ""

  defp format_event_time(%DateTime{} = dt) do
    dt
    |> Calendar.strftime("%I:%M %p")
    |> String.trim_leading("0")
  end

  defp format_event_time(%NaiveDateTime{} = dt) do
    dt
    |> Calendar.strftime("%I:%M %p")
    |> String.trim_leading("0")
  end

  defp format_event_time(_), do: ""

  defp technician_avatar(technician) do
    technician.avatar_url ||
      "https://ui-avatars.com/api/?name=#{URI.encode_www_form(technician.name || "Tech")}&background=10b981&color=fff"
  end

  defp technician_presence_label(technician) do
    status = technician.status || "off_duty"

    if status in ["on_job", "traveling", "en_route", "on_site", "busy"] do
      "Live ops active"
    else
      "Offline"
    end
  end

  defp payment_status_badge("paid"), do: "bg-emerald-50 text-emerald-700 border-emerald-200"
  defp payment_status_badge("invoiced"), do: "bg-blue-50 text-blue-700 border-blue-200"
  defp payment_status_badge("pending"), do: "bg-amber-50 text-amber-700 border-amber-200"
  defp payment_status_badge("refunded"), do: "bg-zinc-50 text-zinc-700 border-zinc-200"
  defp payment_status_badge(_), do: "bg-zinc-50 text-zinc-700 border-zinc-200"

  defp job_total(job) do
    cond do
      match?(%Decimal{}, job.actual_amount) -> job.actual_amount
      match?(%Decimal{}, job.quoted_amount) -> job.quoted_amount
      true -> Decimal.new(0)
    end
  end

  defp status_color("unscheduled"), do: "bg-gray-50 text-gray-600 ring-gray-500/10"
  defp status_color("scheduled"), do: "bg-blue-50 text-blue-700 ring-blue-700/10"
  defp status_color("dispatched"), do: "bg-teal-50 text-teal-700 ring-teal-700/10"
  defp status_color("en_route"), do: "bg-purple-50 text-purple-700 ring-purple-700/10"
  defp status_color("on_site"), do: "bg-yellow-50 text-yellow-800 ring-yellow-600/20"
  defp status_color("in_progress"), do: "bg-green-50 text-green-700 ring-green-600/20"
  defp status_color("completed"), do: "bg-emerald-50 text-emerald-700 ring-emerald-600/20"
  defp status_color("cancelled"), do: "bg-red-50 text-red-700 ring-red-600/10"
  defp status_color("on_hold"), do: "bg-orange-50 text-orange-700 ring-orange-600/20"
  defp status_color(_), do: "bg-gray-50 text-gray-600 ring-gray-500/10"

  defp status_label(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> Phoenix.Naming.humanize()
  end

  defp status_label(_), do: "Unknown"

  defp payment_status_label(status) when is_binary(status), do: Phoenix.Naming.humanize(status)
  defp payment_status_label(_), do: "Pending"

  defp blank_fallback(value, fallback) when is_binary(value) do
    if String.trim(value) == "", do: fallback, else: value
  end

  defp blank_fallback(_value, fallback), do: fallback

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_), do: false

  defp service_address(job) do
    [
      job.service_address,
      [job.service_city, job.service_state, job.service_zip]
      |> Enum.filter(&present?/1)
      |> Enum.join(" ")
    ]
    |> Enum.filter(&present?/1)
    |> Enum.join(", ")
    |> blank_fallback("No service address on file.")
  end

  defp map_query(job) do
    cond do
      is_number(job.service_lat) and is_number(job.service_lng) ->
        "#{job.service_lat},#{job.service_lng}"

      map_address_query = map_address_query(job) ->
        map_address_query

      true ->
        nil
    end
  end

  defp map_address_query(job) do
    query =
      [
        job.service_address,
        job.service_city,
        job.service_state,
        job.service_zip
      ]
      |> Enum.filter(&present?/1)
      |> Enum.join(", ")

    if present?(query), do: query, else: nil
  end

  defp google_maps_url(query) when is_binary(query) do
    encoded = URI.encode_www_form(query)
    "https://www.google.com/maps?q=#{encoded}"
  end

  defp google_maps_embed_url(query) when is_binary(query) do
    encoded = URI.encode_www_form(query)
    "https://www.google.com/maps?&q=#{encoded}&z=15&output=embed"
  end

  defp format_money(nil), do: "—"

  defp format_money(%Decimal{} = amount) do
    "$" <> (amount |> Decimal.round(2) |> Decimal.to_string(:normal))
  end
end
