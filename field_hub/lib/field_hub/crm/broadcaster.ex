defmodule FieldHub.CRM.Broadcaster do
  @moduledoc """
  Handles real-time broadcasting of CRM events to organization topics.
  """

  alias Phoenix.PubSub
  alias FieldHub.CRM.Customer

  @pubsub FieldHub.PubSub

  def broadcast_customer_created(%Customer{} = customer) do
    broadcast(org_topic(customer.organization_id), {:customer_created, customer})
    {:ok, customer}
  end

  def broadcast_customer_updated(%Customer{} = customer) do
    broadcast(org_topic(customer.organization_id), {:customer_updated, customer})
    {:ok, customer}
  end

  def broadcast_customer_archived(%Customer{} = customer) do
    broadcast(org_topic(customer.organization_id), {:customer_archived, customer})
    {:ok, customer}
  end

  # Helper functions

  def subscribe_to_org(org_id) do
    PubSub.subscribe(@pubsub, org_topic(org_id))
  end

  defp org_topic(org_id), do: "org:#{org_id}"

  defp broadcast(topic, message) do
    PubSub.broadcast(@pubsub, topic, message)
  end
end
