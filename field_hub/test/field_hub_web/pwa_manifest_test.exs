defmodule FieldHubWeb.PwaManifestTest do
  use FieldHubWeb.ConnCase, async: true

  test "root layout includes manifest link", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ ~s(<link rel="manifest" href="/manifest.json")
  end

  test "manifest.json is served", %{conn: conn} do
    conn = get(conn, "/manifest.json")

    assert response_content_type(conn, :json) =~ "application/json"
    assert conn.resp_body =~ "\"name\""
  end
end
