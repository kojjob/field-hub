defmodule FieldHubWeb.Router do
  use FieldHubWeb, :router

  import FieldHubWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FieldHubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FieldHubWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", FieldHubWeb do
  #   pipe_through :api
  # end

  ## Authentication routes

  scope "/", FieldHubWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{FieldHubWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # Onboarding for users without organization
      live "/onboarding", OnboardingLive, :new

      # Main application routes (require organization)
      live "/dashboard", DashboardLive, :index
    live "/technicians", TechnicianLive.Index, :index
    live "/technicians/new", TechnicianLive.Index, :new
    live "/technicians/:id/edit", TechnicianLive.Index, :edit

      live "/customers", CustomerLive.Index, :index
      live "/customers/new", CustomerLive.Index, :new
      live "/customers/:id/edit", CustomerLive.Index, :edit
      live "/customers/:id", CustomerLive.Show, :show

      live "/jobs", JobLive.Index, :index
      live "/jobs/new", JobLive.Index, :new
      live "/jobs/:id/edit", JobLive.Index, :edit
      live "/jobs/:id", JobLive.Show, :show

      live "/dispatch", DispatchLive.Index, :index

      # Technician Mobile Views
      live "/tech/dashboard", TechLive.Dashboard, :index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", FieldHubWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{FieldHubWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
