defmodule FieldHub.Config.CustomFields do
  @moduledoc """
  Context for managing custom field definitions.
  """
  import Ecto.Query, warn: false
  alias FieldHub.Repo
  alias FieldHub.Config.CustomFieldDefinition
  alias FieldHub.Accounts.Organization

  def list_definitions(%Organization{id: org_id}) do
    CustomFieldDefinition
    |> where([c], c.organization_id == ^org_id)
    |> order_by([c], asc: :target, asc: :name)
    |> Repo.all()
  end

  def list_definitions(%Organization{id: org_id}, target) do
    CustomFieldDefinition
    |> where([c], c.organization_id == ^org_id and c.target == ^target)
    |> order_by([c], asc: :name)
    |> Repo.all()
  end

  def get_definition!(id), do: Repo.get!(CustomFieldDefinition, id)

  def create_definition(attrs) do
    %CustomFieldDefinition{}
    |> CustomFieldDefinition.changeset(attrs)
    |> Repo.insert()
  end

  def update_definition(%CustomFieldDefinition{} = definition, attrs) do
    definition
    |> CustomFieldDefinition.changeset(attrs)
    |> Repo.update()
  end

  def delete_definition(%CustomFieldDefinition{} = definition) do
    Repo.delete(definition)
  end

  def change_definition(%CustomFieldDefinition{} = definition, attrs \\ %{}) do
    CustomFieldDefinition.changeset(definition, attrs)
  end
end
