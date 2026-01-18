defmodule FieldHub.CRM do
  @moduledoc """
  The CRM context.
  """

  import Ecto.Query, warn: false
  alias FieldHub.Repo

  alias FieldHub.CRM.Customer

  @doc """
  Returns the list of customers for an organization.

  ## Examples

      iex> list_customers(org_id)
      [%Customer{}, ...]

  """
  def list_customers(nil), do: []

  def list_customers(org_id) do
    Customer
    |> where([c], c.organization_id == ^org_id)
    |> where([c], is_nil(c.archived_at))
    |> order_by([c], c.name)
    |> Repo.all()
  end

  def list_customers(org_id, params) do
    page = Map.get(params, :page, 1)
    page_size = Map.get(params, :page_size, 10)
    offset = (page - 1) * page_size

    query =
      Customer
      |> where([c], c.organization_id == ^org_id)
      |> where([c], is_nil(c.archived_at))
      |> order_by([c], c.name)

    total_entries = Repo.aggregate(query, :count, :id)

    entries =
      query
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    %{
      entries: entries,
      page_number: page,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: ceil(total_entries / page_size)
    }
  end

  @doc """
  Gets a single customer scoped to an organization.

  Raises `Ecto.NoResultsError` if the customer does not exist
  or doesn't belong to the organization.

  ## Examples

      iex> get_customer!(org_id, 123)
      %Customer{}

      iex> get_customer!(org_id, 456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(org_id, id) do
    Customer
    |> where([c], c.organization_id == ^org_id)
    |> where([c], c.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a customer.

  Automatically generates a portal token if not present.

  ## Examples

      iex> create_customer(org_id, %{field: value})
      {:ok, %Customer{}}

      iex> create_customer(org_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  alias FieldHub.CRM.Broadcaster

  def create_customer(org_id, attrs) do
    %Customer{organization_id: org_id}
    |> Customer.changeset(attrs)
    |> Customer.generate_portal_token()
    |> Repo.insert()
    |> broadcast_customer_created()
  end

  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
    |> broadcast_customer_updated()
  end

  def archive_customer(%Customer{} = customer) do
    customer
    |> Ecto.Changeset.change(%{archived_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
    |> broadcast_customer_archived()
  end

  defp broadcast_customer_created({:ok, customer}),
    do: Broadcaster.broadcast_customer_created(customer)

  defp broadcast_customer_created(error), do: error

  defp broadcast_customer_updated({:ok, customer}),
    do: Broadcaster.broadcast_customer_updated(customer)

  defp broadcast_customer_updated(error), do: error

  defp broadcast_customer_archived({:ok, customer}),
    do: Broadcaster.broadcast_customer_archived(customer)

  defp broadcast_customer_archived(error), do: error

  @doc """
  Searches customers by name, email, phone, or address.
  """
  def search_customers(nil, _search_term), do: []

  def search_customers(org_id, search_term) do
    search = "%#{search_term}%"

    Customer
    |> where([c], c.organization_id == ^org_id)
    |> where([c], is_nil(c.archived_at))
    |> where(
      [c],
      ilike(c.name, ^search) or
        ilike(c.email, ^search) or
        ilike(c.phone, ^search) or
        ilike(c.address_line1, ^search) or
        ilike(c.city, ^search)
    )
    |> order_by([c], c.name)
    |> Repo.all()
  end

  def search_customers(org_id, search_term, params) do
    search = "%#{search_term}%"
    page = Map.get(params, :page, 1)
    page_size = Map.get(params, :page_size, 10)
    offset = (page - 1) * page_size

    query =
      Customer
      |> where([c], c.organization_id == ^org_id)
      |> where([c], is_nil(c.archived_at))
      |> where(
        [c],
        ilike(c.name, ^search) or
          ilike(c.email, ^search) or
          ilike(c.phone, ^search) or
          ilike(c.address_line1, ^search) or
          ilike(c.city, ^search)
      )
      |> order_by([c], c.name)

    total_entries = Repo.aggregate(query, :count, :id)

    entries =
      query
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    %{
      entries: entries,
      page_number: page,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: ceil(total_entries / page_size)
    }
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end
end
