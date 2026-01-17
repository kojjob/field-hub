defmodule FieldHub.Repo do
  use Ecto.Repo,
    otp_app: :field_hub,
    adapter: Ecto.Adapters.Postgres
end
