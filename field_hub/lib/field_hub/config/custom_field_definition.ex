defmodule FieldHub.Config.CustomFieldDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "custom_field_definitions" do
    field :name, :string
    field :key, :string
    field :type, :string # text, number, date, boolean, select
    field :target, :string # job, customer, technician
    field :required, :boolean, default: false
    field :options, {:array, :string}, default: []

    belongs_to :organization, FieldHub.Accounts.Organization

    timestamps(type: :utc_datetime)
  end

  @types ~w(text number date boolean select)
  @targets ~w(job customer technician)

  def changeset(custom_field, attrs) do
    custom_field
    |> cast(attrs, [:name, :key, :type, :target, :required, :options, :organization_id])
    |> validate_required([:name, :key, :type, :target, :organization_id])
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:target, @targets)
    |> validate_format(:key, ~r/^[a-z0-9_]+$/, message: "must be lowercase alphanumeric with underscores")
    |> unique_constraint([:organization_id, :target, :key])
    |> foreign_key_constraint(:organization_id)
  end
end
