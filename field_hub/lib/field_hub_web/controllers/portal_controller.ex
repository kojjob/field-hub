defmodule FieldHubWeb.PortalController do
  use FieldHubWeb, :controller

  alias FieldHub.Jobs

  def index(conn, _params) do
    customer = conn.assigns.portal_customer

    active_jobs = Jobs.list_active_jobs_for_customer(customer.id)
    completed_jobs = Jobs.list_completed_jobs_for_customer(customer.id, limit: 5)

    render(conn, :index,
      customer: customer,
      active_jobs: active_jobs,
      completed_jobs: completed_jobs
    )
  end
end
