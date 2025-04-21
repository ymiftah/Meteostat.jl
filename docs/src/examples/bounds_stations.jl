"""
Example: Get weather stations by geographical area

Meteorological data provided by Meteostat (https://dev.meteostat.net)
under the terms of the Creative Commons Attribution-NonCommercial
4.0 International Public License.

The code is licensed under the MIT license.
"""

using Meteostat

# Get all stations
stations = get_stations();

# Get number of stations in northern hemisphere
northern = filter_bounds!(copy(stations), (90., -180.), (0., 180.));
@info "Stations in northern hemisphere: $(length(northern))"

# Get number of stations in southern hemisphere
southern = filter_bounds!(copy(stations), (0., -180.), (-90., 180.));
@info "Stations in southern hemisphere:: $(length(southern))"