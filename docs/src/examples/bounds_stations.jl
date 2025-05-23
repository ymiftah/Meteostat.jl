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
northern = filter_bounds!(copy(stations), (90.0, -180.0), (0.0, 180.0));
@info "Stations in northern hemisphere: $(size(northern,1))"

# Get number of stations in southern hemisphere
southern = filter_bounds!(copy(stations), (0.0, -180.0), (-90.0, 180.0));
@info "Stations in southern hemisphere:: $(size(southern,1))"
