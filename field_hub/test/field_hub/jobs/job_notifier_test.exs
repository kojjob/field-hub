defmodule FieldHub.Jobs.JobNotifierTest do
  use FieldHub.DataCase
  import Swoosh.TestAssertions

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.JobsFixtures
  alias FieldHub.Jobs.JobNotifier

  setup do
    org = organization_fixture()
    customer = customer_fixture(org.id, %{email: "customer@example.com", portal_enabled: true})
    job = job_fixture(org.id, %{customer_id: customer.id, title: "Repair Sink"})

    # Clear confirmation email sent by fixture
    receive do
      {:email, _} -> :ok
    after
      0 -> :ok
    end

    {:ok, %{org: org, customer: customer, job: job}}
  end

  test "deliver_job_confirmation sends an email", %{job: job, customer: customer, org: org} do
    JobNotifier.deliver_job_confirmation(job)

    assert_email_sent [
      to: {customer.name, customer.email},
      subject: "Job Confirmation - #{org.name}"
    ]
  end

  test "deliver_technician_dispatch sends an email", %{job: job, customer: customer, org: org} do
    tech = FieldHub.DispatchFixtures.technician_fixture(org.id)
    job = %{job | technician_id: tech.id, technician: tech}

    JobNotifier.deliver_technician_dispatch(job)

    assert_email_sent [
      to: {customer.name, customer.email},
      subject: "Technician Dispatched - #{org.name}"
    ]
  end

  test "deliver_job_completion sends an email", %{job: job, customer: customer, org: org} do
    job = %{job | work_performed: "Fixed the leak and cleaned up."}

    JobNotifier.deliver_job_completion(job)

    assert_email_sent [
      to: {customer.name, customer.email},
      subject: "Service Completed - #{org.name}"
    ]
  end
end
