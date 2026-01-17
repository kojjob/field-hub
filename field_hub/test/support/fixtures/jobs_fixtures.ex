defmodule FieldHub.JobsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FieldHub.Jobs` context.
  """

  @doc """
  Generate a job.
  """
  def job_fixture(org_id, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        title: "Test Job #{System.unique_integer([:positive])}",
        description: "Standard service call",
        job_type: "service_call",
        priority: "normal",
        status: "unscheduled"
      })

    {:ok, job} = FieldHub.Jobs.create_job(org_id, attrs)

    job
  end
end
