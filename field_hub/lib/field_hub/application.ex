defmodule FieldHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FieldHubWeb.Telemetry,
      FieldHub.Repo,
      {DNSCluster, query: Application.get_env(:field_hub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FieldHub.PubSub},
      # ChromicPDF for invoice PDF generation
      ChromicPDF,
      # Start a worker by calling: FieldHub.Worker.start_link(arg)
      # {FieldHub.Worker, arg},
      # Start to serve requests, typically the last entry
      FieldHubWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FieldHub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FieldHubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
