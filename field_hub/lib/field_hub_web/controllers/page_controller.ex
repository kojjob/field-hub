defmodule FieldHubWeb.PageController do
  use FieldHubWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:page_title, "FieldHub - FSM Platform")
    |> assign(
      :page_description,
      "Orchestrate your field operations with AI. The industry-agnostic FSM platform built for scale."
    )
    |> assign(:hide_navbar, true)
    |> render(:home)
  end
end
