defmodule FieldHub.Geo do
  @moduledoc """
  Geocoding service for converting addresses to coordinates.

  This module provides geocoding functionality to automatically
  populate lat/lng fields when addresses are provided.

  Uses OpenStreetMap's Nominatim API (free, no API key required).
  For production, consider using Google Maps, Mapbox, or similar.
  """

  require Logger

  @nominatim_url "https://nominatim.openstreetmap.org/search"
  @user_agent "FieldHub/1.0"

  @doc """
  Geocodes an address string to coordinates.

  Returns {:ok, {lat, lng}} on success, {:error, reason} on failure.

  ## Examples

      iex> FieldHub.Geo.geocode("1600 Amphitheatre Parkway, Mountain View, CA")
      {:ok, {37.4224764, -122.0842499}}

      iex> FieldHub.Geo.geocode("invalid address")
      {:error, :not_found}
  """
  @spec geocode(String.t()) :: {:ok, {float(), float()}} | {:error, atom()}
  def geocode(nil), do: {:error, :no_address}
  def geocode(""), do: {:error, :no_address}

  def geocode(address) when is_binary(address) do
    query = URI.encode_www_form(address)
    url = "#{@nominatim_url}?q=#{query}&format=json&limit=1"

    case http_get(url) do
      {:ok, [%{"lat" => lat_str, "lon" => lng_str} | _]} ->
        lat = parse_float(lat_str)
        lng = parse_float(lng_str)
        {:ok, {lat, lng}}

      {:ok, []} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.warning("Geocoding failed for '#{address}': #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Builds a full address string from job address components.
  """
  def build_address(nil, _, _, _), do: nil
  def build_address("", _, _, _), do: nil

  def build_address(street, city, state, zip) do
    [street, city, state, zip]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
    |> case do
      "" -> nil
      addr -> addr
    end
  end

  @doc """
  Geocodes an address and returns a map with lat/lng keys.
  Useful for piping into changesets.

  ## Examples

      address = "123 Main St, City, ST 12345"
      coords = FieldHub.Geo.geocode_to_map(address)
      # => %{service_lat: 37.123, service_lng: -122.456}
  """
  def geocode_to_map(address, lat_key \\ :service_lat, lng_key \\ :service_lng) do
    case geocode(address) do
      {:ok, {lat, lng}} ->
        %{lat_key => lat, lng_key => lng}

      {:error, _} ->
        %{}
    end
  end

  @doc """
  Attempts to geocode job address and merge coordinates into attrs.
  Only geocodes if lat/lng are not already present.
  """
  def maybe_geocode_job_attrs(attrs) when is_map(attrs) do
    # Skip if coordinates already provided
    if has_coordinates?(attrs) do
      attrs
    else
      address = extract_job_address(attrs)

      case geocode(address) do
        {:ok, {lat, lng}} ->
          attrs
          |> Map.put("service_lat", lat)
          |> Map.put("service_lng", lng)

        {:error, _} ->
          attrs
      end
    end
  end

  # Check if attrs already have coordinates
  defp has_coordinates?(attrs) do
    lat = Map.get(attrs, "service_lat") || Map.get(attrs, :service_lat)
    lng = Map.get(attrs, "service_lng") || Map.get(attrs, :service_lng)

    is_number(lat) and is_number(lng)
  end

  # Extract address components from job attrs
  defp extract_job_address(attrs) do
    street = Map.get(attrs, "service_address") || Map.get(attrs, :service_address)
    city = Map.get(attrs, "service_city") || Map.get(attrs, :service_city)
    state = Map.get(attrs, "service_state") || Map.get(attrs, :service_state)
    zip = Map.get(attrs, "service_zip") || Map.get(attrs, :service_zip)

    build_address(street, city, state, zip)
  end

  # HTTP GET with simple HTTP client
  # Uses :httpc from Erlang's inets (always available)
  defp http_get(url) do
    # Ensure inets is started
    :inets.start()
    :ssl.start()

    headers = [
      {~c"User-Agent", String.to_charlist(@user_agent)},
      {~c"Accept", ~c"application/json"}
    ]

    request = {String.to_charlist(url), headers}

    http_opts = [
      timeout: 10_000,
      connect_timeout: 5_000,
      ssl: [verify: :verify_none]
    ]

    opts = [body_format: :binary]

    case :httpc.request(:get, request, http_opts, opts) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        Jason.decode(body)

      {:ok, {{_, status, _}, _, _}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_float(str) when is_binary(str) do
    case Float.parse(str) do
      {f, _} -> f
      :error -> nil
    end
  end

  defp parse_float(num) when is_number(num), do: num * 1.0
  defp parse_float(_), do: nil
end
