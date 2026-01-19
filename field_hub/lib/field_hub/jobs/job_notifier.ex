defmodule FieldHub.Jobs.JobNotifier do
  @moduledoc """
  Handles job-related notifications to customers and staff.
  """
  import Swoosh.Email

  use FieldHubWeb, :verified_routes

  alias FieldHub.Mailer

  defp deliver(recipient_email, recipient_name, subject, body) do
    if recipient_email && recipient_email =~ "@" do
      email =
        new()
        |> to({recipient_name || "", recipient_email})
        |> from({"FieldHub", "notifications@fieldhub.ai"})
        |> subject(subject)
        |> text_body(body)

      with {:ok, _metadata} <- Mailer.deliver(email) do
        {:ok, email}
      end
    else
      {:error, :no_recipient}
    end
  end

  @doc """
  Deliver job confirmation to customer.
  """
  def deliver_job_confirmation(job) do
    job = FieldHub.Repo.preload(job, [:customer, :organization])
    customer = job.customer
    url = url(FieldHubWeb.Endpoint, ~p"/portal/login/#{customer.portal_token}")

    deliver(customer.email, customer.name, "Job Confirmation - #{job.organization.name}", """
    Hi #{customer.name},

    Your service request for "#{job.title}" has been confirmed.

    Job Details:
    - Status: #{String.capitalize(job.status)}
    - Type: #{String.capitalize(job.job_type)}
    #{if job.scheduled_date, do: "- Date: #{Calendar.strftime(job.scheduled_date, "%b %d, %Y")}"}

    You can track your job status and see technician details here:
    #{url}

    Thank you for choosing #{job.organization.name}!
    """)
  end

  @doc """
  Deliver technician dispatch notification.
  """
  def deliver_technician_dispatch(job) do
    job = FieldHub.Repo.preload(job, [:customer, :technician, :organization])
    customer = job.customer
    url = url(FieldHubWeb.Endpoint, ~p"/portal/login/#{customer.portal_token}")

    deliver(customer.email, customer.name, "Technician Dispatched - #{job.organization.name}", """
    Hi #{customer.name},

    Good news! Your technician, #{job.technician.name}, is dispatched and on the way for your job "#{job.title}".

    You can see the technician's location and estimated arrival time here:
    #{url}

    Regards,
    The #{job.organization.name} Team
    """)
  end

  @doc """
  Deliver job completion summary.
  """
  def deliver_job_completion(job) do
    job = FieldHub.Repo.preload(job, [:customer, :organization])
    customer = job.customer
    url = url(FieldHubWeb.Endpoint, ~p"/portal/login/#{customer.portal_token}")

    deliver(customer.email, customer.name, "Service Completed - #{job.organization.name}", """
    Hi #{customer.name},

    Your service for "#{job.title}" has been completed.

    Summary of Work:
    #{job.work_performed}

    You can view your full service history here:
    #{url}

    We value your business!
    The #{job.organization.name} Team
    """)
  end
end
