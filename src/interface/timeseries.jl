function get_schema(::Type{Dates.Day})
    return OrderedDict(
        :date => Dates.Date => nothing,
        :tavg => Float64 => "The daily average air temperature in °C",
        :tmin => Float64 => "The daily minimum air temperature in °C",
        :tmax => Float64 => "The daily maximum air temperature in °C",
        :prcp => Float64 => "The daily precipitation total in mm",
        :snow => Float64 => "The snow depth in mm",
        :wdir => Float64 => "The average wind direction in degrees (°)",
        :wspd => Float64 => "The average wind speed in km/h",
        :wpgt => Float64 => "The peak wind gust in km/h",
        :pres => Float64 => "The average sea-level air pressure in hPa",
        :tsun => Float64 => "The daily sunshine total in minutes (m)",
    )
end
function get_schema(::Type{Dates.Hour})
    return OrderedDict(
        :date => Dates.Date => nothing,
        :hour => Int => nothing,
        :temp => Float64 => "The average air temperature in °C",
        :dwpt => Float64 => "The dewpoint temperature in °C",
        :rhum => Float64 => "The relative humidity in percent (%)",
        :prcp => Float64 => "The one hour precipitation total in mm",
        :snow => Float64 => "The snow depth in mm",
        :wdir => Float64 => "The average wind direction in degrees (°)",
        :wspd => Float64 => "The average wind speed in km/h",
        :wpgt => Float64 => "The peak wind gust in km/h",
        :pres => Float64 => "The average sea-level air pressure in hPa",
        :tsun => Float64 => "The one hour sunshine total in minutes (m)",
        :coco => Float64 => "The weather condition code",
    )
end
function get_schema(::Type{Dates.Month})
    return OrderedDict(
        :year => Int => nothing,
        :month => Int => nothing,
        :tavg => Float64 => "The monthly average air temperature in °C",
        :tmin => Float64 => "The monthly minimum air temperature in °C",
        :tmax => Float64 => "The monthly maximum air temperature in °C",
        :prcp => Float64 => "The monthly precipitation total in mm",
        :wspd => Float64 => "The average wind speed in km/h",
        :pres => Float64 => "The average sea-level air pressure in hPa",
        :tsun => Float64 => "The monthly sunshine total in minutes (m)",
    )
end

"""
    fetch_data(station::String, granularity::Type{T}

Reads weather data for a given station
"""
function fetch_data(
    station::String, granularity::Type{T}; year::Union{Int,Nothing}=nothing
) where {T<:Union{Dates.Period,Nothing}}
    suffix = generate_endpoint_path(station; granularity=granularity, year=year)
    endpoint = "https://bulk.meteostat.net/v2/" * suffix
    path = load_handler(endpoint, suffix)

    schema = get_schema(granularity)

    df = CSV.read(
        path,
        DataFrame;
        header=collect(keys(schema)),
        types=collect((x -> x.first).(values(schema))),
        dateformat="yyyy-mm-dd",
    )
    for (col, values) in schema
        metadata = values.second
        if !isnothing(metadata)
            colmetadata!(df, col, "label", metadata; style=:note);
        end
    end
    _add_time_column!(df, granularity)
    return df
end

"""
    fetch_data(
        station_id::String, start_date::Dates.Date, end_date::Dates.Date, granularity::Type{T},
        year::Union{Int, Nothing} = nothing) where {T <: Dates.Period}

Fetches hourly weather data for a given date range
"""
function fetch_data(
    station_id::String,
    granularity::Type{Dates.Hour},
    start_date::Dates.Date,
    end_date::Dates.Date;
    kwargs...,
)
    dr = start_date:Day(1):end_date
    years = unique(year.(dr))
    data = vcat((fetch_data(station_id, granularity; year=year) for year in years)...)
    return filter_time!(data, start_date, end_date)
end

"""
    fetch_data(
        point::Point, start_date::Dates.Date, end_date::Dates.Date, granularity::Type{T},
        year::Union{Int, Nothing} = nothing) where {T <: Dates.Period}

fetches weather data for a given date range
"""
function fetch_data(
    station_id::String, granularity::Type{T}, start_date::Dates.Date, end_date::Dates.Date
) where {T<:Dates.Period}
    data = fetch_data(station_id, granularity)
    return filter_time!(data, start_date, end_date)
end

"""
    fetch_data(point::Point, granularity::Type{T};
        year::Union{Int, Nothing} = nothing,
        ) where {T <: Dates.Period}

Fetches weather data for a given point and requested granularity
"""
function fetch_data(
    point::Point,
    granularity::Type{T};
    year::Union{Int,Nothing}=nothing,
    adjust_temp::Bool=true,
) where {T<:Dates.Period}
    stations = get_stations(point, granularity)
    # get the nearest
    station = first(stations)
    id, name, distance, elevation = (x -> (x.id, x.name, x.distance, x.elevation))(station)
    @info "Reading data for station $name $id, at distance $distance"
    data = fetch_data(id, granularity; year=year)
    if adjust_temp
        @info "adjusting temperature for elevation"
        adjust_temp!(data, point.alt, elevation)
    end
    return data
end

"""
    fetch_data(
        point::Point, start_date::Dates.Date, end_date::Dates.Date, granularity::Type{T},
        year::Union{Int, Nothing} = nothing) where {T <: Dates.Period}

fetches weather data for a given date range
"""
function fetch_data(
    point::Point,
    granularity::Type{T},
    start_date::Dates.Date,
    end_date::Dates.Date;
    year::Union{Int,Nothing}=nothing,
    kwargs...,
) where {T<:Dates.Period}
    data = fetch_data(point, granularity; year=year, kwargs...)
    return filter_time!(data, start_date, end_date)
end

"""
    fetch_data(
        point::Point, start_date::Dates.Date, end_date::Dates.Date, granularity::Type{T},
        year::Union{Int, Nothing} = nothing) where {T <: Dates.Period}

Fetches hourly weather data for a given date range
"""
function fetch_data(
    point::Point,
    granularity::Type{Dates.Hour},
    start_date::Dates.Date,
    end_date::Dates.Date;
    kwargs...,
)
    dr = start_date:Day(1):end_date
    years = unique(year.(dr))
    data = vcat((fetch_data(point, granularity; year=year, kwargs...) for year in years)...)
    return filter_time!(data, start_date, end_date)
end
