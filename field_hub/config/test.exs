import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
repo_username =
  cond do
    username = System.get_env("PGUSER") ->
      username

    username = System.get_env("POSTGRES_USER") ->
      username

    match?({:unix, :darwin}, :os.type()) ->
      System.get_env("USER") || "postgres"

    true ->
      "postgres"
  end

repo_password =
  System.get_env("PGPASSWORD") ||
    System.get_env("POSTGRES_PASSWORD") ||
    if(repo_username == "postgres", do: "postgres", else: nil)

config :field_hub, FieldHub.Repo,
  username: repo_username,
  password: repo_password,
  hostname: "localhost",
  database: "field_hub_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :field_hub, FieldHubWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "V9v6C5NA0zGOv9txDXOXusWTPQbGpCnMjUWNj8o4YKUUJD7FkBxmSeIS8vjCPeta",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Configure Swoosh Test adapter
config :field_hub, FieldHub.Mailer, adapter: Swoosh.Adapters.Test
