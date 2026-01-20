defmodule FieldHubWeb.Plugs.StripeRawBody do
  @moduledoc """
  Plug to capture the raw body for Stripe webhook signature verification.
  Must be used before Plug.Parsers in the pipeline for the webhook endpoint.
  """

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    Plug.Conn.assign(conn, :raw_body, body)
  end
end
