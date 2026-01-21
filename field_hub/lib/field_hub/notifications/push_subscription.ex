defmodule FieldHub.Notifications.PushSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "push_subscriptions" do
    field :endpoint, :string
    field :keys, :map
    field :user_agent, :string

    belongs_to :user, FieldHub.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(push_subscription, attrs) do
    push_subscription
    |> cast(attrs, [:endpoint, :keys, :user_agent, :user_id])
    |> validate_required([:endpoint, :keys, :user_id])
    |> unique_constraint(:endpoint)
  end
end
