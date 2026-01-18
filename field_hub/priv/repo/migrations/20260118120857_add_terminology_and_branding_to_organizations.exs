defmodule FieldHub.Repo.Migrations.AddTerminologyAndBrandingToOrganizations do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      # Terminology configuration for industry-agnostic labels
      add :terminology, :map,
        default: %{
          "worker_label" => "Technician",
          "worker_label_plural" => "Technicians",
          "client_label" => "Customer",
          "client_label_plural" => "Customers",
          "task_label" => "Job",
          "task_label_plural" => "Jobs",
          "dispatch_label" => "Dispatch"
        }

      # White-label branding
      add :brand_name, :string
      add :logo_url, :string
      add :primary_color, :string, default: "#3B82F6"
      add :secondary_color, :string, default: "#1E40AF"
    end
  end
end
