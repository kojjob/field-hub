defmodule FieldHub.Dispatch.TechnicianAuthTest do
  use FieldHub.DataCase

  alias FieldHub.Dispatch
  alias FieldHub.Dispatch.Technician
  alias FieldHub.Accounts

  describe "technician authentication & tokens" do
    setup do
      org = FieldHub.AccountsFixtures.organization_fixture()
      user = FieldHub.AccountsFixtures.user_fixture()

      {:ok, technician} =
        Dispatch.create_technician(org.id, %{
          name: "Tech One",
          user_id: user.id,
          status: "available",
          color: "#000000"
        })

      %{technician: technician, user: user, org: org}
    end

    test "update_technician_device_token/3 updates fcm token", %{technician: technician} do
      assert {:ok, %Technician{} = updated_tech} =
               Dispatch.update_technician_device_token(technician, "fcm", "new-fcm-token")

      assert updated_tech.fcm_token == "new-fcm-token"
    end

    test "update_technician_device_token/3 updates apns token", %{technician: technician} do
      assert {:ok, %Technician{} = updated_tech} =
               Dispatch.update_technician_device_token(technician, "apns", "new-apns-token")

      assert updated_tech.apns_token == "new-apns-token"
    end
  end
end
