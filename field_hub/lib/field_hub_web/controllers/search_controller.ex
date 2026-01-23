defmodule FieldHubWeb.SearchController do
  @moduledoc """
  JSON API controller for unified search.
  """
  use FieldHubWeb, :controller

  alias FieldHub.Search

  @doc """
  GET /api/search?q=...

  Returns JSON results from Jobs, Customers, and Invoices.
  """
  def index(conn, %{"q" => query}) do
    org_id = conn.assigns[:current_organization].id
    results = Search.search_all(org_id, query, limit: 5)

    json(conn, %{
      success: true,
      results: results
    })
  end

  def index(conn, _params) do
    json(conn, %{success: false, error: "Missing query parameter 'q'"})
  end
end
