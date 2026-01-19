defmodule FieldHub.Reports do
  @moduledoc """
  The Reports context.
  """

  import Ecto.Query, warn: false
  alias FieldHub.Repo
  alias FieldHub.Accounts.Scope
  alias FieldHub.Jobs.Job
  alias FieldHub.Dispatch.Technician

  @doc """
  Returns a map of KPIs for the given organization and date range.
  Range is a tuple {start_date, end_date}.
  """
  def get_kpis(%Scope{} = current_scope, {start_date, end_date}) do
    org_id = organization_id(current_scope)

    if is_nil(org_id) do
      %{total_revenue: Decimal.new(0), completed_jobs_count: 0, avg_job_duration_minutes: 0}
    else
      start_dt = DateTime.new!(start_date, ~T[00:00:00])
      end_dt = DateTime.new!(end_date, ~T[23:59:59])

      base_query =
        from j in Job,
          where: j.organization_id == ^org_id,
          where: j.status == "completed",
          where: j.completed_at >= ^start_dt and j.completed_at <= ^end_dt

      stats =
        Repo.one(
          from j in base_query,
            select: %{
              count: count(j.id),
              revenue: sum(j.actual_amount),
              total_duration_seconds:
                fragment("SUM(EXTRACT(EPOCH FROM (? - ?)))", j.completed_at, j.started_at)
            }
        )

      total_revenue = stats.revenue || Decimal.new(0)
      count = stats.count || 0

      total_duration_seconds =
        stats.total_duration_seconds
        |> duration_seconds()

      avg_job_duration_minutes =
        if count > 0 && total_duration_seconds > 0 do
          round(total_duration_seconds / count / 60)
        else
          0
        end

      %{
        total_revenue: total_revenue,
        completed_jobs_count: count,
        avg_job_duration_minutes: avg_job_duration_minutes
      }
    end
  end

  @doc """
  Returns technician performance stats.
  """
  def get_technician_performance(%Scope{} = current_scope, {start_date, end_date}) do
    org_id = organization_id(current_scope)

    if is_nil(org_id) do
      []
    else
      start_dt = DateTime.new!(start_date, ~T[00:00:00])
      end_dt = DateTime.new!(end_date, ~T[23:59:59])

      from(j in Job,
        join: t in Technician,
        on: j.technician_id == t.id,
        where: j.organization_id == ^org_id,
        where: j.status == "completed",
        where: j.completed_at >= ^start_dt and j.completed_at <= ^end_dt,
        group_by: [t.id, t.name, t.avatar_url],
        select: %{
          technician_id: t.id,
          name: t.name,
          avatar_url: t.avatar_url,
          jobs_completed: count(j.id),
          total_revenue: sum(j.actual_amount)
        },
        order_by: [desc: count(j.id)]
      )
      |> Repo.all()
      |> Enum.map(fn stat ->
        Map.put(stat, :total_revenue, stat.total_revenue || Decimal.new(0))
      end)
    end
  end

  @doc """
  Returns recent completed jobs.
  """
  def get_recent_completed_jobs(%Scope{} = current_scope, limit \\ 10) do
    org_id = organization_id(current_scope)

    if is_nil(org_id) do
      []
    else
      from(j in Job,
        where: j.organization_id == ^org_id,
        where: j.status == "completed",
        order_by: [desc: j.completed_at],
        limit: ^limit,
        preload: [:customer, :technician]
      )
      |> Repo.all()
    end
  end

  @doc """
  Lists completed jobs in the given date range.

  Use `limit:` to cap the result set.
  """
  def list_completed_jobs(%Scope{} = current_scope, {start_date, end_date}, opts \\ []) do
    org_id = organization_id(current_scope)

    if is_nil(org_id) do
      []
    else
      start_dt = DateTime.new!(start_date, ~T[00:00:00])
      end_dt = DateTime.new!(end_date, ~T[23:59:59])
      limit = Keyword.get(opts, :limit)

      base_query =
        from(j in Job,
          where: j.organization_id == ^org_id,
          where: j.status == "completed",
          where: j.completed_at >= ^start_dt and j.completed_at <= ^end_dt,
          order_by: [desc: j.completed_at],
          preload: [:customer, :technician]
        )

      query =
        if is_integer(limit) do
          from(j in base_query, limit: ^limit)
        else
          base_query
        end

      Repo.all(query)
    end
  end

  @doc """
  Exports completed jobs in range as CSV.
  """
  def completed_jobs_csv(%Scope{} = current_scope, range) do
    jobs = list_completed_jobs(current_scope, range)

    header = ["Job Number", "Title", "Customer", "Technician", "Completed At", "Amount"]

    rows =
      jobs
      |> Enum.map(fn job ->
        [
          job.number,
          job.title,
          job.customer && job.customer.name,
          job.technician && job.technician.name,
          job.completed_at,
          job.actual_amount
        ]
      end)

    [header | rows]
    |> Enum.map(&csv_row/1)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  @doc """
  Returns job completion trend (daily/weekly counts).
  For simplicity we'll group by date (day).
  """
  def get_job_completion_trend(%Scope{} = current_scope, {start_date, end_date}) do
    org_id = organization_id(current_scope)

    if is_nil(org_id) do
      Date.range(start_date, end_date)
      |> Enum.map(fn date -> %{date: date, count: 0} end)
    else
      start_dt = DateTime.new!(start_date, ~T[00:00:00])
      end_dt = DateTime.new!(end_date, ~T[23:59:59])

      data =
        from(j in Job,
          where: j.organization_id == ^org_id,
          where: j.status == "completed",
          where: j.completed_at >= ^start_dt and j.completed_at <= ^end_dt,
          group_by: fragment("date_trunc('day', ?)", j.completed_at),
          select: {fragment("date_trunc('day', ?)::date", j.completed_at), count(j.id)}
        )
        |> Repo.all()
        |> Map.new()

      Date.range(start_date, end_date)
      |> Enum.map(fn date ->
        %{
          date: date,
          count: Map.get(data, date, 0)
        }
      end)
    end
  end

  defp organization_id(%Scope{user: %{organization_id: org_id}}) when not is_nil(org_id),
    do: org_id

  defp organization_id(_), do: nil

  defp duration_seconds(nil), do: 0

  defp duration_seconds(%Decimal{} = dec), do: Decimal.to_float(dec)

  defp duration_seconds(value) when is_integer(value) or is_float(value), do: value

  defp csv_row(values) when is_list(values) do
    values
    |> Enum.map(&csv_escape/1)
    |> Enum.join(",")
  end

  defp csv_escape(nil), do: ""

  defp csv_escape(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp csv_escape(%Date{} = date), do: Date.to_iso8601(date)

  defp csv_escape(%Decimal{} = dec), do: dec |> Decimal.round(2) |> Decimal.to_string(:normal)

  defp csv_escape(value) do
    value = to_string(value)

    if String.contains?(value, [",", "\n", "\r", "\""]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end
end
