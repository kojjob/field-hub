defmodule FieldHubWeb.PortalAuth do
  @moduledoc """
  Customer portal authentication.

  Portal sessions are identified by `:portal_customer_id` in the session.
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller

  alias FieldHub.CRM

  @impl Plug
  def init(action), do: action

  @impl Plug
  def call(conn, action) when is_atom(action) do
    apply(__MODULE__, action, [conn, []])
  end

  def fetch_current_portal_customer(conn, _opts) do
    customer_id = get_session(conn, :portal_customer_id)

    customer =
      if is_integer(customer_id) do
        CRM.get_customer_for_portal(customer_id)
      end

    assign(conn, :portal_customer, customer)
  end

  def require_portal_customer(conn, _opts) do
    if conn.assigns[:portal_customer] do
      conn
    else
      conn
      |> put_flash(:error, "Portal session required. Please use your portal link.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
