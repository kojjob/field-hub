defmodule FieldHubWeb.TechnicianLive.Show do
  use FieldHubWeb, :live_view

  alias FieldHub.Dispatch

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    organization_id = socket.assigns.current_organization.id
    technician = Dispatch.get_technician_by_slug!(organization_id, slug)

    {:ok,
     socket
     |> assign(:technician, technician)
     |> assign(:page_title, technician.name)
     |> assign(:current_nav, :technicians)
     |> assign(:productivity, 85)
     |> assign(:weekly_goal, 110)
     |> assign(:peak_perf, 94)
     |> assign(:show_alert, true)
     |> assign(:earnings_data, [
       %{label: "M", value: 30, active: false},
       %{label: "T", value: 45, active: false},
       %{label: "W", value: 25, active: false},
       %{label: "T", value: 60, active: false},
       %{label: "F", value: 80, active: true},
       %{label: "S", value: 50, active: false},
       %{label: "S", value: 20, active: false}
     ])}
  end

  @impl true
  def handle_event("dismiss_alert", _, socket) do
    {:noreply, assign(socket, :show_alert, false)}
  end

  @impl true
  def render(assigns) do
    technician = assigns.technician

    assigns =
      assigns
      |> assign(
        :technician_id_tag,
        "TECH-" <> String.pad_leading(Integer.to_string(technician.id), 4, "0")
      )

    ~H"""
    <div class="relative h-[calc(100vh-4rem)] overflow-y-auto bg-slate-950 font-display text-slate-200 antialiased overflow-x-hidden">
      <%!-- Profile Header Section --%>
      <header class="p-8 pb-4">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div class="flex items-center gap-6">
            <div class="relative">
              <div class="w-24 h-24 rounded-full bg-slate-800 border-4 border-slate-900 overflow-hidden">
                <img
                  alt={@technician.name}
                  class="w-full h-full object-cover"
                  src={
                    @technician.avatar_url ||
                      "https://ui-avatars.com/api/?name=#{URI.encode_www_form(@technician.name)}&background=0f172a&color=ffffff"
                  }
                />
              </div>

              <div class="absolute bottom-1 right-1 w-6 h-6 bg-[#00c291] rounded-full border-4 border-slate-950 flex items-center justify-center">
                <div class="w-2 h-2 bg-white rounded-full pulse-ring"></div>
              </div>
            </div>

            <div>
              <div class="flex items-center gap-3 mb-1">
                <h2 class="text-3xl font-extrabold text-white tracking-tight">{@technician.name}</h2>

                <span class="px-2.5 py-1 rounded-md bg-[#4F46E5]/20 text-[#4F46E5] text-[10px] font-bold uppercase tracking-widest border border-[#4F46E5]/30">
                  {status_label(@technician.status)}
                </span>
              </div>

              <p class="text-slate-400 font-medium">
                ID: {@technician_id_tag} • Field Technician • {assigns[:current_organization] &&
                  assigns.current_organization.name}
              </p>

              <div class="flex items-center gap-4 mt-2">
                <div class="flex items-center gap-1.5 text-xs font-semibold text-[#00c291]">
                  <.icon name="hero-check-circle" class="size-4" />
                  <span>Background Checked</span>
                </div>

                <div class="flex items-center gap-1.5 text-xs font-semibold text-slate-500">
                  <.icon name="hero-calendar-days" class="size-4" />
                  <span>Joined {join_month_year(@technician.inserted_at)}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="flex gap-3">
            <button
              class="px-6 py-2.5 rounded-xl border border-slate-700 text-white font-bold text-sm hover:bg-slate-900 transition-all flex items-center gap-2"
              type="button"
            >
              <.icon name="hero-adjustments-horizontal" class="size-5" /> Manage Permissions
            </button>
          </div>
        </div>
      </header>

      <%!-- Stats Grid Section --%>
      <section class="px-8 py-4 grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="glass-card rounded-2xl p-6 relative overflow-hidden group">
          <div class="absolute top-0 right-0 w-24 h-24 bg-[#00c291]/5 rounded-bl-full transition-all group-hover:scale-110">
          </div>
          <p class="text-slate-400 text-sm font-semibold mb-1 uppercase tracking-wider">
            Avg. Rating
          </p>
          <div class="flex items-end gap-2">
            <p class="text-3xl font-black text-white">4.96</p>
            <p class="text-[#00c291] text-sm font-bold mb-1">+0.2%</p>
          </div>
          <div class="flex gap-0.5 mt-2">
            <.icon name="hero-star" class="size-4 text-[#00c291]" />
            <.icon name="hero-star" class="size-4 text-[#00c291]" />
            <.icon name="hero-star" class="size-4 text-[#00c291]" />
            <.icon name="hero-star" class="size-4 text-[#00c291]" />
            <.icon name="hero-star" class="size-4 text-[#00c291]" />
          </div>
        </div>

        <div class="glass-card rounded-2xl p-6 relative overflow-hidden group">
          <div class="absolute top-0 right-0 w-24 h-24 bg-[#4F46E5]/5 rounded-bl-full transition-all group-hover:scale-110">
          </div>
          <p class="text-slate-400 text-sm font-semibold mb-1 uppercase tracking-wider">On-Time %</p>
          <div class="flex items-end gap-2">
            <p class="text-3xl font-black text-white">98.2%</p>
            <p class="text-[#00c291] text-sm font-bold mb-1">+1.4%</p>
          </div>
          <div class="w-full bg-slate-800 h-1.5 rounded-full mt-4">
            <div class="bg-[#4F46E5] h-full rounded-full" style="width: 98%;"></div>
          </div>
        </div>

        <div class="glass-card rounded-2xl p-6 relative overflow-hidden group">
          <div class="absolute top-0 right-0 w-24 h-24 bg-emerald-500/5 rounded-bl-full transition-all group-hover:scale-110">
          </div>
          <p class="text-slate-400 text-sm font-semibold mb-1 uppercase tracking-wider">Jobs (MTD)</p>
          <div class="flex items-end gap-2">
            <p class="text-3xl font-black text-white">42</p>
            <p class="text-red-400 text-sm font-bold mb-1">-2%</p>
          </div>
          <p class="text-slate-500 text-xs mt-3">Target: 45 jobs/mo</p>
        </div>

        <div class="glass-card rounded-2xl p-6 relative overflow-hidden group border-[#00c291]/20 bg-[#00c291]/5">
          <div class="absolute top-0 right-0 w-24 h-24 bg-[#00c291]/10 rounded-bl-full transition-all group-hover:scale-110">
          </div>
          <p class="text-[#00c291] text-sm font-bold mb-1 uppercase tracking-wider">Current Status</p>
          <div class="flex items-center gap-2">
            <span class="w-3 h-3 bg-[#00c291] rounded-full pulse-ring"></span>
            <p class="text-2xl font-black text-white tracking-tight">
              {status_title(@technician.status)}
            </p>
          </div>
          <p class="text-[#00c291]/70 text-xs mt-3 flex items-center gap-1 font-semibold">
            <.icon name="hero-map-pin" class="size-3.5" /> Tracking via GPS-TX4
          </p>
        </div>
      </section>

      <%!-- Data Visualizations Section --%>
      <section class="px-8 py-4 grid grid-cols-1 lg:grid-cols-3 gap-6">
        <%!-- Productivity Gauge --%>
        <div class="glass-card rounded-3xl p-8 flex flex-col items-center">
          <h3 class="w-full text-slate-200 text-base font-bold mb-6 flex items-center justify-between">
            Productivity Index <.icon name="hero-information-circle" class="size-5 text-slate-500" />
          </h3>

          <div class="relative flex items-center justify-center w-full min-h-[220px]">
            <svg class="w-48 h-48 -rotate-90" aria-hidden="true">
              <circle
                class="text-slate-800"
                cx="96"
                cy="96"
                fill="transparent"
                r="80"
                stroke="currentColor"
                stroke-width="12"
              />
              <circle
                class="text-[#4F46E5]"
                cx="96"
                cy="96"
                fill="transparent"
                r="80"
                stroke="currentColor"
                stroke-dasharray="502.4"
                stroke-dashoffset={circle_offset(@productivity)}
                stroke-width="12"
              />
            </svg>

            <div class="absolute inset-0 flex flex-col items-center justify-center pt-2">
              <span class="text-5xl font-black text-white">{@productivity}%</span>
              <span class="text-slate-500 text-sm font-bold tracking-widest uppercase">
                Efficiency
              </span>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-8 w-full mt-6">
            <div class="text-center">
              <p class="text-slate-500 text-xs font-bold uppercase mb-1">Weekly Goal</p>
              <p class="text-white text-lg font-bold">{@weekly_goal}%</p>
            </div>
            <div class="text-center">
              <p class="text-slate-500 text-xs font-bold uppercase mb-1">Peak Perf</p>
              <p class="text-white text-lg font-bold">{@peak_perf}%</p>
            </div>
          </div>
        </div>

        <%!-- Live GPS Tracking Map --%>
        <div class="glass-card rounded-3xl overflow-hidden flex flex-col lg:col-span-2">
          <div class="p-6 flex items-center justify-between border-b border-slate-800">
            <div>
              <h3 class="text-white text-base font-bold">Real-time Location</h3>
              <p class="text-slate-500 text-sm font-medium">
                Last ping: {location_ping(@technician)} • {location_coords(@technician)}
              </p>
            </div>
            <button
              class="bg-slate-800 p-2 rounded-lg text-slate-400 hover:text-white transition-colors"
              type="button"
            >
              <.icon name="hero-arrows-pointing-out" class="size-5" />
            </button>
          </div>

          <div
            class="flex-1 min-h-[300px] bg-slate-900 relative bg-cover bg-center"
            style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuB_Law0QhqL905v6l8DoqZZy1xxfuS-XSoTz_kF_RNBIp-jsLiz_q8Ico9sREnjqazgD2fegI0Z29Na4f4K0ZlC3LoJsc2lL9tnC_CRF1P5-hi5yPXJ4a-ybN7WU4ptEQ_PJDI2zk5kfglntDzaGIByCvJHsR0B6YmnVysyrHfmZ88_GMANqINIOtejE52sPzn71r_TJgJfiW-oiGJl88KXevFawzcxXS-GMYN4w9Qc4Q9qZwFbVOeSd-e-TYlkLNJnGgq1Q7Obhe0')"
          >
            <div class="absolute inset-0 bg-slate-950/20 backdrop-brightness-75"></div>

            <%!-- UI Overlay on Map --%>
            <div class="absolute top-4 left-4 bg-slate-950/80 backdrop-blur-md px-4 py-2 rounded-xl border border-slate-700">
              <div class="flex items-center gap-3">
                <div class="w-2 h-2 rounded-full bg-[#00c291] animate-ping"></div>
                <span class="text-xs font-bold text-white">En route to: 450 Post St.</span>
              </div>
            </div>

            <%!-- Marker --%>
            <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2">
              <div class="w-10 h-10 rounded-full bg-[#00c291]/20 flex items-center justify-center border-2 border-[#00c291] pulse-ring">
                <.icon name="hero-clock" class="size-5 text-white" />
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Earnings and Skills Section --%>
      <section class="px-8 py-4 grid grid-cols-1 lg:grid-cols-2 gap-6 pb-24">
        <div class="glass-card rounded-3xl p-8">
          <div class="flex items-center justify-between mb-8">
            <div>
              <h3 class="text-white text-base font-bold">Efficiency Earnings</h3>
              <p class="text-slate-500 text-sm">Commission &amp; Performance bonuses</p>
            </div>
            <div class="text-right">
              <p class="text-2xl font-black text-white">+$1,240.00</p>
              <p class="text-[#00c291] text-xs font-bold uppercase tracking-wider">This Period</p>
            </div>
          </div>

          <div class="h-[150px] w-full flex items-end gap-1.5 px-2">
            <%= for day <- @earnings_data do %>
              <div
                class={[
                  "flex-1 rounded-t-lg transition-all group relative",
                  day.active && "bg-[#00c291]/30 hover:bg-[#00c291]/50",
                  not day.active && "bg-slate-800/50 hover:bg-[#00c291]/40"
                ]}
                style={"height: #{day.value}%;"}
              >
                <div class="absolute -top-6 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 text-[10px] text-white font-bold transition-all">
                  {day.label}
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <div class="glass-card rounded-3xl p-8 flex flex-col">
          <h3 class="text-white text-base font-bold mb-6">Certifications &amp; Skills</h3>

          <div class="flex flex-wrap gap-2">
            <%= for {item, index} <- Enum.with_index((@technician.certifications || []) ++ (@technician.skills || [])) do %>
              <span class={[
                "px-4 py-2 rounded-xl border text-xs font-bold",
                index == 3 && "bg-[#4F46E5]/10 border-[#4F46E5]/30 text-[#4F46E5]",
                index != 3 && "bg-slate-800 border-slate-700 text-slate-300"
              ]}>
                {item}
              </span>
            <% end %>

            <%= if (@technician.certifications || []) == [] and (@technician.skills || []) == [] do %>
              <span class="px-4 py-2 rounded-xl bg-slate-800 border border-slate-700 text-xs font-bold text-slate-300">
                No skills added yet
              </span>
            <% end %>
          </div>

          <div class="mt-auto pt-8 flex items-center justify-between border-t border-slate-800">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-lg bg-slate-800 flex items-center justify-center">
                <.icon name="hero-shield-check" class="size-6 text-[#00c291]" />
              </div>
              <div>
                <p class="text-white text-sm font-bold">Identity Verified</p>
                <p class="text-slate-500 text-xs">Last re-check Dec 12, 2023</p>
              </div>
            </div>
            <button class="text-[#00c291] text-sm font-bold hover:underline" type="button">
              View Docs
            </button>
          </div>
        </div>
      </section>

      <%!-- Floating Action Button --%>
      <button
        class="fixed bottom-8 right-8 w-16 h-16 bg-[#00c291] text-slate-950 rounded-full shadow-[0_8px_30px_rgb(0,194,145,0.4)] hover:scale-110 active:scale-95 transition-all flex items-center justify-center z-50 group"
        type="button"
      >
        <.icon
          name="hero-chat-bubble-left-right"
          class="size-8 text-slate-950 group-hover:rotate-12 transition-transform"
        />
        <div class="absolute -top-1 -right-1 w-5 h-5 bg-red-500 rounded-full border-2 border-slate-950 flex items-center justify-center">
          <span class="text-[10px] text-white font-black">2</span>
        </div>
      </button>

      <%!-- Context specific notification --%>
      <%= if @show_alert do %>
        <div class="fixed bottom-8 left-72 glass-card border-[#00c291]/40 px-6 py-4 rounded-2xl flex items-center gap-4 z-40 animate-bounce-slow">
          <div class="w-10 h-10 rounded-full bg-[#00c291]/20 flex items-center justify-center">
            <.icon name="hero-bell-alert" class="size-6 text-[#00c291]" />
          </div>
          <div>
            <p class="text-white text-sm font-bold">New Efficiency Alert</p>
            <p class="text-slate-400 text-xs">
              {@technician.name} just finished Job #9024 in record time.
            </p>
          </div>
          <button
            class="ml-4 text-slate-500 hover:text-white"
            type="button"
            phx-click="dismiss_alert"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp status_label(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp status_label(_), do: "Unknown"

  defp status_title("available"), do: "Ready Now"
  defp status_title("on_job"), do: "On Job"
  defp status_title("traveling"), do: "Traveling"
  defp status_title("en_route"), do: "En Route"
  defp status_title("on_site"), do: "On Site"
  defp status_title("busy"), do: "Busy"
  defp status_title("break"), do: "On Break"
  defp status_title("off_duty"), do: "Off Duty"
  defp status_title(status), do: status_label(status)

  defp join_month_year(nil), do: "—"
  defp join_month_year(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %Y")

  defp join_month_year(%NaiveDateTime{} = ndt),
    do: Calendar.strftime(NaiveDateTime.to_date(ndt), "%b %Y")

  defp join_month_year(_), do: "—"

  defp circle_offset(percent) when is_number(percent) do
    circumference = 502.4
    circumference - circumference * percent / 100
  end

  defp circle_offset(_), do: 0

  defp location_ping(%{location_updated_at: nil}), do: "—"

  defp location_ping(%{location_updated_at: %DateTime{} = dt}) do
    seconds = DateTime.diff(DateTime.utc_now(), dt, :second)

    cond do
      seconds < 0 -> "—"
      seconds < 60 -> "#{seconds}s ago"
      seconds < 3600 -> "#{div(seconds, 60)}m ago"
      true -> "#{div(seconds, 3600)}h ago"
    end
  end

  defp location_ping(_), do: "—"

  defp location_coords(%{current_lat: lat, current_lng: lng})
       when is_number(lat) and is_number(lng) do
    lat_dir = if lat >= 0, do: "N", else: "S"
    lng_dir = if lng >= 0, do: "E", else: "W"

    "#{Float.round(abs(lat), 4)}° #{lat_dir}, #{Float.round(abs(lng), 4)}° #{lng_dir}"
  end

  defp location_coords(_), do: "Location unavailable"
end
