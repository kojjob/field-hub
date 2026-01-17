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
  def list_customers(org_id) do
    Customer
    |> where([c], c.organization_id == ^org_id)
    |> where([c], is_nil(c.archived_at))
    |> order_by([c], c.name)
    |> Repo.all()
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
  def create_customer(org_id, attrs) do
    %Customer{organization_id: org_id}
    |> Customer.changeset(attrs)
    |> Customer.generate_portal_token()
    |> Repo.insert()
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update_customer(customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update_customer(customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Archives a customer (soft delete).

  ## Examples

      iex> archive_customer(customer)
      {:ok, %Customer{}}

  """
  def archive_customer(%Customer{} = customer) do
    customer
    |> Ecto.Changeset.change(%{archived_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Searches customers by name, email, phone, or address.
  """
  def search_customers(org_id, search_term) do
    search = "%#{search_term}%"

    Customer
    |> where([c], c.organization_id == ^org_id)
    |> where([c], is_nil(c.archived_at))
    |> where([c],
      ilike(c.name, ^search) or
      ilike(c.email, ^search) or
      ilike(c.phone, ^search) or
      ilike(c.address_line1, ^search) or
      ilike(c.city, ^search)
    )
    |> order_by([c], c.name)
    |> Repo.all()
  end
end
