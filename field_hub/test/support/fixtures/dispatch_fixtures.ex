defmodule FieldHub.DispatchFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FieldHub.Dispatch` context.
  """

  alias FieldHub.Dispatch

  @doc """
  Generate a technician.
  """
  def technician_fixture(org_id, attrs \\ %{}) do
    {:ok, tech} =
      attrs
      |> Enum.into(%{
        name: "Test Tech #{System.unique_integer([:positive])}",
        email: "tech#{System.unique_integer([:positive])}@example.com",
        phone: "555-#{System.unique_integer([:positive])}",
        skills: ["General"],
        hourly_rate: Decimal.new("50.00"),
        color: "#3B82F6",
        status: "off_duty"
      })
      |> then(&Dispatch.create_technician(org_id, &1))

    tech
  end
end
