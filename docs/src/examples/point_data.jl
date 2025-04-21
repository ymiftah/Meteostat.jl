"""
Example: Hourly point data access

Meteorological data provided by Meteostat (https://dev.meteostat.net)
under the terms of the Creative Commons Attribution-NonCommercial
4.0 International Public License.

The code is licensed under the MIT license.
"""

using Dates
using Meteostat: Point, fetch_data

# Time period
start_date = Date(2021, 1, 1)
end_date = Date(2021, 1, 2)

# The point
point = Point(50.3167, 8.5, 320.)

# Get hourly data
data = fetch_data(point, Dates.Hour, start_date, end_date)

# Print to console
@show data