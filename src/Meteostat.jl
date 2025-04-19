"""
█▀▄▀█ █▀▀ ▀█▀ █▀▀ █▀█ █▀ ▀█▀ ▄▀█ ▀█▀
█░▀░█ ██▄ ░█░ ██▄ █▄█ ▄█ ░█░ █▀█ ░█░

A Julia library for accessing open weather and climate data

Meteorological data provided by Meteostat (https://dev.meteostat.net)
under the terms of the Creative Commons Attribution-NonCommercial
4.0 International Public License.

The code is licensed under the MIT license.
"""
module Meteostat

using Dates
using HTTP
using Downloads
using DataFrames
using OrderedCollections: OrderedDict
using CSV: CSV
import Statistics: mean

const CACHE_PATH = joinpath(tempdir(), ".meteostat", "cache")

ispath(CACHE_PATH) || mkpath(CACHE_PATH)

include("utilities/utilities.jl")
include("interface/interface.jl")
include("interface/stations.jl")
include("interface/timeseries.jl")

export Point, get_stations, get_weather_data
export fetch_data


end # module Meteostat
