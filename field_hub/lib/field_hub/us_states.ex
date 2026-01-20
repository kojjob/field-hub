defmodule FieldHub.USStates do
  @moduledoc """
  US States and territories for address forms.
  All addresses in this application are USA-only.
  """

  @states [
    {"Alabama", "AL"},
    {"Alaska", "AK"},
    {"Arizona", "AZ"},
    {"Arkansas", "AR"},
    {"California", "CA"},
    {"Colorado", "CO"},
    {"Connecticut", "CT"},
    {"Delaware", "DE"},
    {"District of Columbia", "DC"},
    {"Florida", "FL"},
    {"Georgia", "GA"},
    {"Hawaii", "HI"},
    {"Idaho", "ID"},
    {"Illinois", "IL"},
    {"Indiana", "IN"},
    {"Iowa", "IA"},
    {"Kansas", "KS"},
    {"Kentucky", "KY"},
    {"Louisiana", "LA"},
    {"Maine", "ME"},
    {"Maryland", "MD"},
    {"Massachusetts", "MA"},
    {"Michigan", "MI"},
    {"Minnesota", "MN"},
    {"Mississippi", "MS"},
    {"Missouri", "MO"},
    {"Montana", "MT"},
    {"Nebraska", "NE"},
    {"Nevada", "NV"},
    {"New Hampshire", "NH"},
    {"New Jersey", "NJ"},
    {"New Mexico", "NM"},
    {"New York", "NY"},
    {"North Carolina", "NC"},
    {"North Dakota", "ND"},
    {"Ohio", "OH"},
    {"Oklahoma", "OK"},
    {"Oregon", "OR"},
    {"Pennsylvania", "PA"},
    {"Rhode Island", "RI"},
    {"South Carolina", "SC"},
    {"South Dakota", "SD"},
    {"Tennessee", "TN"},
    {"Texas", "TX"},
    {"Utah", "UT"},
    {"Vermont", "VT"},
    {"Virginia", "VA"},
    {"Washington", "WA"},
    {"West Virginia", "WV"},
    {"Wisconsin", "WI"},
    {"Wyoming", "WY"}
  ]

  @territories [
    {"American Samoa", "AS"},
    {"Guam", "GU"},
    {"Northern Mariana Islands", "MP"},
    {"Puerto Rico", "PR"},
    {"U.S. Virgin Islands", "VI"}
  ]

  @doc """
  Returns list of US states as {name, code} tuples for select dropdowns.
  """
  def states, do: @states

  @doc """
  Returns list of US territories as {name, code} tuples.
  """
  def territories, do: @territories

  @doc """
  Returns all states and territories combined.
  """
  def all, do: @states ++ @territories

  @doc """
  Returns list formatted for Phoenix form select options.
  Format: [{display_name, value}, ...]
  """
  def select_options do
    Enum.map(@states, fn {name, code} -> {name, code} end)
  end

  @doc """
  Returns all states and territories formatted for select options.
  """
  def select_options_with_territories do
    Enum.map(@states ++ @territories, fn {name, code} -> {name, code} end)
  end

  @doc """
  Returns the full state name for a given code.
  """
  def name_for_code(code) when is_binary(code) do
    code = String.upcase(code)

    case Enum.find(@states ++ @territories, fn {_name, c} -> c == code end) do
      {name, _code} -> name
      nil -> nil
    end
  end

  @doc """
  Validates if a given code is a valid US state or territory code.
  """
  def valid_code?(code) when is_binary(code) do
    code = String.upcase(code)
    Enum.any?(@states ++ @territories, fn {_name, c} -> c == code end)
  end
end
