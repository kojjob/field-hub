defmodule FieldHubWeb.FallbackController do
  @moduledoc """
  Fallback controller for handling errors in API controllers.
  """

  use FieldHubWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: FieldHubWeb.ErrorJSON)
    |> render(:error, message: "Not found")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: FieldHubWeb.ErrorJSON)
    |> render(:error, message: "Unauthorized")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: FieldHubWeb.ErrorJSON)
    |> render(:error, message: "Validation failed", errors: errors)
  end

  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: FieldHubWeb.ErrorJSON)
    |> render(:error, message: message)
  end
end
