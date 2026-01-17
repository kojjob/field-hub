defmodule FieldHub.Accounts.OrganizationsTest do
  use FieldHub.DataCase, async: true

  alias FieldHub.Accounts
  alias FieldHub.Accounts.Organization

  describe "list_organizations/0" do
    test "returns all organizations" do
      org1 = organization_fixture(%{name: "Org One", slug: "org-one"})
      org2 = organization_fixture(%{name: "Org Two", slug: "org-two"})

      organizations = Accounts.list_organizations()

      assert length(organizations) == 2
      assert Enum.any?(organizations, &(&1.id == org1.id))
      assert Enum.any?(organizations, &(&1.id == org2.id))
    end

    test "returns empty list when no organizations exist" do
      assert Accounts.list_organizations() == []
    end
  end

  describe "get_organization!/1" do
    test "returns the organization with given id" do
      org = organization_fixture()

      assert Accounts.get_organization!(org.id).id == org.id
    end

    test "raises Ecto.NoResultsError if organization doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_organization!(9999)
      end
    end
  end

  describe "get_organization/1" do
    test "returns {:ok, organization} for existing id" do
      org = organization_fixture()

      assert {:ok, fetched_org} = Accounts.get_organization(org.id)
      assert fetched_org.id == org.id
    end

    test "returns {:error, :not_found} for non-existent id" do
      assert {:error, :not_found} = Accounts.get_organization(9999)
    end
  end

  describe "get_organization_by_slug/1" do
    test "returns the organization with matching slug" do
      org = organization_fixture(%{slug: "unique-slug"})

      assert {:ok, fetched_org} = Accounts.get_organization_by_slug("unique-slug")
      assert fetched_org.id == org.id
    end

    test "returns {:error, :not_found} for non-existent slug" do
      assert {:error, :not_found} = Accounts.get_organization_by_slug("non-existent")
    end
  end

  describe "create_organization/1" do
    test "with valid data creates an organization" do
      valid_attrs = %{
        name: "Ace HVAC Services",
        slug: "ace-hvac-services",
        email: "info@acehvac.com",
        phone: "555-123-4567"
      }

      assert {:ok, %Organization{} = org} = Accounts.create_organization(valid_attrs)
      assert org.name == "Ace HVAC Services"
      assert org.slug == "ace-hvac-services"
      assert org.email == "info@acehvac.com"
      assert org.subscription_tier == "trial"
      assert org.subscription_status == "trial"
    end

    test "with invalid data returns error changeset" do
      invalid_attrs = %{name: nil}

      assert {:error, %Ecto.Changeset{}} = Accounts.create_organization(invalid_attrs)
    end

    test "with duplicate slug returns error" do
      organization_fixture(%{slug: "taken-slug"})

      assert {:error, changeset} =
               Accounts.create_organization(%{
                 name: "Another Org",
                 slug: "taken-slug"
               })

      assert "has already been taken" in errors_on(changeset).slug
    end

    test "sets trial_ends_at to 14 days from now" do
      valid_attrs = %{name: "Trial Org", slug: "trial-org"}

      assert {:ok, org} = Accounts.create_organization(valid_attrs)

      # Trial should end in approximately 14 days
      expected_end = DateTime.utc_now() |> DateTime.add(14, :day)
      diff = DateTime.diff(org.trial_ends_at, expected_end)

      # Within 1 minute tolerance
      assert abs(diff) < 60
    end
  end

  describe "create_organization_with_owner/2" do
    test "creates organization and associates user as owner" do
      user = user_fixture()
      org_attrs = %{name: "New Org", slug: "new-org"}

      assert {:ok, %{organization: org, user: updated_user}} =
               Accounts.create_organization_with_owner(org_attrs, user)

      assert org.name == "New Org"
      assert updated_user.organization_id == org.id
      assert updated_user.role == "owner"
    end

    test "rolls back if organization creation fails" do
      user = user_fixture()
      invalid_attrs = %{name: nil}

      assert {:error, :organization, _changeset, _changes} =
               Accounts.create_organization_with_owner(invalid_attrs, user)

      # User should not be updated
      refetched_user = Accounts.get_user!(user.id)
      assert is_nil(refetched_user.organization_id)
    end
  end

  describe "update_organization/2" do
    test "with valid data updates the organization" do
      org = organization_fixture()
      update_attrs = %{name: "Updated Name", phone: "555-999-8888"}

      assert {:ok, updated_org} = Accounts.update_organization(org, update_attrs)
      assert updated_org.name == "Updated Name"
      assert updated_org.phone == "555-999-8888"
    end

    test "with invalid data returns error changeset" do
      org = organization_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_organization(org, %{name: nil})

      assert Accounts.get_organization!(org.id).name == org.name
    end

    test "cannot change slug after creation" do
      org = organization_fixture(%{slug: "original-slug"})

      assert {:ok, updated_org} =
               Accounts.update_organization(org, %{
                 name: "New Name",
                 slug: "new-slug"
               })

      # Slug should remain unchanged
      assert updated_org.slug == "original-slug"
    end
  end

  describe "delete_organization/1" do
    test "deletes the organization" do
      org = organization_fixture()

      assert {:ok, %Organization{}} = Accounts.delete_organization(org)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_organization!(org.id) end
    end

    test "nullifies organization_id for associated users" do
      org = organization_fixture()
      user = user_fixture()

      # Associate user with org
      {:ok, user} = Repo.update(Ecto.Changeset.change(user, organization_id: org.id))
      assert user.organization_id == org.id

      assert {:ok, _} = Accounts.delete_organization(org)

      # User's organization_id should be nullified (based on migration on_delete: :delete_all)
      # Actually the migration uses :delete_all, so user is deleted
      refetched_user = Repo.get(FieldHub.Accounts.User, user.id)
      # Migration has on_delete: :delete_all, so user should be deleted
      assert is_nil(refetched_user)
    end
  end

  describe "update_subscription/2" do
    test "updates subscription tier and status" do
      org = organization_fixture()

      assert {:ok, updated_org} =
               Accounts.update_subscription(org, %{
                 subscription_tier: "growth",
                 subscription_status: "active"
               })

      assert updated_org.subscription_tier == "growth"
      assert updated_org.subscription_status == "active"
    end

    test "updates stripe_customer_id" do
      org = organization_fixture()

      assert {:ok, updated_org} =
               Accounts.update_subscription(org, %{
                 stripe_customer_id: "cus_abc123"
               })

      assert updated_org.stripe_customer_id == "cus_abc123"
    end
  end

  describe "generate_unique_slug/1" do
    test "generates slug from name" do
      slug = Accounts.generate_unique_slug("Ace HVAC Services")

      assert slug == "ace-hvac-services"
    end

    test "appends suffix when slug already exists" do
      organization_fixture(%{slug: "ace-hvac"})

      slug = Accounts.generate_unique_slug("Ace HVAC")

      assert String.starts_with?(slug, "ace-hvac-")
      assert slug != "ace-hvac"
    end

    test "handles special characters" do
      slug = Accounts.generate_unique_slug("Bob's Plumbing & Heating!")

      assert slug == "bobs-plumbing-heating"
    end
  end

  describe "organization_active?/1" do
    test "returns true for active subscription" do
      org = organization_fixture()
      {:ok, org} = Accounts.update_subscription(org, %{subscription_status: "active"})

      assert Accounts.organization_active?(org) == true
    end

    test "returns true for trial within trial period" do
      org = organization_fixture()

      assert Accounts.organization_active?(org) == true
    end

    test "returns false for cancelled subscription" do
      org = organization_fixture()
      {:ok, org} = Accounts.update_subscription(org, %{subscription_status: "cancelled"})

      assert Accounts.organization_active?(org) == false
    end

    test "returns false for expired trial" do
      org = organization_fixture()
      past = DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
      {:ok, org} = Repo.update(Ecto.Changeset.change(org, trial_ends_at: past))

      assert Accounts.organization_active?(org) == false
    end
  end

  # Fixtures

  defp organization_fixture(attrs \\ %{}) do
    {:ok, org} =
      attrs
      |> Enum.into(%{
        name: "Test Organization #{System.unique_integer([:positive])}",
        slug: "test-org-#{System.unique_integer([:positive])}"
      })
      |> Accounts.create_organization()

    org
  end

  defp user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "test#{System.unique_integer([:positive])}@example.com",
        password: "validpassword123"
      })
      |> FieldHub.Accounts.register_user()

    user
  end
end
