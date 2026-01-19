defmodule FieldHubWeb.PortalHTML do
  @moduledoc """
  Customer portal pages rendered by PortalController.

  See the `portal_html` directory for all templates available.
  """

  use FieldHubWeb, :html

  embed_templates "portal_html/*"
end
