defmodule FieldHub.Config.Terminology do
  @moduledoc """
  Provides industry-agnostic terminology lookups for organizations.

  Instead of hard-coding "Technician", "Customer", "Job", etc.,
  this module allows organizations to customize their labels.
  """

  alias FieldHub.Accounts.Organization

  @default_terminology %{
    "worker_label" => "Technician",
    "worker_label_plural" => "Technicians",
    "client_label" => "Customer",
    "client_label_plural" => "Customers",
    "task_label" => "Job",
    "task_label_plural" => "Jobs",
    "dispatch_label" => "Dispatch"
  }

  @doc """
  Returns the full terminology map for an organization, with defaults.
  """
  def get_terminology(%Organization{terminology: nil}), do: @default_terminology
  def get_terminology(%Organization{terminology: terms}) when is_map(terms) do
    Map.merge(@default_terminology, terms)
  end
  def get_terminology(_), do: @default_terminology

  @doc """
  Get a specific terminology value by key.

  ## Examples

      iex> Terminology.get(org, :worker_label)
      "Caregiver"

      iex> Terminology.get(org, :task_label)
      "Visit"
  """
  def get(%Organization{} = org, key) when is_atom(key) do
    get(org, Atom.to_string(key))
  end

  def get(%Organization{} = org, key) when is_binary(key) do
    org
    |> get_terminology()
    |> Map.get(key, @default_terminology[key])
  end

  def get(_, key) when is_atom(key), do: @default_terminology[Atom.to_string(key)]
  def get(_, key) when is_binary(key), do: @default_terminology[key]

  # Convenience functions
  def worker_label(org), do: get(org, "worker_label")
  def worker_label_plural(org), do: get(org, "worker_label_plural")
  def client_label(org), do: get(org, "client_label")
  def client_label_plural(org), do: get(org, "client_label_plural")
  def task_label(org), do: get(org, "task_label")
  def task_label_plural(org), do: get(org, "task_label_plural")
  def dispatch_label(org), do: get(org, "dispatch_label")

  @doc """
  Returns the default terminology map.
  """
  def defaults, do: @default_terminology

  @doc """
  Industry-specific terminology presets.
  """
  def preset(:field_service) do
    @default_terminology
  end

  def preset(:healthcare) do
    %{
      "worker_label" => "Caregiver",
      "worker_label_plural" => "Caregivers",
      "client_label" => "Patient",
      "client_label_plural" => "Patients",
      "task_label" => "Visit",
      "task_label_plural" => "Visits",
      "dispatch_label" => "Schedule"
    }
  end

  def preset(:delivery) do
    %{
      "worker_label" => "Driver",
      "worker_label_plural" => "Drivers",
      "client_label" => "Recipient",
      "client_label_plural" => "Recipients",
      "task_label" => "Delivery",
      "task_label_plural" => "Deliveries",
      "dispatch_label" => "Route"
    }
  end

  def preset(:inspection) do
    %{
      "worker_label" => "Inspector",
      "worker_label_plural" => "Inspectors",
      "client_label" => "Property",
      "client_label_plural" => "Properties",
      "task_label" => "Inspection",
      "task_label_plural" => "Inspections",
      "dispatch_label" => "Assign"
    }
  end

  def preset(:cleaning) do
    %{
      "worker_label" => "Cleaner",
      "worker_label_plural" => "Cleaners",
      "client_label" => "Location",
      "client_label_plural" => "Locations",
      "task_label" => "Cleaning",
      "task_label_plural" => "Cleanings",
      "dispatch_label" => "Schedule"
    }
  end

  def preset(_), do: @default_terminology

  @doc """
  Returns list of available preset keys.
  """
  def available_presets do
    [:field_service, :healthcare, :delivery, :inspection, :cleaning]
  end
end
