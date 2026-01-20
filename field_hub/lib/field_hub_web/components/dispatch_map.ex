defmodule FieldHubWeb.Components.DispatchMap do
  @moduledoc """
  Pure LiveView dispatch map component.

  Uses OpenStreetMap iframe embed - no JavaScript hooks required!
  This is a LiveView-native approach that renders server-side.
  """
  use Phoenix.Component

  import FieldHubWeb.CoreComponents

  @doc """
  Renders a dispatch map view showing technicians and jobs.

  ## Examples

      <DispatchMap.render
        technicians={@map_technicians}
        jobs={@map_jobs}
      />
  """
  attr :technicians, :list, default: []
  attr :jobs, :list, default: []
  attr :class, :string, default: ""

  def render(assigns) do
    # Find center point from all markers
    all_coords = extract_all_coordinates(assigns.technicians, assigns.jobs)
    center = calculate_center(all_coords)

    assigns =
      assigns
      |> assign(:all_coords, all_coords)
      |> assign(:center, center)
      |> assign(:has_markers, length(all_coords) > 0)

    ~H"""
    <div class={"relative w-full h-full min-h-[400px] bg-zinc-100 dark:bg-zinc-800 rounded-xl overflow-hidden #{@class}"}>
      <%= if @has_markers do %>
        <!-- OpenStreetMap Embed with markers -->
        <iframe
          class="absolute inset-0 w-full h-full border-0"
          src={build_osm_embed_url(@center, @all_coords)}
          loading="lazy"
          referrerpolicy="no-referrer"
          title="Dispatch Map"
        />
        
    <!-- Map Legend Overlay -->
        <div class="absolute bottom-4 left-4 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-sm rounded-2xl p-4 shadow-xl border border-zinc-200/50 dark:border-zinc-700/50 z-10">
          <h4 class="text-[10px] font-black uppercase tracking-widest text-zinc-400 dark:text-zinc-500 mb-3">
            Map Legend
          </h4>
          <div class="space-y-2">
            <div class="flex items-center gap-2">
              <div class="size-3 rounded-full bg-teal-500"></div>
              <span class="text-xs font-bold text-zinc-700 dark:text-zinc-300">
                Technicians ({length(@technicians)})
              </span>
            </div>
            <div class="flex items-center gap-2">
              <div class="size-3 rounded-sm bg-blue-500"></div>
              <span class="text-xs font-bold text-zinc-700 dark:text-zinc-300">
                Jobs ({length(@jobs)})
              </span>
            </div>
          </div>
        </div>
        
    <!-- Marker List Panel -->
        <div class="absolute top-4 right-4 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-sm rounded-2xl shadow-xl border border-zinc-200/50 dark:border-zinc-700/50 z-10 max-h-[300px] overflow-y-auto w-64">
          <div class="p-4 border-b border-zinc-100 dark:border-zinc-800">
            <h4 class="text-xs font-black text-zinc-900 dark:text-white">
              Active on Map
            </h4>
          </div>
          <div class="p-2 space-y-1">
            <!-- Technicians -->
            <%= for tech <- Enum.filter(@technicians, &has_location?/1) do %>
              <div class="flex items-center gap-3 p-2 rounded-xl hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors">
                <div
                  class="size-8 rounded-full flex items-center justify-center text-white text-[10px] font-black shadow-sm"
                  style={"background-color: #{tech.color || "#14b8a6"}"}
                >
                  {initials(tech.name)}
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-xs font-bold text-zinc-900 dark:text-white truncate">
                    {tech.name}
                  </div>
                  <div class="text-[10px] text-zinc-500 capitalize">
                    {String.replace(to_string(tech.status || "unknown"), "_", " ")}
                  </div>
                </div>
              </div>
            <% end %>
            
    <!-- Jobs -->
            <%= for job <- Enum.filter(@jobs, &has_job_location?/1) do %>
              <div
                class="flex items-center gap-3 p-2 rounded-xl hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors cursor-pointer"
                phx-click="show_job_details"
                phx-value-job_id={job.id}
              >
                <div class="size-8 rounded-lg bg-blue-500/10 flex items-center justify-center">
                  <.icon name="hero-wrench-screwdriver" class="size-4 text-blue-600" />
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-xs font-bold text-zinc-900 dark:text-white truncate">
                    #{job.number}
                  </div>
                  <div class="text-[10px] text-zinc-500 truncate">
                    {job.title}
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <!-- Empty State -->
        <div class="absolute inset-0 flex items-center justify-center">
          <div class="text-center p-8">
            <div class="size-16 mx-auto mb-4 rounded-2xl bg-zinc-200 dark:bg-zinc-700 flex items-center justify-center">
              <.icon name="hero-map" class="size-8 text-zinc-400" />
            </div>
            <h3 class="text-lg font-black text-zinc-700 dark:text-zinc-300 mb-2">
              No Locations Available
            </h3>
            <p class="text-sm text-zinc-500 dark:text-zinc-400 max-w-xs">
              No technicians or jobs have location data for this date.
              Assign jobs with service addresses to see them on the map.
            </p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Extract all coordinates from technicians and jobs
  defp extract_all_coordinates(technicians, jobs) do
    tech_coords =
      technicians
      |> Enum.filter(&has_location?/1)
      |> Enum.map(fn t -> {t.current_lat, t.current_lng, :technician, t} end)

    job_coords =
      jobs
      |> Enum.filter(&has_job_location?/1)
      |> Enum.map(fn j -> {j.service_lat, j.service_lng, :job, j} end)

    tech_coords ++ job_coords
  end

  defp has_location?(tech) do
    is_number(tech.current_lat) and is_number(tech.current_lng)
  end

  defp has_job_location?(job) do
    is_number(job.service_lat) and is_number(job.service_lng)
  end

  # Calculate center point of all coordinates
  # Default: San Francisco
  defp calculate_center([]), do: {37.7749, -122.4194}

  defp calculate_center(coords) do
    {lats, lngs} =
      coords
      |> Enum.reduce({[], []}, fn {lat, lng, _, _}, {lats, lngs} ->
        {[lat | lats], [lng | lngs]}
      end)

    avg_lat = Enum.sum(lats) / length(lats)
    avg_lng = Enum.sum(lngs) / length(lngs)

    {avg_lat, avg_lng}
  end

  # Build OpenStreetMap embed URL
  # Using OpenStreetMap's embed with bounding box
  defp build_osm_embed_url(center, coords) do
    {lat, lng} = center

    # Calculate bounding box for zoom
    {min_lat, max_lat, min_lng, max_lng} = calculate_bounds(coords, center)

    # Use OpenStreetMap embed URL
    # Format: https://www.openstreetmap.org/export/embed.html?bbox=...&layer=mapnik&marker=...
    bbox = "#{min_lng},#{min_lat},#{max_lng},#{max_lat}"

    "https://www.openstreetmap.org/export/embed.html?bbox=#{bbox}&layer=mapnik&marker=#{lat},#{lng}"
  end

  defp calculate_bounds([], center) do
    {lat, lng} = center
    # Default bounds around center
    {lat - 0.05, lat + 0.05, lng - 0.05, lng + 0.05}
  end

  defp calculate_bounds(coords, _center) do
    lats = Enum.map(coords, fn {lat, _, _, _} -> lat end)
    lngs = Enum.map(coords, fn {_, lng, _, _} -> lng end)

    min_lat = Enum.min(lats) - 0.01
    max_lat = Enum.max(lats) + 0.01
    min_lng = Enum.min(lngs) - 0.01
    max_lng = Enum.max(lngs) + 0.01

    {min_lat, max_lat, min_lng, max_lng}
  end

  defp initials(nil), do: "?"

  defp initials(name) do
    name
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.at(&1, 0))
    |> Enum.join("")
    |> String.upcase()
  end
end
