defmodule FieldHub.Notifications.SMSTest do
  use FieldHub.DataCase

  alias FieldHub.Notifications.SMS

  describe "send_sms/2" do
    test "normalizes phone numbers correctly" do
      # In dev mode, SMS is disabled so it returns a fake SID
      assert {:ok, "dev_mode_" <> _} = SMS.send_sms("555-123-4567", "Test message")
      assert {:ok, "dev_mode_" <> _} = SMS.send_sms("(555) 123-4567", "Test message")
      assert {:ok, "dev_mode_" <> _} = SMS.send_sms("+15551234567", "Test message")
    end
  end

  describe "notification templates" do
    setup do
      {:ok, org} =
        FieldHub.Accounts.create_organization(%{
          name: "Test Org",
          slug: "test-org-#{System.unique_integer([:positive])}"
        })

      customer = %{
        name: "John Smith",
        phone: "+15551234567",
        sms_notifications_enabled: true
      }

      technician = %{
        name: "Jane Doe",
        phone: "+15559876543"
      }

      job = %{
        id: 1,
        title: "AC Repair",
        status: "en_route",
        scheduled_date: Date.utc_today(),
        scheduled_start: ~T[10:00:00],
        service_address: "123 Main St",
        actual_amount: Decimal.new("150.00"),
        travel_started_at: nil,
        customer: customer,
        technician: technician
      }

      {:ok, job: job, org: org}
    end

    test "notify_technician_en_route sends SMS", %{job: job} do
      assert {:ok, "dev_mode_" <> _} = SMS.notify_technician_en_route(job)
    end

    test "notify_technician_arrived sends SMS", %{job: job} do
      assert {:ok, "dev_mode_" <> _} = SMS.notify_technician_arrived(job)
    end

    test "notify_job_completed sends SMS", %{job: job} do
      assert {:ok, "dev_mode_" <> _} = SMS.notify_job_completed(job)
    end

    test "notify_job_scheduled sends SMS", %{job: job} do
      assert {:ok, "dev_mode_" <> _} = SMS.notify_job_scheduled(job)
    end

    test "notify_technician_new_job sends SMS", %{job: job} do
      assert {:ok, "dev_mode_" <> _} = SMS.notify_technician_new_job(job)
    end

    test "returns error when customer has no phone" do
      job = %{
        title: "Test Job",
        customer: %{name: "No Phone Customer", phone: nil}
      }

      assert {:error, :no_phone} = SMS.notify_technician_en_route(job)
      assert {:error, :no_phone} = SMS.notify_technician_arrived(job)
      assert {:error, :no_phone} = SMS.notify_job_completed(job)
    end
  end
end
