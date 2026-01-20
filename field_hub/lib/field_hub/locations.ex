defmodule FieldHub.Locations do
  @moduledoc """
  Provides location related data such as countries and states.
  """

  @countries [
    {"United States", "US"},
    {"Canada", "CA"},
    {"United Kingdom", "GB"},
    {"Australia", "AU"},
    {"Mexico", "MX"},
    {"Germany", "DE"},
    {"France", "FR"},
    {"Spain", "ES"},
    {"Italy", "IT"},
    {"Japan", "JP"},
    {"Brazil", "BR"},
    {"India", "IN"}
  ]

  @doc """
  Returns a list of common countries as {name, code} tuples.
  """
  def countries do
    @countries
  end

  @doc """
  Returns the country name for a given code.
  """
  def country_name(code) do
    Enum.find_value(@countries, fn {name, c} -> if c == code, do: name end)
  end

  @doc """
  Returns US states from FieldHub.USStates.
  """
  def us_states do
    FieldHub.USStates.select_options()
  end
end
