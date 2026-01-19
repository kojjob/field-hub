defmodule FieldHubWeb.PortalSessionController do
  use FieldHubWeb, :controller

  alias FieldHub.CRM

  def create(conn, %{"token" => token}) do
    case CRM.get_customer_by_portal_token(token) do
      nil ->
        conn
        |> put_flash(:error, "The portal link is invalid or it has expired.")
        |> redirect(to: ~p"/")

      customer ->
        conn
        |> configure_session(renew: true)
        |> put_session(:portal_customer_id, customer.id)
        |> redirect(to: ~p"/portal")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:portal_customer_id)
    |> put_flash(:info, "Logged out from portal")
    |> redirect(to: ~p"/")
  end
end
