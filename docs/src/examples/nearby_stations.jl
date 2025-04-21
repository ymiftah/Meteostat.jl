"""
Example: Closest weather station by coordinates

Meteorological data provided by Meteostat (https://dev.meteostat.net)
under the terms of the Creative Commons Attribution-NonCommercial
4.0 International Public License.

The code is licensed under the MIT license.
"""

using Meteostat
using Dates

const MT = Meteostat;

# Get weather station
stations = get_stations();

# read closest stations
filter_nearby!(stations, 50., 8.; radius=50_000.);
@show first(stations, 5)

# Filter stations with hourly data
filter_inventory!(stations, Dates.Hour);
@show  first(stations, 5)

# Get the the closest station with hourly data
station = first(stations);
@info ("Closest weather station at coordinates 50, 8:", station["name"])