"""
Example: Simple chart

Meteorological data provided by Meteostat (https://dev.meteostat.net)
under the terms of the Creative Commons Attribution-NonCommercial
4.0 International Public License.

The code is licensed under the MIT license.
"""
# Import Meteostat library and dependencies
using Meteostat
using Dates
using AlgebraOfGraphics, CairoMakie
using DisplayAs

const MT = Meteostat;
const AOG = AlgebraOfGraphics;

# Define point
lat, lon=  -27.3, 153.;

# Fetch all stations
stations = get_stations();

# Filter stations closest to point
stations = MT.filter_nearby!(stations, lat, lon);


# Get hourly data for the station
station_id = first(stations.id);
start_date = Date(2017, 1, 1);
end_date = Date(2017, 1, 8);
weather_data = fetch_data(station_id, Dates.Hour, start_date, end_date);
@show first(weather_data, 5)

# draw figure
fig = (
    AOG.data(weather_data)
    * mapping(:time, [:temp, :dwpt], color=dims(1) => renamer(["Measured", "Dewpoint"]) => "Temperatures")
    * visual(Lines)
);
img = draw(fig;
    figure=(;title="Temperature in Brisbane, QLD"),
    axis=(;width=400)
) |> DisplayAs.PNG
