defmodule FieldHubWeb.PageController do
  use FieldHubWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
