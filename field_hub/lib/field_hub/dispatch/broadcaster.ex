defmodule FieldHub.Dispatch.Broadcaster do
  @moduledoc """
  Handles real-time broadcasting of events to organization and technician topics.
  """

  alias Phoenix.PubSub
  alias FieldHub.Jobs.Job
  alias FieldHub.Dispatch.Technician

  @pubsub FieldHub.PubSub

  def broadcast_job_created(%Job{} = job) do
    broadcast(org_topic(job.organization_id), {:job_created, job})
    {:ok, job}
  end

  def broadcast_job_updated(%Job{} = job) do
    broadcast(org_topic(job.organization_id), {:job_updated, job})

    if job.technician_id do
      broadcast(tech_topic(job.technician_id), {:job_updated, job})
    end

    {:ok, job}
  end

  def broadcast_technician_location(%Technician{} = tech) do
    broadcast(org_topic(tech.organization_id), {:technician_location_updated, tech})
    {:ok, tech}
  end

  def broadcast_technician_created(%Technician{} = tech) do
    broadcast(org_topic(tech.organization_id), {:technician_created, tech})
    {:ok, tech}
  end

  def broadcast_technician_updated(%Technician{} = tech) do
    broadcast(org_topic(tech.organization_id), {:technician_updated, tech})
    {:ok, tech}
  end

  def broadcast_technician_archived(%Technician{} = tech) do
    broadcast(org_topic(tech.organization_id), {:technician_archived, tech})
    {:ok, tech}
  end

  def broadcast_technician_status(%Technician{} = tech) do
    broadcast(org_topic(tech.organization_id), {:technician_status_updated, tech})
    {:ok, tech}
  end

  # Helper functions

  def subscribe_to_org(org_id) do
    PubSub.subscribe(@pubsub, org_topic(org_id))
  end

  def subscribe_to_tech(tech_id) do
    PubSub.subscribe(@pubsub, tech_topic(tech_id))
  end

  defp org_topic(org_id), do: "org:#{org_id}"
  defp tech_topic(tech_id), do: "tech:#{tech_id}"

  defp broadcast(topic, message) do
    PubSub.broadcast(@pubsub, topic, message)
  end
end
