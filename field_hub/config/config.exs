# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :field_hub, :scopes,
  user: [
    default: true,
    module: FieldHub.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: FieldHub.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :field_hub,
  ecto_repos: [FieldHub.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :field_hub, FieldHubWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FieldHubWeb.ErrorHTML, json: FieldHubWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: FieldHub.PubSub,
  live_view: [signing_salt: "K+s1qvUi"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  field_hub: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=. --loader:.png=dataurl --loader:.svg=dataurl),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  field_hub: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Swoosh for email sending (use Local adapter in dev)
config :field_hub, FieldHub.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client configuration (for local mailbox preview)
config :swoosh, :api_client, false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
