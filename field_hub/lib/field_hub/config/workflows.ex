defmodule FieldHub.Config.Workflows do
  @moduledoc """
  Provides configurable job status workflows for organizations.
  Allows organizations to customize their job statuses and transitions.
  """

  alias FieldHub.Accounts.Organization

  @default_statuses [
    %{key: "pending", label: "Pending", color: "#6B7280", order: 1},
    %{key: "scheduled", label: "Scheduled", color: "#3B82F6", order: 2},
    %{key: "en_route", label: "En Route", color: "#8B5CF6", order: 3},
    %{key: "in_progress", label: "In Progress", color: "#F59E0B", order: 4},
    %{key: "completed", label: "Completed", color: "#10B981", order: 5},
    %{key: "cancelled", label: "Cancelled", color: "#EF4444", order: 6}
  ]

  @default_transitions %{
    "pending" => ["scheduled", "cancelled"],
    "scheduled" => ["en_route", "in_progress", "cancelled"],
    "en_route" => ["in_progress", "cancelled"],
    "in_progress" => ["completed", "cancelled"],
    "completed" => [],
    "cancelled" => ["pending"]
  }

  @doc """
  Returns the default job statuses.
  """
  def default_statuses, do: @default_statuses

  @doc """
  Returns the default status transitions.
  """
  def default_transitions, do: @default_transitions

  @doc """
  Gets the status configuration for an organization.
  Returns custom config if set, otherwise returns defaults.
  """
  def get_statuses(%Organization{job_status_config: config}) when is_list(config) and config != [] do
    config
  end
  def get_statuses(_), do: @default_statuses

  @doc """
  Gets a status label by key.
  """
  def get_status_label(org, key) do
    statuses = get_statuses(org)

    case find_status(statuses, key) do
      nil -> key
      status -> Map.get(status, :label) || Map.get(status, "label") || key
    end
  end

  @doc """
  Gets a status color by key.
  """
  def get_status_color(org, key) do
    statuses = get_statuses(org)

    case find_status(statuses, key) do
      nil -> "#6B7280"
      status -> Map.get(status, :color) || Map.get(status, "color") || "#6B7280"
    end
  end

  @doc """
  Returns allowed next statuses from the current status.
  """
  def next_statuses(org, current_status) do
    statuses = get_statuses(org)
    transitions = get_transitions(org)

    allowed_keys = Map.get(transitions, current_status, [])

    Enum.filter(statuses, fn status ->
      key = Map.get(status, :key) || Map.get(status, "key")
      key in allowed_keys
    end)
  end

  @doc """
  Gets the transition rules for an organization.
  """
  def get_transitions(%Organization{} = _org) do
    # For now, use default transitions. Could be customized per org later.
    @default_transitions
  end
  def get_transitions(_), do: @default_transitions

  @doc """
  Returns available industry workflow presets.
  """
  def industry_presets do
    [
      %{
        key: :field_service,
        name: "Field Service",
        description: "HVAC, plumbing, electrical repairs",
        statuses: @default_statuses
      },
      %{
        key: :healthcare,
        name: "Healthcare",
        description: "Home visits, patient care",
        statuses: [
          %{key: "scheduled", label: "Scheduled", color: "#3B82F6", order: 1},
          %{key: "confirmed", label: "Confirmed", color: "#8B5CF6", order: 2},
          %{key: "in_visit", label: "In Visit", color: "#F59E0B", order: 3},
          %{key: "completed", label: "Completed", color: "#10B981", order: 4},
          %{key: "no_show", label: "No Show", color: "#EF4444", order: 5},
          %{key: "cancelled", label: "Cancelled", color: "#6B7280", order: 6}
        ]
      },
      %{
        key: :delivery,
        name: "Delivery",
        description: "Package delivery, logistics",
        statuses: [
          %{key: "pending_pickup", label: "Pending Pickup", color: "#6B7280", order: 1},
          %{key: "picked_up", label: "Picked Up", color: "#3B82F6", order: 2},
          %{key: "in_transit", label: "In Transit", color: "#8B5CF6", order: 3},
          %{key: "out_for_delivery", label: "Out for Delivery", color: "#F59E0B", order: 4},
          %{key: "delivered", label: "Delivered", color: "#10B981", order: 5},
          %{key: "failed", label: "Delivery Failed", color: "#EF4444", order: 6}
        ]
      },
      %{
        key: :inspection,
        name: "Inspection",
        description: "Property inspections, audits",
        statuses: [
          %{key: "requested", label: "Requested", color: "#6B7280", order: 1},
          %{key: "scheduled", label: "Scheduled", color: "#3B82F6", order: 2},
          %{key: "inspecting", label: "Inspecting", color: "#F59E0B", order: 3},
          %{key: "report_pending", label: "Report Pending", color: "#8B5CF6", order: 4},
          %{key: "completed", label: "Completed", color: "#10B981", order: 5},
          %{key: "cancelled", label: "Cancelled", color: "#EF4444", order: 6}
        ]
      }
    ]
  end

  # Private helpers

  defp find_status(statuses, key) do
    Enum.find(statuses, fn status ->
      status_key = Map.get(status, :key) || Map.get(status, "key")
      status_key == key
    end)
  end
end
