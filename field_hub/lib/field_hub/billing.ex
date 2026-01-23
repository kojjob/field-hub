defmodule FieldHub.Billing do
  @moduledoc """
  The Billing context for managing invoices and payments.
  """
  import Ecto.Query
  alias FieldHub.Repo
  alias FieldHub.Billing.{Invoice, InvoiceLineItem}
  alias FieldHub.Jobs
  alias FieldHub.Inventory

  # ============================================================================
  # Invoice CRUD
  # ============================================================================

  @doc """
  List invoices for an organization.
  """
  def list_invoices(org_id, opts \\ []) do
    Invoice
    |> Invoice.for_organization(org_id)
    |> apply_invoice_filters(opts)
    |> order_by([i], desc: i.inserted_at)
    |> Repo.all()
    |> Repo.preload([:job, :customer])
  end

  defp apply_invoice_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:status, status}, q -> Invoice.with_status(q, status)
      {:customer_id, id}, q -> Invoice.for_customer(q, id)
      {:limit, limit}, q -> from(i in q, limit: ^limit)
      _, q -> q
    end)
  end

  @doc """
  Get an invoice by ID.
  """
  def get_invoice!(org_id, id) do
    Invoice
    |> Invoice.for_organization(org_id)
    |> Repo.get!(id)
    |> Repo.preload([:job, :customer, :line_items])
  end

  @doc """
  Get invoice for a job.
  """
  def get_invoice_for_job(job_id) do
    Invoice
    |> Invoice.for_job(job_id)
    |> Repo.one()
    |> case do
      nil -> nil
      invoice -> Repo.preload(invoice, [:job, :customer, :line_items])
    end
  end

  @doc """
  Generate an invoice from a job.
  """
  def generate_invoice_from_job(job_id, attrs \\ %{}) do
    job =
      Repo.get!(FieldHub.Jobs.Job, job_id)
      |> Repo.preload([:customer, :technician, :organization])

    # Calculate labor from job data
    labor_hours = calculate_labor_hours(job)
    labor_rate = (job.technician && job.technician.hourly_rate) || Decimal.new(75)
    labor_amount = Decimal.mult(labor_hours, labor_rate) |> Decimal.round(2)

    # Calculate parts amount from job parts
    parts_total = Inventory.job_parts_total(job.id)

    # Default tax rate from org settings or 8.25%
    tax_rate = get_org_tax_rate(job.organization) || Decimal.new("8.25")

    invoice_attrs =
      %{
        job_id: job.id,
        customer_id: job.customer_id,
        organization_id: job.organization_id,
        issue_date: Date.utc_today(),
        due_date: Date.add(Date.utc_today(), 30),
        labor_hours: labor_hours,
        labor_rate: labor_rate,
        labor_amount: labor_amount,
        parts_amount: parts_total,
        tax_rate: tax_rate,
        notes: "Invoice for: #{job.title}\n\nThank you for your business!"
      }
      |> Map.merge(attrs)

    %Invoice{}
    |> Invoice.changeset(invoice_attrs)
    |> Repo.insert()
    |> case do
      {:ok, invoice} ->
        # Create line items from job parts
        create_parts_line_items(invoice, job.id)

        # Update job with invoice reference
        Jobs.update_job(job, %{invoice_id: invoice.id, payment_status: "invoiced"})
        {:ok, Repo.preload(invoice, [:job, :customer, :line_items])}

      error ->
        error
    end
  end

  defp create_parts_line_items(invoice, job_id) do
    job_parts = Inventory.list_job_parts(job_id)

    Enum.each(job_parts, fn jp ->
      %InvoiceLineItem{}
      |> InvoiceLineItem.changeset(%{
        invoice_id: invoice.id,
        description: jp.part.name,
        type: "parts",
        quantity: jp.quantity_used,
        unit_price: jp.unit_price_at_time
      })
      |> Repo.insert()
    end)
  end

  defp calculate_labor_hours(job) do
    # Calculate actual duration from started_at and completed_at timestamps
    actual_minutes = calculate_actual_minutes(job.started_at, job.completed_at)

    cond do
      actual_minutes && actual_minutes > 0 ->
        Decimal.div(Decimal.new(actual_minutes), Decimal.new(60))

      job.estimated_duration_minutes ->
        Decimal.div(Decimal.new(job.estimated_duration_minutes), Decimal.new(60))

      true ->
        Decimal.new(1)
    end
  end

  defp calculate_actual_minutes(nil, _), do: nil
  defp calculate_actual_minutes(_, nil), do: nil

  defp calculate_actual_minutes(started_at, completed_at) do
    DateTime.diff(completed_at, started_at, :minute)
  end

  defp get_org_tax_rate(org) do
    settings = org.settings || %{}

    case settings["tax_rate"] do
      nil -> nil
      rate when is_number(rate) -> Decimal.new(to_string(rate))
      rate when is_binary(rate) -> Decimal.new(rate)
      _ -> nil
    end
  end

  @doc """
  Update an invoice.
  """
  def update_invoice(%Invoice{} = invoice, attrs) do
    invoice
    |> Invoice.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete an invoice.
  """
  def delete_invoice(%Invoice{} = invoice) do
    Repo.delete(invoice)
  end

  @doc """
  Mark invoice as sent.
  """
  def send_invoice(%Invoice{} = invoice) do
    update_invoice(invoice, %{status: "sent"})
  end

  @doc """
  Mark invoice as paid.
  """
  def mark_invoice_paid(%Invoice{} = invoice) do
    update_invoice(invoice, %{status: "paid", paid_at: DateTime.utc_now()})
  end

  # ============================================================================
  # Line Items
  # ============================================================================

  @doc """
  Add line item to invoice.
  """
  def add_line_item(invoice_id, attrs) do
    %InvoiceLineItem{invoice_id: invoice_id}
    |> InvoiceLineItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Remove line item from invoice.
  """
  def remove_line_item(line_item_id) do
    Repo.get!(InvoiceLineItem, line_item_id)
    |> Repo.delete()
  end

  # ============================================================================
  # Stats
  # ============================================================================

  @doc """
  Get invoice statistics for an organization.
  """
  def get_invoice_stats(org_id) do
    query = Invoice.for_organization(org_id)

    total_invoiced =
      from(i in query, select: coalesce(sum(i.total_amount), 0))
      |> Repo.one()

    total_paid =
      from(i in query, where: i.status == "paid", select: coalesce(sum(i.total_amount), 0))
      |> Repo.one()

    outstanding =
      from(i in query,
        where: i.status in ["sent", "viewed", "overdue"],
        select: coalesce(sum(i.total_amount), 0)
      )
      |> Repo.one()

    invoice_count =
      from(i in query, select: count(i.id))
      |> Repo.one()

    %{
      total_invoiced: total_invoiced,
      total_paid: total_paid,
      outstanding: outstanding,
      invoice_count: invoice_count
    }
  end

  @doc """
  Get weekly revenue data for the last 7 days.
  Returns a list of {day_name, current_week_amount, previous_week_amount}
  """
  def get_weekly_revenue(org_id) do
    today = Date.utc_today()
    start_of_week = Date.add(today, -6)
    start_of_prev_week = Date.add(start_of_week, -7)

    # Convert dates to DateTime for utc_datetime comparison
    start_of_week_dt = DateTime.new!(start_of_week, ~T[00:00:00], "Etc/UTC")
    end_of_today_dt = DateTime.new!(Date.add(today, 1), ~T[00:00:00], "Etc/UTC")
    start_of_prev_week_dt = DateTime.new!(start_of_prev_week, ~T[00:00:00], "Etc/UTC")

    # Get current week revenue by day
    current_week =
      from(i in Invoice,
        where: i.organization_id == ^org_id,
        where: i.status == "paid",
        where: i.paid_at >= ^start_of_week_dt,
        where: i.paid_at < ^end_of_today_dt,
        group_by: fragment("DATE(?)::date", i.paid_at),
        select: {fragment("DATE(?)::date", i.paid_at), sum(i.total_amount)}
      )
      |> Repo.all()
      |> Map.new()

    # Get previous week revenue by day offset
    prev_week =
      from(i in Invoice,
        where: i.organization_id == ^org_id,
        where: i.status == "paid",
        where: i.paid_at >= ^start_of_prev_week_dt,
        where: i.paid_at < ^start_of_week_dt,
        group_by: fragment("DATE(?)::date", i.paid_at),
        select: {fragment("DATE(?)::date", i.paid_at), sum(i.total_amount)}
      )
      |> Repo.all()
      |> Map.new()

    # Build 7-day array
    for offset <- 0..6 do
      date = Date.add(start_of_week, offset)
      prev_date = Date.add(date, -7)
      day_name = Calendar.strftime(date, "%a") |> String.upcase()

      current = Map.get(current_week, date, Decimal.new(0))
      previous = Map.get(prev_week, prev_date, Decimal.new(0))

      %{
        day: day_name,
        current: current,
        previous: previous
      }
    end
  end

  @doc """
  Get additional dashboard KPIs.
  """
  def get_dashboard_kpis(org_id) do
    now = DateTime.utc_now()
    thirty_days_ago = DateTime.add(now, -30, :day)
    sixty_days_ago = DateTime.add(now, -60, :day)

    # New customers this month
    new_customers_query =
      from(c in FieldHub.CRM.Customer,
        where: c.organization_id == ^org_id,
        where: c.inserted_at >= ^thirty_days_ago
      )

    new_customers = Repo.aggregate(new_customers_query, :count, :id)

    # Average job value (last 30 days)
    avg_job_value =
      from(i in Invoice,
        where: i.organization_id == ^org_id,
        where: i.status == "paid",
        where: i.paid_at >= ^thirty_days_ago,
        select: avg(i.total_amount)
      )
      |> Repo.one()

    # Collection rate
    total_sent =
      from(i in Invoice,
        where: i.organization_id == ^org_id,
        where: i.inserted_at >= ^sixty_days_ago,
        select: coalesce(sum(i.total_amount), 0)
      )
      |> Repo.one()

    total_collected =
      from(i in Invoice,
        where: i.organization_id == ^org_id,
        where: i.inserted_at >= ^sixty_days_ago,
        where: i.status == "paid",
        select: coalesce(sum(i.total_amount), 0)
      )
      |> Repo.one()

    collection_rate =
      if Decimal.gt?(total_sent, 0) do
        Decimal.div(Decimal.mult(total_collected, 100), total_sent)
        |> Decimal.round(1)
      else
        Decimal.new(0)
      end

    %{
      new_customers: new_customers,
      avg_job_value: avg_job_value || Decimal.new(0),
      collection_rate: collection_rate
    }
  end
end
