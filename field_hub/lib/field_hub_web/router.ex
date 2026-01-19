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

  pipeline :portal do
    plug FieldHubWeb.PortalAuth, :fetch_current_portal_customer
  end

  pipeline :require_portal_customer do
    plug FieldHubWeb.PortalAuth, :require_portal_customer
  end

  scope "/", FieldHubWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/portal", FieldHubWeb do
    pipe_through [:browser, :portal]

    get "/login/:token", PortalSessionController, :create
    delete "/logout", PortalSessionController, :delete
  end

  scope "/portal", FieldHubWeb do
    pipe_through [:browser, :portal, :require_portal_customer]

    live_session :portal_customer,
      on_mount: [{FieldHubWeb.PortalAuth, :mount_portal_customer}],
      layout: {FieldHubWeb.Layouts, :portal} do
      live "/", PortalLive.Dashboard, :index
      live "/jobs/:number", PortalLive.JobDetail, :show
      live "/history", PortalLive.History, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", FieldHubWeb do
  #   pipe_through :api
  # end

  ## Authentication routes

  scope "/", FieldHubWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{FieldHubWeb.UserAuth, :require_authenticated}],
      layout: {FieldHubWeb.Layouts, :app} do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # Onboarding for users without organization
      live "/onboarding", OnboardingLive, :new

      # Main application routes (require organization)
      live "/dashboard", DashboardLive, :index
      live "/technicians", TechnicianLive.Index, :index
      live "/technicians/new", TechnicianLive.Index, :new
      live "/technicians/:slug/edit", TechnicianLive.Index, :edit

      live "/customers", CustomerLive.Index, :index
      live "/customers/new", CustomerLive.Index, :new
      live "/customers/:slug/edit", CustomerLive.Index, :edit
      live "/customers/:slug", CustomerLive.Index, :show

      live "/jobs", JobLive.Index, :index
      live "/jobs/new", JobLive.Index, :new
      live "/jobs/:number/edit", JobLive.Index, :edit
      live "/jobs/:number", JobLive.Show, :show

      live "/dispatch", DispatchLive.Index, :index

      # Reports
      live "/reports", ReportLive.Index, :index

      # Technician Mobile Views
      live "/tech/dashboard", TechLive.Dashboard, :index
      live "/tech/jobs/:number", TechLive.JobShow, :show
      live "/tech/jobs/:number/complete", TechLive.JobComplete, :complete

      # Settings
      live "/settings/organization", SettingsLive.Organization, :index
      live "/settings/users", SettingsLive.Users, :index
      live "/settings/notifications", SettingsLive.Notifications, :index
      live "/settings/billing", SettingsLive.Billing, :index
      live "/settings/terminology", SettingsLive.Terminology, :index
      live "/settings/branding", SettingsLive.Branding, :index
      live "/settings/workflows", SettingsLive.Workflows, :index
      live "/settings/custom-fields", SettingsLive.CustomFields, :index
      live "/settings/custom-fields/new", SettingsLive.CustomFields, :new
    end

    get "/reports/export", ReportController, :export

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

  # Enable Swoosh mailbox preview in development
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
