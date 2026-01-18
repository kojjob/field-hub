defmodule FieldHub.Config.IndustryTemplates do
  @moduledoc """
  Provides industry-specific templates for quick organization setup.
  Each template includes terminology, suggested settings, and branding defaults.
  """

  alias FieldHub.Config.Terminology

  @templates [
    %{
      key: :field_service,
      name: "Field Service",
      description: "HVAC, plumbing, electrical, appliance repair",
      icon: "hero-wrench-screwdriver",
      primary_color: "#3B82F6",
      secondary_color: "#1E40AF"
    },
    %{
      key: :healthcare,
      name: "Home Healthcare",
      description: "Home care, nursing visits, patient services",
      icon: "hero-heart",
      primary_color: "#10B981",
      secondary_color: "#059669"
    },
    %{
      key: :delivery,
      name: "Delivery & Logistics",
      description: "Package delivery, courier services, last-mile",
      icon: "hero-truck",
      primary_color: "#F59E0B",
      secondary_color: "#D97706"
    },
    %{
      key: :inspection,
      name: "Property Inspection",
      description: "Home inspection, property management, compliance",
      icon: "hero-clipboard-document-check",
      primary_color: "#8B5CF6",
      secondary_color: "#7C3AED"
    },
    %{
      key: :cleaning,
      name: "Cleaning Services",
      description: "Commercial cleaning, janitorial, housekeeping",
      icon: "hero-sparkles",
      primary_color: "#06B6D4",
      secondary_color: "#0891B2"
    }
  ]

  @doc """
  Returns list of all available industry templates.
  """
  def templates, do: @templates

  @doc """
  Get a specific template by key.
  """
  def get_template(key) when is_atom(key) do
    Enum.find(@templates, fn t -> t.key == key end)
  end

  def get_template(key) when is_binary(key) do
    get_template(String.to_existing_atom(key))
  rescue
    ArgumentError -> nil
  end

  @doc """
  Returns the configuration to apply for a given template.
  This merges terminology and branding settings.
  """
  def get_config(template_key) do
    template = get_template(template_key)

    if template do
      %{
        terminology: Terminology.preset(template.key),
        primary_color: template.primary_color,
        secondary_color: template.secondary_color
      }
    else
      %{
        terminology: Terminology.defaults(),
        primary_color: "#3B82F6",
        secondary_color: "#1E40AF"
      }
    end
  end

  @doc """
  Apply template configuration to organization attributes.
  Returns merged attrs with template settings.
  """
  def apply_template(attrs, template_key) do
    config = get_config(template_key)

    attrs
    |> Map.put(:terminology, config.terminology)
    |> Map.put(:primary_color, config.primary_color)
    |> Map.put(:secondary_color, config.secondary_color)
  end
end
