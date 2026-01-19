defmodule FieldHubWeb.TechLive.JobComplete do
  use FieldHubWeb, :live_view

  alias FieldHub.Jobs

  @impl true
  def mount(%{"number" => number}, _session, socket) do
    org_id = socket.assigns.current_scope.user.organization_id

    job =
      Jobs.get_job_by_number!(org_id, number) |> FieldHub.Repo.preload([:customer, :technician])

    # Check if job is in a state that can be completed
    if job.status not in ["on_site", "in_progress"] do
      {:ok,
       socket
       |> put_flash(:error, "Job must be started before it can be completed.")
       |> push_navigate(to: ~p"/tech/jobs/#{job}")}
    else
      changeset = Jobs.change_complete_job(job)

      {:ok,
       socket
       |> assign(:job, job)
       |> assign(:technician, job.technician)
       |> assign(:customer, job.customer)
       |> assign_form(changeset)
       |> assign(:signature_data, nil)
       |> allow_upload(:photos,
         accept: ~w(.jpg .jpeg .png),
         max_entries: 5,
         max_file_size: 10_000_000
       )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 pb-24">
      <!-- Header -->
      <div class="bg-white border-b px-4 py-3 sticky top-0 z-10 flex items-center justify-between">
        <button phx-click={JS.navigate(~p"/tech/jobs/#{@job}")} class="p-1 -ml-1 text-gray-400">
          <.icon name="hero-chevron-left" class="w-6 h-6" />
        </button>
        <h1 class="text-lg font-bold">Complete Job</h1>
        <div class="w-8"></div>
      </div>

      <div class="p-4 max-w-lg mx-auto">
        <.form
          for={@form}
          id="job-completion-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <!-- Customer/Job Summary -->
          <div class="bg-blue-50 rounded-xl p-4 border border-blue-100 mb-6">
            <p class="text-xs font-semibold text-blue-600 uppercase tracking-wider mb-1">
              Job #{@job.number}
            </p>
            <h2 class="text-lg font-bold text-gray-900">{@customer.name}</h2>
            <p class="text-sm text-gray-600">{@job.title}</p>
          </div>
          
    <!-- Work Performed -->
          <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
            <h3 class="flex items-center gap-2 font-bold text-gray-900 mb-4">
              <.icon name="hero-clipboard-document-check" class="w-5 h-5 text-blue-500" />
              Work Performed
            </h3>
            <.input
              field={@form[:work_performed]}
              type="textarea"
              placeholder="Describe the work you completed..."
              class="w-full"
              required
              rows="5"
            />
          </div>
          
    <!-- Financials -->
          <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
            <h3 class="flex items-center gap-2 font-bold text-gray-900 mb-4">
              <.icon name="hero-banknotes" class="w-5 h-5 text-green-500" /> Final Amount
            </h3>
            <div class="space-y-4">
              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-500">Quoted Amount:</span>
                <span class="font-medium">
                  {if @job.quoted_amount, do: "$#{@job.quoted_amount}", else: "N/A"}
                </span>
              </div>
              <.input
                field={@form[:actual_amount]}
                type="number"
                step="0.01"
                label="Actual Amount Collected"
                placeholder="0.00"
              />
            </div>
          </div>
          
    <!-- Photos -->
          <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
            <h3 class="flex items-center gap-2 font-bold text-gray-900 mb-4">
              <.icon name="hero-camera" class="w-5 h-5 text-purple-500" /> Job Photos
            </h3>

            <div
              phx-drop-target={@uploads.photos.ref}
              class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-400 transition-colors"
            >
              <.live_file_input upload={@uploads.photos} class="hidden" id="photo-upload-input" />
              <label for="photo-upload-input" class="cursor-pointer">
                <div class="flex flex-col items-center">
                  <.icon name="hero-cloud-arrow-up" class="w-10 h-10 text-gray-400 mb-2" />
                  <p class="text-sm text-gray-600 font-medium">Click to upload or drag and drop</p>
                  <p class="text-xs text-gray-400 mt-1">Up to 5 images (Max 10MB each)</p>
                </div>
              </label>
            </div>

            <div class="mt-4 grid grid-cols-3 gap-2">
              <%= for entry <- @uploads.photos.entries do %>
                <div class="relative aspect-square rounded-lg overflow-hidden bg-gray-100 group">
                  <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="absolute top-1 right-1 p-1 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <.icon name="hero-x-mark" class="w-3 h-3" />
                  </button>
                  <div class="absolute bottom-0 left-0 right-0 h-1 bg-gray-200">
                    <div class="h-full bg-blue-500" style={"width: #{entry.progress}%"}></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Signature -->
          <div class="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
            <h3 class="flex items-center gap-2 font-bold text-gray-900 mb-4">
              <.icon name="hero-pencil-square" class="w-5 h-5 text-orange-500" /> Customer Signature
            </h3>

            <div class="relative bg-gray-50 border rounded-lg overflow-hidden">
              <canvas
                id="signature-pad"
                phx-hook="SignaturePad"
                data-target-id="customer-signature-input"
                class="w-full h-48 touch-none cursor-crosshair"
              >
              </canvas>
              <button
                type="button"
                id="clear-signature"
                class="absolute bottom-2 right-2 px-3 py-1 bg-white shadow-sm border rounded-md text-xs font-medium text-gray-600 active:bg-gray-100"
              >
                Clear
              </button>
            </div>
            <textarea
              name="job[customer_signature]"
              id="customer-signature-input"
              class="hidden"
            ><%= @form[:customer_signature].value %></textarea>
          </div>
          
    <!-- Actions -->
          <div class="fixed bottom-0 left-0 right-0 p-4 bg-white shadow-[0_-4px_10px_rgba(0,0,0,0.05)] flex gap-3">
            <button
              type="button"
              phx-click={JS.navigate(~p"/tech/jobs/#{@job}")}
              class="flex-1 py-4 px-6 rounded-xl font-bold bg-gray-100 text-gray-700 active:bg-gray-200 transition-all"
            >
              Cancel
            </button>
            <button
              type="submit"
              phx-disable-with="Submitting..."
              class="flex-[2] py-4 px-6 rounded-xl font-bold bg-blue-600 text-white shadow-lg shadow-blue-200 active:bg-blue-700 transition-all"
            >
              Complete Job
            </button>
          </div>
        </.form>

        <div id="geolocation-tracking" phx-hook="Geolocation" data-auto-start="true"></div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"job" => params}, socket) do
    changeset =
      socket.assigns.job
      |> Jobs.change_complete_job(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  @impl true
  def handle_event("save", %{"job" => params}, socket) do
    # Handle photos
    photo_urls =
      consume_uploaded_entries(socket, :photos, fn _meta, entry ->
        # In a real app, we would upload to S3 here.
        # For now, we'll simulate by returning a dummy path.
        # Since we don't have a static file server configured for uploads yet,
        # we'll just use the filenames or dummy IDs.
        {:ok, "/uploads/jobs/#{socket.assigns.job.id}/#{entry.client_name}"}
      end)

    # Merge photos into params
    params = Map.put(params, "photos", photo_urls)
    params = Map.put(params, "completed_by_id", socket.assigns.job.technician_id)

    case Jobs.complete_job(socket.assigns.job, params) do
      {:ok, _job} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job completed successfully!")
         |> push_navigate(to: ~p"/tech/dashboard")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("update_location", %{"lat" => lat, "lng" => lng}, socket) do
    if socket.assigns.technician do
      FieldHub.Dispatch.update_technician_location(socket.assigns.technician, lat, lng)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("location_error", params, socket) do
    IO.puts("Location error for technician #{socket.assigns.technician.id}: #{inspect(params)}")
    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
