defmodule FieldHubWeb.PortalController do
  use FieldHubWeb, :controller

  def index(conn, _params) do
    customer = conn.assigns.portal_customer

    render(conn, :index, customer: customer)
  end
end
