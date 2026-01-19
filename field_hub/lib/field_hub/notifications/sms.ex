defmodule FieldHub.Notifications.SMS do
  @moduledoc """
  SMS notification service using Twilio.

  Sends SMS notifications to customers and technicians for key job events.

  ## Configuration

  Set these environment variables in production:

      TWILIO_ACCOUNT_SID=ACxxxxx
      TWILIO_AUTH_TOKEN=xxxxx
      TWILIO_PHONE_NUMBER=+1234567890

  ## Usage

      # Send a custom message
      SMS.send_sms("+1234567890", "Your technician is on the way!")

      # Use pre-built templates
      SMS.notify_technician_en_route(job)
      SMS.notify_technician_arrived(job)
      SMS.notify_job_completed(job)
  """

  require Logger

  @twilio_api_url "https://api.twilio.com/2010-04-01/Accounts"

  @doc """
  Sends an SMS message to the specified phone number.

  Returns {:ok, message_sid} on success, {:error, reason} on failure.
  """
  @spec send_sms(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def send_sms(to, body) when is_binary(to) and is_binary(body) do
    if enabled?() do
      do_send_sms(normalize_phone(to), body)
    else
      Logger.info("[SMS] SMS disabled - would send to #{to}: #{body}")
      {:ok, "dev_mode_#{System.unique_integer([:positive])}"}
    end
  end

  @doc """
  Notifies customer that technician is on the way.
  """
  def notify_technician_en_route(%{customer: %{phone: phone, name: name}} = job)
      when is_binary(phone) do
    tech_name = get_technician_name(job)

    message = """
    Hi #{first_name(name)}! 🚗

    Your technician #{tech_name} is now on the way for your appointment.

    Job: #{job.title}
    ETA: ~#{estimated_arrival_minutes(job)} minutes

    Reply STOP to unsubscribe.
    """

    send_sms(phone, String.trim(message))
  end

  def notify_technician_en_route(_job), do: {:error, :no_phone}

  @doc """
  Notifies customer that technician has arrived.
  """
  def notify_technician_arrived(%{customer: %{phone: phone, name: name}} = job)
      when is_binary(phone) do
    tech_name = get_technician_name(job)

    message = """
    Hi #{first_name(name)}! 👋

    Good news! #{tech_name} has arrived for your appointment.

    Job: #{job.title}

    Thank you for choosing us!
    """

    send_sms(phone, String.trim(message))
  end

  def notify_technician_arrived(_job), do: {:error, :no_phone}

  @doc """
  Notifies customer that job is complete.
  """
  def notify_job_completed(%{customer: %{phone: phone, name: name}} = job)
      when is_binary(phone) do
    message = """
    Hi #{first_name(name)}! ✅

    Great news! Your service has been completed.

    Job: #{job.title}
    #{if job.actual_amount, do: "Total: $#{job.actual_amount}", else: ""}

    Thank you for your business! We'd love your feedback.

    Reply STOP to unsubscribe.
    """

    send_sms(phone, String.trim(message))
  end

  def notify_job_completed(_job), do: {:error, :no_phone}

  @doc """
  Notifies customer of a scheduled appointment.
  """
  def notify_job_scheduled(%{customer: %{phone: phone, name: name}} = job)
      when is_binary(phone) do
    date = format_date(job.scheduled_date)
    time = format_time(job.scheduled_start)

    message = """
    Hi #{first_name(name)}! 📅

    Your appointment has been scheduled:

    #{job.title}
    📆 #{date}
    🕐 #{time}

    We'll notify you when your technician is on the way.

    Reply STOP to unsubscribe.
    """

    send_sms(phone, String.trim(message))
  end

  def notify_job_scheduled(_job), do: {:error, :no_phone}

  @doc """
  Notifies technician of a new job assignment.
  """
  def notify_technician_new_job(%{technician: %{phone: phone, name: name}} = job)
      when is_binary(phone) do
    customer_name = get_customer_name(job)
    date = format_date(job.scheduled_date)
    time = format_time(job.scheduled_start)

    message = """
    Hi #{first_name(name)}! 🔔

    New job assigned:

    #{job.title}
    Customer: #{customer_name}
    📆 #{date} at #{time}
    📍 #{job.service_address}

    Open FieldHub app for details.
    """

    send_sms(phone, String.trim(message))
  end

  def notify_technician_new_job(_job), do: {:error, :no_phone}

  # Private functions

  defp do_send_sms(to, body) do
    account_sid = get_config(:account_sid)
    auth_token = get_config(:auth_token)
    from_number = get_config(:phone_number)

    url = "#{@twilio_api_url}/#{account_sid}/Messages.json"

    form_data = [
      {"To", to},
      {"From", from_number},
      {"Body", body}
    ]

    headers = [
      {"Authorization", "Basic " <> Base.encode64("#{account_sid}:#{auth_token}")},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    body_encoded = URI.encode_query(form_data)

    case http_post(url, body_encoded, headers) do
      {:ok, %{"sid" => sid}} ->
        Logger.info("[SMS] Message sent successfully: #{sid}")
        {:ok, sid}

      {:ok, %{"message" => error_message, "code" => code}} ->
        Logger.error("[SMS] Twilio error #{code}: #{error_message}")
        {:error, {:twilio_error, code, error_message}}

      {:error, reason} ->
        Logger.error("[SMS] Failed to send: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp http_post(url, body, headers) do
    :inets.start()
    :ssl.start()

    headers_charlist = Enum.map(headers, fn {k, v} ->
      {String.to_charlist(k), String.to_charlist(v)}
    end)

    request = {
      String.to_charlist(url),
      headers_charlist,
      ~c"application/x-www-form-urlencoded",
      String.to_charlist(body)
    }

    http_opts = [
      timeout: 30_000,
      connect_timeout: 10_000,
      ssl: [verify: :verify_none]
    ]

    case :httpc.request(:post, request, http_opts, [body_format: :binary]) do
      {:ok, {{_, 200, _}, _, response_body}} ->
        Jason.decode(response_body)

      {:ok, {{_, 201, _}, _, response_body}} ->
        Jason.decode(response_body)

      {:ok, {{_, status, _}, _, response_body}} ->
        case Jason.decode(response_body) do
          {:ok, json} -> {:ok, json}
          _ -> {:error, {:http_error, status}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_phone(phone) do
    # Remove all non-digit characters except leading +
    cleaned = Regex.replace(~r/[^\d+]/, phone, "")

    # Add country code if missing
    case cleaned do
      "+" <> _ -> cleaned
      _ when byte_size(cleaned) == 10 -> "+1" <> cleaned  # US number
      _ -> "+" <> cleaned
    end
  end

  defp enabled? do
    get_config(:account_sid) != nil and
    get_config(:auth_token) != nil and
    get_config(:phone_number) != nil
  end

  defp get_config(key) do
    Application.get_env(:field_hub, __MODULE__, [])[key]
  end

  defp first_name(nil), do: "there"
  defp first_name(name) do
    name |> String.split(" ") |> List.first() || "there"
  end

  defp get_technician_name(%{technician: %{name: name}}) when is_binary(name), do: name
  defp get_technician_name(_), do: "your technician"

  defp get_customer_name(%{customer: %{name: name}}) when is_binary(name), do: name
  defp get_customer_name(_), do: "Customer"

  defp estimated_arrival_minutes(%{travel_started_at: nil}), do: 15
  defp estimated_arrival_minutes(_job), do: 10  # Already traveling

  defp format_date(nil), do: "TBD"
  defp format_date(date), do: Calendar.strftime(date, "%B %d, %Y")

  defp format_time(nil), do: "TBD"
  defp format_time(time), do: Calendar.strftime(time, "%I:%M %p")
end
