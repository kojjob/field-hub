defmodule FieldHub.Search do
  @moduledoc """
  Unified search context for querying across Jobs, Customers, and Invoices.
  """
  import Ecto.Query
  alias FieldHub.Repo
  alias FieldHub.Jobs.Job
  alias FieldHub.CRM.Customer
  alias FieldHub.Billing.Invoice

  @doc """
  Searches across all entities for an organization.

  Returns a map with categorized results:
  %{jobs: [...], customers: [...], invoices: [...]}

  ## Options
  - `:limit` - Max results per category (default: 5)
  """
  def search_all(org_id, query, opts \\ []) when is_binary(query) do
    limit = Keyword.get(opts, :limit, 5)
    search_term = "%#{String.trim(query)}%"

    if String.length(String.trim(query)) < 2 do
      %{jobs: [], customers: [], invoices: [], total: 0}
    else
      jobs = search_jobs(org_id, search_term, limit)
      customers = search_customers(org_id, search_term, limit)
      invoices = search_invoices(org_id, search_term, limit)

      %{
        jobs: jobs,
        customers: customers,
        invoices: invoices,
        total: length(jobs) + length(customers) + length(invoices)
      }
    end
  end

  defp search_jobs(org_id, search_term, limit) do
    Job
    |> where([j], j.organization_id == ^org_id)
    |> where(
      [j],
      ilike(j.number, ^search_term) or
        ilike(j.title, ^search_term) or
        ilike(j.service_address, ^search_term) or
        ilike(j.service_city, ^search_term)
    )
    |> where([j], j.status not in ["cancelled"])
    |> order_by([j], desc: j.updated_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:customer])
    |> Enum.map(&format_job_result/1)
  end

  defp search_customers(org_id, search_term, limit) do
    Customer
    |> where([c], c.organization_id == ^org_id)
    |> where([c], is_nil(c.archived_at))
    |> where(
      [c],
      ilike(c.name, ^search_term) or
        ilike(c.email, ^search_term) or
        ilike(c.phone, ^search_term) or
        ilike(c.address_line1, ^search_term) or
        ilike(c.city, ^search_term)
    )
    |> order_by([c], c.name)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(&format_customer_result/1)
  end

  defp search_invoices(org_id, search_term, limit) do
    Invoice
    |> where([i], i.organization_id == ^org_id)
    |> where([i], ilike(i.number, ^search_term))
    |> order_by([i], desc: i.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:customer])
    |> Enum.map(&format_invoice_result/1)
  end

  # Format results for consistent frontend display
  defp format_job_result(job) do
    %{
      id: job.id,
      type: :job,
      title: job.title,
      subtitle: job.customer && job.customer.name,
      number: job.number,
      status: job.status,
      url: "/jobs/#{job.number}"
    }
  end

  defp format_customer_result(customer) do
    %{
      id: customer.id,
      type: :customer,
      title: customer.name,
      subtitle: customer.email || customer.phone,
      slug: customer.slug,
      url: "/customers/#{customer.slug}"
    }
  end

  defp format_invoice_result(invoice) do
    %{
      id: invoice.id,
      type: :invoice,
      title: "Invoice #{invoice.number}",
      subtitle: invoice.customer && invoice.customer.name,
      number: invoice.number,
      status: invoice.status,
      total: invoice.total_amount,
      url: "/invoices/#{invoice.id}"
    }
  end
end
