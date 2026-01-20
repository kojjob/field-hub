defmodule FieldHub.Jobs.JobNotifier do
  @moduledoc """
  Handles job-related notifications to customers and staff.
  """
  import Swoosh.Email

  use FieldHubWeb, :verified_routes

  alias FieldHub.Mailer

  defp deliver(recipient_email, recipient_name, subject, body) do
    if recipient_email && recipient_email =~ "@" do
      from_address = Application.get_env(:field_hub, :mail_from, "notifications@fieldhub.ai")

      email =
        new()
        |> to({recipient_name || "", recipient_email})
        |> from({"FieldHub", from_address})
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

  @doc """
  Deliver status update email to customer.
  """
  def deliver_status_update(job, customer) do
    job = FieldHub.Repo.preload(job, [:technician, :organization])
    url = url(FieldHubWeb.Endpoint, ~p"/portal/login/#{customer.portal_token}")

    status_message = status_to_message(job.status, job.technician)

    deliver(customer.email, customer.name, "Job Status Update - #{job.organization.name}", """
    Hi #{customer.name},

    Here's an update on your service request "#{job.title}":

    Current Status: #{String.upcase(String.replace(job.status, "_", " "))}
    #{status_message}

    #{if job.technician, do: "Technician: #{job.technician.name}", else: ""}
    #{if job.scheduled_date, do: "Scheduled Date: #{Calendar.strftime(job.scheduled_date, "%b %d, %Y")}", else: ""}

    Track your job in real-time:
    #{url}

    Questions? Reply to this email or call us.

    Best regards,
    The #{job.organization.name} Team
    """)
  end

  defp status_to_message("scheduled", _tech),
    do:
      "Your appointment has been scheduled. We'll notify you when your technician is on the way."

  defp status_to_message("dispatched", tech),
    do:
      "#{(tech && tech.name) || "Your technician"} has been assigned and will be heading your way soon."

  defp status_to_message("en_route", tech),
    do: "#{(tech && tech.name) || "Your technician"} is on the way to your location!"

  defp status_to_message("on_site", tech),
    do: "#{(tech && tech.name) || "Your technician"} has arrived at your location."

  defp status_to_message("in_progress", _tech),
    do: "Work is currently in progress on your service request."

  defp status_to_message("completed", _tech),
    do: "Your service has been completed. Thank you for choosing us!"

  defp status_to_message("cancelled", _tech),
    do: "This job has been cancelled. Please contact us if you have questions."

  defp status_to_message(status, _tech),
    do: "Your job status is: #{String.replace(status, "_", " ")}"
end
