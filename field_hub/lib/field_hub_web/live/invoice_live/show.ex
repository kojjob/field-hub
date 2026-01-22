defmodule FieldHubWeb.InvoiceLive.Show do
  @moduledoc """
  Invoice detail and preview LiveView.
  Displays a professional invoice with adjustments sidebar matching the design system.
  """
  use FieldHubWeb, :live_view

  alias FieldHub.Billing
  alias FieldHub.Jobs
  alias FieldHub.Payments
  alias FieldHub.Repo

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    org = FieldHub.Accounts.get_organization!(user.organization_id)

    {:ok,
     socket
     |> assign(:current_organization, org)
     |> assign(:current_user, user)
     |> assign(:current_nav, :invoices)
     |> assign(:labor_section_open, true)
     |> assign(:parts_section_open, true)
     |> assign(:discounts_section_open, true)
     |> assign(:tax_section_open, true)
     # Modal states
     |> assign(:show_labor_modal, false)
     |> assign(:show_part_modal, false)
     # Form fields
     |> assign(:new_labor_hours, "")
     |> assign(:new_labor_rate, "")
     |> assign(:new_labor_technician, "")
     |> assign(:new_part_description, "")
     |> assign(:new_part_quantity, "1")
     |> assign(:new_part_price, "")}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    invoice = Billing.get_invoice!(socket.assigns.current_organization.id, id)
    job = invoice.job && Repo.preload(invoice.job, [:technician])

    {:noreply,
     socket
     |> assign(:page_title, "Invoice #{invoice.number}")
     |> assign(:invoice, invoice)
     |> assign(:job, job)}
  end

  @impl true
  def handle_event("send_invoice", _params, socket) do
    case Billing.send_invoice(socket.assigns.invoice) do
      {:ok, invoice} ->
        # Send email notification
        send_invoice_email(invoice)

        {:noreply,
         socket
         |> assign(:invoice, invoice)
         |> put_flash(:info, "Invoice sent to #{invoice.customer.email}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to send invoice")}
    end
  end

  def handle_event("mark_paid", _params, socket) do
    case Billing.mark_invoice_paid(socket.assigns.invoice) do
      {:ok, invoice} ->
        # Update job payment status
        if socket.assigns.job do
          Jobs.update_job(socket.assigns.job, %{payment_status: "paid"})
        end

        {:noreply,
         socket
         |> assign(:invoice, invoice)
         |> put_flash(:info, "Invoice marked as paid")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update invoice")}
    end
  end

  def handle_event("download_pdf", _params, socket) do
    # Trigger browser print dialog
    {:noreply, push_event(socket, "print_invoice", %{})}
  end

  def handle_event("request_payment", _params, socket) do
    invoice = socket.assigns.invoice

    # Check if Stripe is configured
    unless Payments.stripe_configured?() do
      {:noreply,
       put_flash(
         socket,
         :error,
         "Payment processing is not configured. Please set up Stripe API keys."
       )}
    else
      # Build success and cancel URLs
      base_url = FieldHubWeb.Endpoint.url()
      success_url = "#{base_url}/invoices/#{invoice.id}?payment=success"
      cancel_url = "#{base_url}/invoices/#{invoice.id}?payment=cancelled"

      case Payments.create_checkout_session(invoice, success_url, cancel_url) do
        {:ok, session} ->
          # Redirect to Stripe Checkout
          {:noreply, redirect(socket, external: session.url)}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Failed to create payment session: #{reason}")}
      end
    end
  end

  def handle_event("toggle_section", %{"section" => section}, socket) do
    key = String.to_existing_atom("#{section}_section_open")
    {:noreply, assign(socket, key, !socket.assigns[key])}
  end

  def handle_event("recalculate_totals", _params, socket) do
    invoice = socket.assigns.invoice
    line_items = invoice.line_items || []

    # Calculate labor amount from labor line items
    labor_amount =
      line_items
      |> Enum.filter(fn li -> li.type == "labor" end)
      |> Enum.reduce(Decimal.new(0), fn li, acc ->
        Decimal.add(acc, li.amount || Decimal.new(0))
      end)

    # Calculate parts amount from parts line items
    parts_amount =
      line_items
      |> Enum.filter(fn li -> li.type == "parts" end)
      |> Enum.reduce(Decimal.new(0), fn li, acc ->
        Decimal.add(acc, li.amount || Decimal.new(0))
      end)

    # Add existing parts_amount that may not be in line_items (legacy data)
    # Keep the greater of calculated or existing if there are no parts line items
    parts_amount =
      if Enum.any?(line_items, fn li -> li.type == "parts" end) do
        parts_amount
      else
        invoice.parts_amount || Decimal.new(0)
      end

    # Keep existing labor_amount if no labor line items (legacy data)
    labor_amount =
      if Enum.any?(line_items, fn li -> li.type == "labor" end) do
        labor_amount
      else
        invoice.labor_amount || Decimal.new(0)
      end

    # Calculate subtotal
    subtotal = Decimal.add(labor_amount, parts_amount)

    # Calculate discount
    discount = invoice.discount_amount || Decimal.new(0)
    after_discount = Decimal.sub(subtotal, discount)

    # Calculate tax
    tax_rate = invoice.tax_rate || Decimal.new("8.25")

    tax_amount =
      Decimal.mult(after_discount, Decimal.div(tax_rate, Decimal.new(100)))
      |> Decimal.round(2)

    # Calculate total
    total_amount = Decimal.add(after_discount, tax_amount) |> Decimal.round(2)

    case Billing.update_invoice(invoice, %{
           labor_amount: labor_amount,
           parts_amount: parts_amount,
           total_amount: total_amount
         }) do
      {:ok, updated_invoice} ->
        # Reload the invoice to get fresh data with associations
        refreshed_invoice =
          Billing.get_invoice!(socket.assigns.current_organization.id, updated_invoice.id)

        {:noreply,
         socket
         |> assign(:invoice, refreshed_invoice)
         |> put_flash(
           :info,
           "Invoice totals recalculated: #{currency_symbol(socket.assigns.current_organization.currency)}#{format_money(total_amount)}"
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to recalculate totals")}
    end
  end

  # Labor Modal Handlers
  def handle_event("add_labor_row", _params, socket) do
    technician_name =
      if socket.assigns.job && socket.assigns.job.technician do
        socket.assigns.job.technician.name
      else
        ""
      end

    {:noreply,
     socket
     |> assign(:show_labor_modal, true)
     |> assign(:new_labor_technician, technician_name)
     |> assign(:new_labor_hours, "")
     |> assign(:new_labor_rate, "")}
  end

  def handle_event("close_labor_modal", _params, socket) do
    {:noreply, assign(socket, :show_labor_modal, false)}
  end

  def handle_event("update_labor_form", params, socket) do
    {:noreply,
     socket
     |> assign(:new_labor_technician, params["technician"] || "")
     |> assign(:new_labor_hours, params["hours"] || "")
     |> assign(:new_labor_rate, params["rate"] || "")}
  end

  def handle_event("save_labor", params, socket) do
    hours = parse_decimal(params["hours"])
    rate = parse_decimal(params["rate"])

    if hours && rate do
      labor_amount = Decimal.mult(hours, rate)
      current_labor = socket.assigns.invoice.labor_amount || Decimal.new(0)
      new_labor_amount = Decimal.add(current_labor, labor_amount)

      case Billing.update_invoice(socket.assigns.invoice, %{
             labor_hours: hours,
             labor_rate: rate,
             labor_amount: new_labor_amount
           }) do
        {:ok, updated_invoice} ->
          {:noreply,
           socket
           |> assign(:invoice, updated_invoice)
           |> assign(:show_labor_modal, false)
           |> put_flash(:info, "Labor added: #{params["hours"]} hours @ $#{params["rate"]}/hr")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to save labor")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please enter valid hours and rate")}
    end
  end

  # Parts Modal Handlers
  def handle_event("add_part", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_part_modal, true)
     |> assign(:new_part_description, "")
     |> assign(:new_part_quantity, "1")
     |> assign(:new_part_price, "")}
  end

  def handle_event("close_part_modal", _params, socket) do
    {:noreply, assign(socket, :show_part_modal, false)}
  end

  def handle_event("update_part_form", params, socket) do
    {:noreply,
     socket
     |> assign(:new_part_description, params["description"] || "")
     |> assign(:new_part_quantity, params["quantity"] || "1")
     |> assign(:new_part_price, params["price"] || "")}
  end

  def handle_event("save_part", params, socket) do
    quantity = parse_decimal(params["quantity"])
    price = parse_decimal(params["price"])
    description = params["description"] || ""

    if quantity && price && description != "" do
      part_amount = Decimal.mult(quantity, price)
      current_parts = socket.assigns.invoice.parts_amount || Decimal.new(0)
      new_parts_amount = Decimal.add(current_parts, part_amount)

      # Create line item
      case Billing.add_line_item(socket.assigns.invoice.id, %{
             description: description,
             type: "parts",
             quantity: quantity,
             unit_price: price,
             amount: part_amount
           }) do
        {:ok, _line_item} ->
          # Update invoice parts total
          {:ok, updated_invoice} =
            Billing.update_invoice(socket.assigns.invoice, %{parts_amount: new_parts_amount})

          {:noreply,
           socket
           |> assign(
             :invoice,
             Billing.get_invoice!(socket.assigns.current_organization.id, updated_invoice.id)
           )
           |> assign(:show_part_modal, false)
           |> put_flash(:info, "Part added: #{description}")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to save part")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please fill in all fields")}
    end
  end

  defp parse_decimal(""), do: nil
  defp parse_decimal(nil), do: nil

  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _} -> decimal
      :error -> nil
    end
  end

  defp send_invoice_email(invoice) do
    FieldHub.Billing.InvoiceNotifier.deliver_invoice(invoice)
    :ok
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-950" id="invoice-page" phx-hook="PrintInvoice">
      <!-- Top Navigation Bar -->
      <header class="sticky top-0 z-40 bg-white dark:bg-zinc-900 border-b border-zinc-200 dark:border-zinc-800 print:hidden">
        <div class="max-w-[1600px] mx-auto px-6 py-3">
          <div class="flex items-center justify-between">
            <!-- Breadcrumb -->
            <nav class="flex items-center gap-2 text-sm">
              <.link navigate={~p"/jobs"} class="text-zinc-500 hover:text-primary transition-colors">
                JOBS
              </.link>
              <span class="text-zinc-400">›</span>
              <%= if @job do %>
                <.link
                  navigate={~p"/jobs/#{@job.number}"}
                  class="text-zinc-500 hover:text-primary transition-colors"
                >
                  #JOB-{@job.number}
                </.link>
                <span class="text-zinc-400">›</span>
              <% end %>
              <span class="text-zinc-900 dark:text-white font-semibold">GENERATE INVOICE</span>
            </nav>
            
    <!-- Action Buttons -->
            <div class="flex items-center gap-3">
              <button
                phx-click="download_pdf"
                class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-white dark:bg-zinc-800 border border-zinc-300 dark:border-zinc-700 text-zinc-700 dark:text-zinc-200 text-sm font-medium hover:bg-zinc-50 dark:hover:bg-zinc-700 transition-all"
              >
                <.icon name="hero-document" class="size-4" /> Preview PDF
              </button>

              <%= if @invoice.status == "draft" do %>
                <button
                  phx-click="send_invoice"
                  class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-amber-500 text-white text-sm font-semibold hover:bg-amber-600 transition-all"
                >
                  <.icon name="hero-paper-airplane" class="size-4" /> Email to Customer
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </header>
      
    <!-- Page Header -->
      <div class="max-w-[1600px] mx-auto px-6 py-6 print:hidden">
        <div class="flex items-center justify-between">
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-white">
            Invoice: #JOB-{@invoice.number |> String.replace("INV-", "")}
          </h1>

          <button
            phx-click="request_payment"
            class="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-zinc-900 dark:bg-white text-white dark:text-zinc-900 text-sm font-semibold hover:opacity-90 transition-all"
          >
            <.icon name="hero-credit-card" class="size-4" /> Request Online Payment
          </button>
        </div>
      </div>
      
    <!-- Main Content - Two Column Layout -->
      <div class="max-w-[1600px] mx-auto px-6 pb-12">
        <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
          <!-- Left Column: Invoice Preview -->
          <div class="xl:col-span-2 print:col-span-3">
            <div class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden print:rounded-none print:border-0 print:shadow-none">
              <!-- Invoice Header -->
              <div class="p-8 sm:p-10">
                <div class="flex flex-col sm:flex-row sm:items-start justify-between gap-8">
                  <!-- Company Branding -->
                  <div class="flex items-start gap-4">
                    <div class="size-14 rounded-xl bg-zinc-800 dark:bg-zinc-700 flex items-center justify-center flex-shrink-0">
                      <.icon name="hero-building-office-2" class="size-7 text-white" />
                    </div>
                    <div>
                      <h2 class="text-lg font-bold text-zinc-900 dark:text-white tracking-tight uppercase">
                        {@current_organization.name}
                      </h2>
                      <div class="mt-2 text-sm text-zinc-500 dark:text-zinc-400 space-y-0.5">
                        <%= if @current_organization.address_line1 do %>
                          <p>{@current_organization.address_line1}</p>
                        <% end %>
                        <p>
                          {@current_organization.city || "City"}, {@current_organization.state ||
                            "ST"} {@current_organization.zip || "00000"}
                        </p>
                        <p>
                          {@current_organization.email || "contact@example.com"} | {@current_organization.phone ||
                            "(555) 000-0000"}
                        </p>
                      </div>
                    </div>
                  </div>
                  
    <!-- Invoice Info -->
                  <div class="text-right">
                    <h2 class="text-4xl font-black text-zinc-900 dark:text-white tracking-tight">
                      INVOICE
                    </h2>
                    <div class="mt-3 space-y-1 text-sm">
                      <div class="flex justify-end items-center gap-3">
                        <span class="text-zinc-400">Invoice Number:</span>
                        <span class="font-bold text-zinc-900 dark:text-white">
                          {@invoice.number}
                        </span>
                      </div>
                      <div class="flex justify-end items-center gap-3">
                        <span class="text-zinc-400">Issue Date:</span>
                        <span class="font-semibold text-zinc-700 dark:text-zinc-300">
                          {format_date(@invoice.issue_date)}
                        </span>
                      </div>
                      <div class="flex justify-end items-center gap-3">
                        <span class="text-zinc-400">Due Date:</span>
                        <span class="font-semibold text-zinc-700 dark:text-zinc-300">
                          {format_date(@invoice.due_date)}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Bill To / Service Location -->
              <div class="px-8 sm:px-10 pb-8">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-8">
                  <!-- Bill To -->
                  <div>
                    <h4 class="text-xs font-bold text-primary uppercase tracking-wider mb-3">
                      BILL TO
                    </h4>
                    <div>
                      <p class="text-base font-bold text-zinc-900 dark:text-white">
                        {@invoice.customer.name}
                      </p>
                      <%= if @invoice.customer.address_line1 do %>
                        <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                          {@invoice.customer.address_line1}
                          <%= if @invoice.customer.address_line2 do %>
                            <br />{@invoice.customer.address_line2}
                          <% end %>
                        </p>
                        <p class="text-sm text-zinc-500 dark:text-zinc-400">
                          {@invoice.customer.city}, {@invoice.customer.state} {@invoice.customer.zip}
                        </p>
                      <% end %>
                      <%= if @invoice.customer.email do %>
                        <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                          {@invoice.customer.email}
                        </p>
                      <% end %>
                    </div>
                  </div>
                  
    <!-- Service Location -->
                  <%= if @job do %>
                    <div>
                      <h4 class="text-xs font-bold text-primary uppercase tracking-wider mb-3">
                        SERVICE LOCATION
                      </h4>
                      <div>
                        <p class="text-base font-bold text-zinc-900 dark:text-white">
                          {@job.title}
                        </p>
                        <%= if @job.service_address do %>
                          <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                            {@job.service_address}
                          </p>
                          <p class="text-sm text-zinc-500 dark:text-zinc-400">
                            {@job.service_city}, {@job.service_state} {@job.service_zip}
                          </p>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
              
    <!-- Line Items Table -->
              <div class="border-t border-zinc-100 dark:border-zinc-800">
                <table class="w-full">
                  <thead class="bg-zinc-50 dark:bg-zinc-800/50">
                    <tr>
                      <th class="text-left px-8 sm:px-10 py-4 text-xs font-bold text-zinc-500 uppercase tracking-wider">
                        DESCRIPTION
                      </th>
                      <th class="text-right px-4 py-4 text-xs font-bold text-zinc-500 uppercase tracking-wider">
                        QTY/HRS
                      </th>
                      <th class="text-right px-4 py-4 text-xs font-bold text-zinc-500 uppercase tracking-wider">
                        RATE
                      </th>
                      <th class="text-right px-8 sm:px-10 py-4 text-xs font-bold text-zinc-500 uppercase tracking-wider">
                        AMOUNT
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
                    <!-- Labor Row -->
                    <%= if Decimal.gt?(@invoice.labor_amount, Decimal.new(0)) do %>
                      <tr>
                        <td class="px-8 sm:px-10 py-5">
                          <p class="font-semibold text-zinc-900 dark:text-white">
                            Technical Labor - {(@job && @job.title) || "Service"}
                          </p>
                          <%= if @job && @job.technician do %>
                            <p class="text-sm text-zinc-400 mt-0.5">
                              Service performed by: {@job.technician.name}
                            </p>
                          <% end %>
                        </td>
                        <td class="px-4 py-5 text-right text-zinc-600 dark:text-zinc-300">
                          {format_decimal(@invoice.labor_hours)}
                        </td>
                        <td class="px-4 py-5 text-right text-zinc-600 dark:text-zinc-300">
                          {currency_symbol(@current_organization.currency)}{format_money(
                            @invoice.labor_rate
                          )}
                        </td>
                        <td class="px-8 sm:px-10 py-5 text-right font-semibold text-zinc-900 dark:text-white">
                          {currency_symbol(@current_organization.currency)}{format_money(
                            @invoice.labor_amount
                          )}
                        </td>
                      </tr>
                    <% end %>
                    
    <!-- Parts & Materials -->
                    <%= if Decimal.gt?(@invoice.parts_amount, Decimal.new(0)) do %>
                      <tr>
                        <td class="px-8 sm:px-10 py-5">
                          <p class="font-semibold text-zinc-900 dark:text-white">
                            Replacement Parts
                          </p>
                          <p class="text-sm text-zinc-400 mt-0.5">
                            Parts and materials
                          </p>
                        </td>
                        <td class="px-4 py-5 text-right text-zinc-600 dark:text-zinc-300">
                          —
                        </td>
                        <td class="px-4 py-5 text-right text-zinc-600 dark:text-zinc-300">
                          {currency_symbol(@current_organization.currency)}{format_money(
                            @invoice.parts_amount
                          )}
                        </td>
                        <td class="px-8 sm:px-10 py-5 text-right font-semibold text-zinc-900 dark:text-white">
                          {currency_symbol(@current_organization.currency)}{format_money(
                            @invoice.parts_amount
                          )}
                        </td>
                      </tr>
                    <% end %>
                    
    <!-- Dynamic Line Items -->
                    <%= for item <- @invoice.line_items || [] do %>
                      <tr>
                        <td class="px-8 sm:px-10 py-5">
                          <p class="font-semibold text-zinc-900 dark:text-white">
                            {item.description}
                          </p>
                          <%= if item.type do %>
                            <p class="text-sm text-zinc-400 mt-0.5 capitalize">
                              {item.type}
                            </p>
                          <% end %>
                        </td>
                        <td class="px-4 py-5 text-right text-zinc-600 dark:text-zinc-300">
                          {format_decimal(item.quantity)}
                        </td>
                        <td class="px-4 py-5 text-right text-zinc-600 dark:text-zinc-300">
                          {currency_symbol(@current_organization.currency)}{format_money(
                            item.unit_price
                          )}
                        </td>
                        <td class="px-8 sm:px-10 py-5 text-right font-semibold text-zinc-900 dark:text-white">
                          {currency_symbol(@current_organization.currency)}{format_money(item.amount)}
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
              
    <!-- Totals Section -->
              <div class="px-8 sm:px-10 py-8 border-t border-zinc-100 dark:border-zinc-800">
                <div class="flex justify-end">
                  <div class="w-full sm:w-72 space-y-2 text-sm">
                    <div class="flex justify-between">
                      <span class="text-zinc-500">Subtotal</span>
                      <span class="font-medium text-zinc-900 dark:text-white">
                        {currency_symbol(@current_organization.currency)}{format_money(
                          subtotal(@invoice)
                        )}
                      </span>
                    </div>

                    <%= if Decimal.gt?(@invoice.discount_amount || Decimal.new(0), Decimal.new(0)) do %>
                      <div class="flex justify-between">
                        <span class="text-primary">Discount (First Time Service)</span>
                        <span class="font-medium text-primary">
                          -{currency_symbol(@current_organization.currency)}{format_money(
                            @invoice.discount_amount
                          )}
                        </span>
                      </div>
                    <% end %>

                    <div class="flex justify-between">
                      <span class="text-zinc-500">
                        Sales Tax ({format_decimal(@invoice.tax_rate)}%)
                      </span>
                      <span class="font-medium text-zinc-900 dark:text-white">
                        {currency_symbol(@current_organization.currency)}{format_money(
                          @invoice.tax_amount
                        )}
                      </span>
                    </div>

                    <div class="pt-4 mt-4 border-t border-zinc-200 dark:border-zinc-700 flex justify-between items-center">
                      <span class="text-base font-bold text-zinc-900 dark:text-white">TOTAL</span>
                      <span class="text-2xl font-black text-primary">
                        {currency_symbol(@current_organization.currency)}{format_money(
                          @invoice.total_amount
                        )}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Terms & Notes -->
              <%= if @invoice.notes || @invoice.terms do %>
                <div class="px-8 sm:px-10 py-6 border-t border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20">
                  <h4 class="text-xs font-bold text-zinc-400 uppercase tracking-wider mb-2">
                    TERMS & NOTES
                  </h4>
                  <p class="text-xs text-zinc-500 dark:text-zinc-400 leading-relaxed">
                    {default_terms()}
                  </p>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Right Column: Adjustments Sidebar -->
          <div class="xl:col-span-1 print:hidden space-y-3">
            <!-- Adjustments Header -->
            <div class="flex items-center gap-2 mb-1">
              <.icon name="hero-adjustments-horizontal" class="size-5 text-violet-600" />
              <h2 class="text-base font-semibold text-zinc-800 dark:text-white">Adjustments</h2>
            </div>
            
    <!-- Labor Hours Section -->
            <div class="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-100 dark:border-zinc-800 shadow-sm overflow-hidden">
              <button
                phx-click="toggle_section"
                phx-value-section="labor"
                class="w-full flex items-center justify-between px-4 py-3 hover:bg-zinc-50/50 dark:hover:bg-zinc-800/50 transition-colors"
              >
                <div class="flex items-center gap-2">
                  <div class="size-7 rounded-lg bg-violet-100 dark:bg-violet-900/30 flex items-center justify-center">
                    <.icon name="hero-clock" class="size-3.5 text-violet-600 dark:text-violet-400" />
                  </div>
                  <span class="font-medium text-zinc-800 dark:text-white text-sm">Labor Hours</span>
                </div>
                <.icon
                  name={if @labor_section_open, do: "hero-chevron-up", else: "hero-chevron-down"}
                  class="size-4 text-zinc-400"
                />
              </button>

              <%= if @labor_section_open do %>
                <div class="px-4 pb-4 border-t border-zinc-100 dark:border-zinc-800">
                  <div class="pt-3 space-y-2">
                    <!-- Column Headers Row -->
                    <div class="flex items-center gap-2">
                      <div class="flex-1">
                        <span class="text-[9px] font-medium text-zinc-400 uppercase tracking-wider">
                          TECHNICIAN
                        </span>
                      </div>
                      <div class="w-16 text-center">
                        <span class="text-[9px] font-medium text-zinc-400 uppercase tracking-wider">
                          HOURS
                        </span>
                      </div>
                      <div class="w-16 text-right">
                        <span class="text-[9px] font-medium text-zinc-400 uppercase tracking-wider">
                          RATE
                        </span>
                      </div>
                    </div>
                    
    <!-- Input Row -->
                    <div class="flex items-center gap-2">
                      <div class="flex-1">
                        <input
                          type="text"
                          value={(@job && @job.technician && @job.technician.name) || "—"}
                          readonly
                          class="w-full px-2.5 py-2 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg text-sm text-zinc-700 dark:text-zinc-300"
                        />
                      </div>
                      <div class="w-16">
                        <input
                          type="text"
                          value={format_decimal(@invoice.labor_hours)}
                          class="w-full px-2 py-2 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg text-sm text-center text-zinc-700 dark:text-zinc-300"
                        />
                      </div>
                      <div class="w-16">
                        <input
                          type="text"
                          value={format_decimal(@invoice.labor_rate)}
                          class="w-full px-2 py-2 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg text-sm text-center text-zinc-700 dark:text-zinc-300"
                        />
                      </div>
                    </div>
                    
    <!-- Add Row Button - Dashed Style -->
                    <button
                      phx-click="add_labor_row"
                      class="mt-2 w-full py-2 text-xs font-medium text-zinc-400 hover:text-violet-600 transition-colors flex items-center justify-center gap-1.5 border border-dashed border-zinc-200 dark:border-zinc-700 rounded-lg hover:border-violet-300 hover:bg-violet-50/50"
                    >
                      <span>+ Add Labor Row</span>
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
            
    <!-- Parts & Materials Section -->
            <div class="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-100 dark:border-zinc-800 shadow-sm overflow-hidden">
              <button
                phx-click="toggle_section"
                phx-value-section="parts"
                class="w-full flex items-center justify-between px-4 py-3 hover:bg-zinc-50/50 dark:hover:bg-zinc-800/50 transition-colors"
              >
                <div class="flex items-center gap-2">
                  <div class="size-7 rounded-lg bg-slate-100 dark:bg-slate-900/30 flex items-center justify-center">
                    <.icon name="hero-cube" class="size-3.5 text-slate-600 dark:text-slate-400" />
                  </div>
                  <span class="font-medium text-zinc-800 dark:text-white text-sm">
                    Parts & Materials
                  </span>
                </div>
                <.icon
                  name={if @parts_section_open, do: "hero-chevron-up", else: "hero-chevron-down"}
                  class="size-4 text-zinc-400"
                />
              </button>

              <%= if @parts_section_open do %>
                <div class="px-4 pb-4 border-t border-zinc-100 dark:border-zinc-800">
                  <div class="pt-3">
                    <!-- List individual parts from line_items -->
                    <%= if length(Enum.filter(@invoice.line_items || [], fn li -> li.type == "parts" end)) > 0 do %>
                      <div class="space-y-2 mb-3">
                        <%= for item <- Enum.filter(@invoice.line_items || [], fn li -> li.type == "parts" end) do %>
                          <div class="flex items-center justify-between py-1.5 px-2 bg-zinc-50 dark:bg-zinc-800/50 rounded-lg">
                            <div class="flex-1 min-w-0">
                              <span class="text-xs text-zinc-600 dark:text-zinc-300 truncate block">
                                {item.description}
                              </span>
                              <span class="text-[10px] text-zinc-400">
                                {format_decimal(item.quantity)} × {currency_symbol(
                                  @current_organization.currency
                                )}{format_money(item.unit_price)}
                              </span>
                            </div>
                            <span class="text-xs font-medium text-zinc-900 dark:text-white ml-2">
                              {currency_symbol(@current_organization.currency)}{format_money(
                                item.amount
                              )}
                            </span>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                    
    <!-- Total Parts -->
                    <%= if Decimal.gt?(@invoice.parts_amount || Decimal.new(0), Decimal.new(0)) do %>
                      <div class="flex items-center justify-between py-2 border-t border-zinc-100 dark:border-zinc-700">
                        <span class="text-sm font-medium text-zinc-600 dark:text-zinc-300">
                          Total Parts
                        </span>
                        <span class="text-sm font-semibold text-zinc-900 dark:text-white">
                          {currency_symbol(@current_organization.currency)}{format_money(
                            @invoice.parts_amount
                          )}
                        </span>
                      </div>
                    <% else %>
                      <div class="flex items-center justify-center py-3 text-sm text-zinc-400 italic">
                        No parts added yet
                      </div>
                    <% end %>
                    <button
                      phx-click="add_part"
                      class="mt-2 w-full py-2 text-xs font-medium text-zinc-400 hover:text-violet-600 transition-colors flex items-center justify-center gap-1.5 border border-dashed border-zinc-200 dark:border-zinc-700 rounded-lg hover:border-violet-300 hover:bg-violet-50/50"
                    >
                      <span>+ Add Part</span>
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
            
    <!-- Discounts & Fees Section -->
            <div class="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-100 dark:border-zinc-800 shadow-sm overflow-hidden">
              <button
                phx-click="toggle_section"
                phx-value-section="discounts"
                class="w-full flex items-center justify-between px-4 py-3 hover:bg-zinc-50/50 dark:hover:bg-zinc-800/50 transition-colors"
              >
                <div class="flex items-center gap-2">
                  <div class="size-7 rounded-lg bg-pink-100 dark:bg-pink-900/30 flex items-center justify-center">
                    <.icon name="hero-tag" class="size-3.5 text-pink-600 dark:text-pink-400" />
                  </div>
                  <span class="font-medium text-zinc-800 dark:text-white text-sm">
                    Discounts & Fees
                  </span>
                </div>
                <.icon
                  name={if @discounts_section_open, do: "hero-chevron-up", else: "hero-chevron-down"}
                  class="size-4 text-zinc-400"
                />
              </button>

              <%= if @discounts_section_open do %>
                <div class="px-4 pb-4 border-t border-zinc-100 dark:border-zinc-800">
                  <div class="pt-3">
                    <!-- Discount Select Row -->
                    <div class="flex items-center gap-2">
                      <select class="flex-1 px-3 py-2 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg text-sm text-zinc-700 dark:text-zinc-300">
                        <option>First Time Customer (-10%)</option>
                        <option>Loyalty Discount (-15%)</option>
                        <option>Referral Discount (-5%)</option>
                        <option>Senior Discount (-10%)</option>
                        <option>Military Discount (-15%)</option>
                      </select>
                      <button class="size-9 flex items-center justify-center text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/20 rounded-lg transition-colors">
                        <.icon name="hero-trash" class="size-4" />
                      </button>
                    </div>
                    
    <!-- Info Box -->
                    <div class="mt-3 px-3 py-2 bg-amber-50/80 dark:bg-amber-900/20 rounded-lg">
                      <p class="text-[10px] text-amber-700 dark:text-amber-400 flex items-start gap-1.5">
                        <.icon name="hero-information-circle" class="size-3 mt-0.5 flex-shrink-0" />
                        <span>Discounts are applied to the subtotal before taxes.</span>
                      </p>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
            
    <!-- Tax Settings Section -->
            <div class="bg-white dark:bg-zinc-900 rounded-xl border border-zinc-100 dark:border-zinc-800 shadow-sm overflow-hidden">
              <button
                phx-click="toggle_section"
                phx-value-section="tax"
                class="w-full flex items-center justify-between px-4 py-3 hover:bg-zinc-50/50 dark:hover:bg-zinc-800/50 transition-colors"
              >
                <div class="flex items-center gap-2">
                  <div class="size-7 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
                    <.icon
                      name="hero-receipt-percent"
                      class="size-3.5 text-emerald-600 dark:text-emerald-400"
                    />
                  </div>
                  <span class="font-medium text-zinc-800 dark:text-white text-sm">Tax Settings</span>
                </div>
                <.icon
                  name={if @tax_section_open, do: "hero-chevron-up", else: "hero-chevron-down"}
                  class="size-4 text-zinc-400"
                />
              </button>

              <%= if @tax_section_open do %>
                <div class="px-4 pb-4 border-t border-zinc-100 dark:border-zinc-800">
                  <div class="pt-3">
                    <label class="text-[9px] font-medium text-zinc-400 uppercase tracking-wider">
                      TAX RATE
                    </label>
                    <div class="mt-1.5 flex items-center gap-2">
                      <input
                        type="text"
                        value={format_decimal(@invoice.tax_rate)}
                        class="flex-1 px-3 py-2 bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg text-sm text-zinc-700 dark:text-zinc-300"
                      />
                      <span class="text-sm font-medium text-zinc-400">%</span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
            
    <!-- Summary Card - Dark Navy Theme -->
            <div
              class="rounded-xl p-4 shadow-lg mt-4"
              style="background: linear-gradient(145deg, #1e1b4b 0%, #0f172a 100%);"
            >
              <div class="space-y-2">
                <!-- Subtotal Row -->
                <div class="flex justify-between items-center">
                  <span class="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">
                    SUBTOTAL
                  </span>
                  <span class="text-sm font-bold text-white">
                    {currency_symbol(@current_organization.currency)}{format_money(subtotal(@invoice))}
                  </span>
                </div>
                
    <!-- Adjustments Row -->
                <%= if Decimal.gt?(@invoice.discount_amount || Decimal.new(0), Decimal.new(0)) do %>
                  <div class="flex justify-between items-center">
                    <span class="text-[10px] font-semibold text-pink-400 uppercase tracking-wider">
                      ADJUSTMENTS
                    </span>
                    <span class="text-sm font-bold text-pink-400">
                      -{currency_symbol(@current_organization.currency)}{format_money(
                        @invoice.discount_amount
                      )}
                    </span>
                  </div>
                <% end %>
                
    <!-- Divider -->
                <div class="border-t border-slate-600/50 my-2"></div>
                
    <!-- Total Section -->
                <div class="flex justify-between items-end">
                  <div>
                    <span class="text-[9px] font-medium text-slate-500 uppercase tracking-wider block">
                      TOTAL INVOICE AMOUNT
                    </span>
                    <p class="text-xl font-black text-white mt-0.5 tracking-tight">
                      {currency_symbol(@current_organization.currency)}{format_money(
                        @invoice.total_amount
                      )}
                    </p>
                  </div>
                  <button
                    phx-click="recalculate_totals"
                    class="size-9 bg-violet-600 hover:bg-violet-500 rounded-lg flex items-center justify-center transition-all shadow-lg"
                    title="Recalculate totals"
                  >
                    <.icon name="hero-arrow-path" class="size-4 text-white" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Add Labor Modal -->
      <%= if @show_labor_modal do %>
        <div
          class="fixed inset-0 z-50 flex items-center justify-center p-4"
          aria-labelledby="modal-title"
          role="dialog"
          aria-modal="true"
        >
          <!-- Background overlay -->
          <div class="fixed inset-0 bg-zinc-900/75 transition-opacity" phx-click="close_labor_modal">
          </div>
          
    <!-- Modal panel -->
          <div class="relative bg-white dark:bg-zinc-900 rounded-2xl shadow-xl w-full max-w-md p-6 z-10">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-zinc-900 dark:text-white">Add Labor</h3>
              <button
                type="button"
                phx-click="close_labor_modal"
                class="text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300"
              >
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </div>

            <form phx-submit="save_labor" phx-change="update_labor_form">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                    Technician
                  </label>
                  <input
                    type="text"
                    name="technician"
                    value={@new_labor_technician}
                    class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white focus:ring-2 focus:ring-violet-500 focus:border-transparent"
                    placeholder="Enter technician name"
                  />
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                      Hours
                    </label>
                    <input
                      type="number"
                      name="hours"
                      step="0.25"
                      min="0"
                      value={@new_labor_hours}
                      class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white focus:ring-2 focus:ring-violet-500 focus:border-transparent"
                      placeholder="0.00"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                      Rate ($/hr)
                    </label>
                    <input
                      type="number"
                      name="rate"
                      step="0.01"
                      min="0"
                      value={@new_labor_rate}
                      class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white focus:ring-2 focus:ring-violet-500 focus:border-transparent"
                      placeholder="0.00"
                    />
                  </div>
                </div>
              </div>

              <div class="mt-6 flex gap-3">
                <button
                  type="button"
                  phx-click="close_labor_modal"
                  class="flex-1 px-4 py-2.5 text-sm font-medium text-zinc-700 dark:text-zinc-300 bg-zinc-100 dark:bg-zinc-800 rounded-lg hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="flex-1 px-4 py-2.5 text-sm font-semibold text-white bg-violet-600 rounded-lg hover:bg-violet-700 transition-colors"
                >
                  Add Labor
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
    <!-- Add Part Modal -->
      <%= if @show_part_modal do %>
        <div
          class="fixed inset-0 z-50 flex items-center justify-center p-4"
          aria-labelledby="modal-title"
          role="dialog"
          aria-modal="true"
        >
          <!-- Background overlay -->
          <div class="fixed inset-0 bg-zinc-900/75 transition-opacity" phx-click="close_part_modal">
          </div>
          
    <!-- Modal panel -->
          <div class="relative bg-white dark:bg-zinc-900 rounded-2xl shadow-xl w-full max-w-md p-6 z-10">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-zinc-900 dark:text-white">Add Part</h3>
              <button
                type="button"
                phx-click="close_part_modal"
                class="text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300"
              >
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </div>

            <form phx-submit="save_part" phx-change="update_part_form">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                    Description
                  </label>
                  <input
                    type="text"
                    name="description"
                    value={@new_part_description}
                    class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white focus:ring-2 focus:ring-violet-500 focus:border-transparent"
                    placeholder="e.g., Air Filter, Capacitor..."
                  />
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                      Quantity
                    </label>
                    <input
                      type="number"
                      name="quantity"
                      step="1"
                      min="1"
                      value={@new_part_quantity}
                      class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white focus:ring-2 focus:ring-violet-500 focus:border-transparent"
                      placeholder="1"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">
                      Unit Price ($)
                    </label>
                    <input
                      type="number"
                      name="price"
                      step="0.01"
                      min="0"
                      value={@new_part_price}
                      class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-700 rounded-lg bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white focus:ring-2 focus:ring-violet-500 focus:border-transparent"
                      placeholder="0.00"
                    />
                  </div>
                </div>
              </div>

              <div class="mt-6 flex gap-3">
                <button
                  type="button"
                  phx-click="close_part_modal"
                  class="flex-1 px-4 py-2.5 text-sm font-medium text-zinc-700 dark:text-zinc-300 bg-zinc-100 dark:bg-zinc-800 rounded-lg hover:bg-zinc-200 dark:hover:bg-zinc-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="flex-1 px-4 py-2.5 text-sm font-semibold text-white bg-violet-600 rounded-lg hover:bg-violet-700 transition-colors"
                >
                  Add Part
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions
  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%b %d, %Y")

  defp format_money(nil), do: "0.00"
  defp format_money(%Decimal{} = amount), do: Decimal.to_string(amount, :normal)

  defp format_money(amount) when is_number(amount),
    do: :erlang.float_to_binary(amount / 1, decimals: 2)

  defp format_money(_), do: "0.00"

  defp format_decimal(nil), do: "—"
  defp format_decimal(%Decimal{} = d), do: Decimal.to_string(d, :normal)
  defp format_decimal(n), do: to_string(n)

  defp subtotal(invoice) do
    labor = invoice.labor_amount || Decimal.new(0)
    parts = invoice.parts_amount || Decimal.new(0)
    materials = invoice.materials_amount || Decimal.new(0)
    Decimal.add(labor, parts) |> Decimal.add(materials)
  end

  defp default_terms do
    "Please pay this invoice within 15 days of issue. A late fee of 1.5% per month may be applied to overdue balances. Work guaranteed for 90 days from the date of service. For any questions regarding this billing, please contact our support desk."
  end

  # Currency symbol mapping based on ISO 4217 currency codes
  defp currency_symbol("USD"), do: "$"
  defp currency_symbol("EUR"), do: "€"
  defp currency_symbol("GBP"), do: "£"
  defp currency_symbol("JPY"), do: "¥"
  defp currency_symbol("CNY"), do: "¥"
  defp currency_symbol("KRW"), do: "₩"
  defp currency_symbol("INR"), do: "₹"
  defp currency_symbol("RUB"), do: "₽"
  defp currency_symbol("BRL"), do: "R$"
  defp currency_symbol("CAD"), do: "C$"
  defp currency_symbol("AUD"), do: "A$"
  defp currency_symbol("CHF"), do: "CHF"
  defp currency_symbol("MXN"), do: "$"
  defp currency_symbol("ZAR"), do: "R"
  defp currency_symbol("NGN"), do: "₦"
  defp currency_symbol("GHS"), do: "₵"
  defp currency_symbol("KES"), do: "KSh"
  defp currency_symbol("AED"), do: "د.إ"
  defp currency_symbol("SAR"), do: "﷼"
  defp currency_symbol("SGD"), do: "S$"
  defp currency_symbol("HKD"), do: "HK$"
  defp currency_symbol("NZD"), do: "NZ$"
  defp currency_symbol("SEK"), do: "kr"
  defp currency_symbol("NOK"), do: "kr"
  defp currency_symbol("DKK"), do: "kr"
  defp currency_symbol("PLN"), do: "zł"
  defp currency_symbol("THB"), do: "฿"
  defp currency_symbol("PHP"), do: "₱"
  defp currency_symbol("IDR"), do: "Rp"
  defp currency_symbol("MYR"), do: "RM"
  defp currency_symbol("VND"), do: "₫"
  defp currency_symbol("TRY"), do: "₺"
  defp currency_symbol("ILS"), do: "₪"
  defp currency_symbol("EGP"), do: "£"
  defp currency_symbol("PKR"), do: "₨"
  defp currency_symbol("BDT"), do: "৳"
  defp currency_symbol("COP"), do: "$"
  defp currency_symbol("ARS"), do: "$"
  defp currency_symbol("CLP"), do: "$"
  defp currency_symbol("PEN"), do: "S/"
  defp currency_symbol(_), do: "$"
end
