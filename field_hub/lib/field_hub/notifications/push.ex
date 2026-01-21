defmodule FieldHub.Notifications.Push do
  @moduledoc """
  Handles Web Push Notifications.
  """
  import Ecto.Query
  require Logger
  alias FieldHub.Repo
  alias FieldHub.Notifications.PushSubscription

  @doc """
  Registers a new push subscription for a user.
  """
  def subscribe(user_id, subscription_params) do
    endpoint = subscription_params["endpoint"]

    case Repo.get_by(PushSubscription, endpoint: endpoint) do
      nil ->
        %PushSubscription{}
        |> PushSubscription.changeset(Map.put(subscription_params, "user_id", user_id))
        |> Repo.insert()

      %PushSubscription{} = existing ->
        # Update keys or user if needed
        existing
        |> PushSubscription.changeset(Map.put(subscription_params, "user_id", user_id))
        |> Repo.update()
    end
  end

  @doc """
  Sends a push notification to all devices for a given user.
  """
  def send_notification(user_id, title, body, data \\ %{}) do
    subscriptions = Repo.all(from s in PushSubscription, where: s.user_id == ^user_id)

    if Enum.empty?(subscriptions) do
      {:ok, :no_subscriptions}
    else
      payload =
        Jason.encode!(%{
          title: title,
          body: body,
          icon: "/images/icon-192.png",
          data: data
        })

      results =
        Enum.map(subscriptions, fn sub ->
          send_single_notification(sub, payload)
        end)

      {:ok, results}
    end
  end

  defp send_single_notification(subscription, payload) do
    subscription_info = %{
      endpoint: subscription.endpoint,
      keys: %{
        p256dh: subscription.keys["p256dh"],
        auth: subscription.keys["auth"]
      }
    }

    # Use a task to avoid blocking? Or just sync for now.
    # WebPushEncryption.send_notification returns {:ok, response} or {:error, error}
    case WebPushEncryption.send_web_push(payload, subscription_info) do
      {:ok, %{status_code: code}} when code in 200..299 ->
        :ok

      {:ok, %{status_code: code}} when code in [404, 410] ->
        # Subscription is expired/invalid
        Logger.info("[Push] Removing expired subscription for user #{subscription.user_id}")
        Repo.delete(subscription)
        {:error, :expired}

      {:error, reason} ->
        Logger.warning("[Push] Failed to send notification: #{inspect(reason)}")
        {:error, reason}

      other ->
        # Handle tuple response if any
        Logger.debug("[Push] WebPush response: #{inspect(other)}")
        :ok
    end
  end
end
