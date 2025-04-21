# Meteostat Julia Package

The Meteostat Julia library provides a simple API for accessing open weather and climate data. The historical observations and statistics are collected by [Meteostat](https://meteostat.net) from different public interfaces, most of which are governmental.

Among the data sources are national weather services like the National Oceanic and Atmospheric Administration (NOAA) and Germany's national meteorological service (DWD).

## Disclaimer

This project is not affiliated to the [Meteostat organisation](https://meteostat.net/en/about). Do consider [donating](https://meteostat.net/en/donate) to support the open source project.

## Installation

The Meteostat Julia package is not yet available on the public registry, insall from Github.

```julia
import Pkg
Pkg.add("https://github.com/ymiftah/Meteostat")
```

## Example

Let's plot 2018 temperature data for Vancouver, BC:

```julia
# Import Meteostat library and dependencies
using Meteostat:Point, fetch_data
using Dates
using AlgebraOfGraphics, CairoMakie

# Set time period
start_date = Date(2018, 1, 1)
end_date = Date(2018, 12, 31)

# Create Point for Vancouver, BC
location = Point(49.2497, -123.1193, 70.)

# Get daily data for 2018
weather_data = fetch_data(location, Dates.Day, start_date, end_date)

# Plot line chart including average, minimum and maximum temperature

fig = (
    data(weather_data)
    * mapping(:time, [:tavg, :tmin, :tmax], color=dims(1) => renamer(["avg", "min", "max"]) => "Temperatures ")
    * visual(Lines)
)
draw(fig;
    figure=(;title="Vancouver, BC"),
    axis=(;width=600)
)
```


## Contributing

Instructions on building and testing the Meteostat Python package can be found in the [documentation](https://dev.meteostat.net/python/contributing.html). More information about the Meteostat bulk data interface is available [here](https://dev.meteostat.net/bulk/).

## Donating

If you want to support the project financially, you can make a donation using one of the following services:

* [GitHub](https://github.com/sponsors/clampr)
* [Patreon](https://www.patreon.com/meteostat)
* [PayPal](https://www.paypal.com/donate?hosted_button_id=MQ67WRDC8EW38)

## Data License

Meteorological data is provided under the terms of the [Creative Commons Attribution-NonCommercial 4.0 International Public License (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/legalcode). You may build upon the material
for any purpose, even commercially. However, you are not allowed to redistribute Meteostat data "as-is" for commercial purposes.

By using the Meteostat Julia library you agree to Meteostat's [terms of service](https://dev.meteostat.net/terms.html). All meteorological data sources used by the Meteostat project are listed [here](https://dev.meteostat.net/sources.html).

## Code License

The code of this library is available under the [MIT license](https://opensource.org/licenses/MIT).
