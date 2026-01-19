defmodule FieldHubWeb.ReportController do
  use FieldHubWeb, :controller

  alias FieldHub.Reports

  @range_days 30

  def export(conn, params) do
    current_scope = conn.assigns[:current_scope]

    case current_scope do
      %FieldHub.Accounts.Scope{} ->
        {start_date, end_date} = parse_range(params)
        csv = Reports.completed_jobs_csv(current_scope, {start_date, end_date})

        filename = "reports_#{Date.to_iso8601(start_date)}_to_#{Date.to_iso8601(end_date)}.csv"

        Phoenix.Controller.send_download(conn, {:binary, csv},
          filename: filename,
          content_type: "text/csv"
        )

      _ ->
        conn
        |> put_status(:unauthorized)
        |> text("Unauthorized")
    end
  end

  defp parse_range(%{"start" => start_date, "end" => end_date}) do
    with {:ok, start_date} <- Date.from_iso8601(start_date),
         {:ok, end_date} <- Date.from_iso8601(end_date) do
      {start_date, end_date}
    else
      _ ->
        default_range()
    end
  end

  defp parse_range(_params), do: default_range()

  defp default_range do
    today = Date.utc_today()
    {Date.add(today, -@range_days), today}
  end
end
