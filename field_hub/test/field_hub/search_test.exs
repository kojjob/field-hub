defmodule FieldHub.SearchTest do
  use FieldHub.DataCase

  alias FieldHub.Search

  import FieldHub.AccountsFixtures
  import FieldHub.CRMFixtures
  import FieldHub.JobsFixtures

  describe "search_all/3" do
    setup do
      org = organization_fixture()
      customer = customer_fixture(org.id, %{name: "Acme Corporation", email: "acme@test.com"})
      job = job_fixture(org.id, %{title: "HVAC Repair at Acme", customer_id: customer.id})

      %{org: org, customer: customer, job: job}
    end

    test "returns empty results for short queries", %{org: org} do
      results = Search.search_all(org.id, "a")
      assert results.total == 0
      assert results.jobs == []
      assert results.customers == []
      assert results.invoices == []
    end

    test "finds jobs by title", %{org: org} do
      results = Search.search_all(org.id, "HVAC")
      assert length(results.jobs) > 0
      assert Enum.any?(results.jobs, fn j -> String.contains?(j.title, "HVAC") end)
    end

    test "finds customers by name", %{org: org} do
      results = Search.search_all(org.id, "Acme")
      assert length(results.customers) > 0
      assert Enum.any?(results.customers, fn c -> String.contains?(c.title, "Acme") end)
    end

    test "respects organization boundaries" do
      other_org = organization_fixture(%{name: "Other Org"})
      results = Search.search_all(other_org.id, "Acme")

      # Should not find customer or job from different org
      assert results.total == 0
    end

    test "limits results per category", %{org: org, customer: customer} do
      # Create multiple jobs
      for i <- 1..10 do
        job_fixture(org.id, %{title: "Test Job #{i}", customer_id: customer.id})
      end

      results = Search.search_all(org.id, "Test Job", limit: 3)
      assert length(results.jobs) <= 3
    end
  end
end
