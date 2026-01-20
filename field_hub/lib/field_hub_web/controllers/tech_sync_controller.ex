defmodule FieldHubWeb.TechSyncController do
  @moduledoc """
  API controller for syncing offline technician job updates.

  When a technician is offline, job status changes are queued in IndexedDB.
  When they come back online, this endpoint processes those queued updates.
  """

  use FieldHubWeb, :controller

  alias FieldHub.Jobs
  alias FieldHub.Dispatch

  action_fallback FieldHubWeb.FallbackController

  @doc """
  Processes a batch of offline updates from the technician mobile app.

  Expected payload:
  ```json
  {
    "action": "start_travel" | "arrive" | "start_work" | "complete",
    "job_id": "uuid",
    "data": {},
    "offline_timestamp": "ISO8601 timestamp"
  }
  ```
  """
  def sync(conn, params) do
    user = conn.assigns[:current_user]

    case user do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})

      user ->
        process_sync(conn, user, params)
    end
  end

  defp process_sync(conn, user, %{"action" => action, "job_id" => job_id} = params) do
    # Get technician for this user
    technician = Dispatch.get_technician_by_user_id(user.id)

    if technician == nil do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Not a technician"})
    else
      # Get the job - verify it belongs to this technician
      case get_and_verify_job(technician, job_id) do
        {:ok, job} ->
          result = execute_action(action, job, Map.get(params, "data", %{}))
          handle_result(conn, result, params)

        {:error, :not_found} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Job not found"})

        {:error, :not_assigned} ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Job not assigned to you"})
      end
    end
  end

  defp process_sync(conn, _user, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required fields: action, job_id"})
  end

  defp get_and_verify_job(technician, job_id) do
    try do
      job = Jobs.get_job!(technician.organization_id, job_id)

      if job.technician_id == technician.id do
        {:ok, FieldHub.Repo.preload(job, [:customer, :technician])}
      else
        {:error, :not_assigned}
      end
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  defp execute_action("start_travel", job, _data) do
    Jobs.start_travel(job)
  end

  defp execute_action("arrive", job, _data) do
    Jobs.arrive_on_site(job)
  end

  defp execute_action("start_work", job, _data) do
    Jobs.start_work(job)
  end

  defp execute_action("complete", job, data) do
    # Convert string keys to atoms for the completion attrs
    attrs = %{
      work_performed: data["work_performed"] || data[:work_performed] || "",
      amount_charged: parse_money(data["amount_charged"] || data[:amount_charged])
    }

    Jobs.complete_job(job, attrs)
  end

  defp execute_action(action, _job, _data) do
    {:error, "Unknown action: #{action}"}
  end

  defp parse_money(nil), do: nil
  defp parse_money(""), do: nil
  defp parse_money(value) when is_binary(value) do
    case Float.parse(value) do
      {amount, _} -> Decimal.from_float(amount)
      :error -> nil
    end
  end
  defp parse_money(value) when is_number(value), do: Decimal.new(value)
  defp parse_money(_), do: nil

  defp handle_result(conn, {:ok, job}, params) do
    conn
    |> put_status(:ok)
    |> json(%{
      success: true,
      job_id: job.id,
      status: job.status,
      synced_action: params["action"],
      offline_timestamp: params["offline_timestamp"]
    })
  end

  defp handle_result(conn, {:error, changeset}, _params) when is_struct(changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Validation failed", details: errors})
  end

  defp handle_result(conn, {:error, reason}, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: to_string(reason)})
  end
end
