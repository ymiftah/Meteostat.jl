function get_schema(::Type{Dates.Day})
    return OrderedDict(
        :date => Dates.Date,
        :tavg => Float64,
        :tmin => Float64,
        :tmax => Float64,
        :prcp => Float64,
        :snow => Float64,
        :wdir => Float64,
        :wspd => Float64,
        :wpgt => Float64,
        :pres => Float64,
        :tsun => Float64,
    )
end
function get_schema(::Type{Dates.Hour})
    return OrderedDict(
        :date => Dates.Date,
        :hour => Int,
        :temp => Float64,
        :dwpt => Float64,
        :rhum => Float64,
        :prcp => Float64,
        :snow => Float64,
        :wdir => Float64,
        :wspd => Float64,
        :wpgt => Float64,
        :pres => Float64,
        :tsun => Float64,
        :coco => Float64,
    )
end
function get_schema(::Type{Dates.Month})
    return OrderedDict(
        :year => Int,
        :month => Int,
        :tavg => Float64,
        :tmin => Float64,
        :tmax => Float64,
        :prcp => Float64,
        :wspd => Float64,
        :pres => Float64,
        :tsun => Float64,
    )
end

"""
    get_weather_data(station::String, granularity::Type{T}

Reads weather data for a given station
"""
function get_weather_data(
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
        types=collect(values(schema)),
        dateformat="yyyy-mm-dd",
    )
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
    kwargs...
)
    dr = start_date:Day(1):end_date
    years = unique(year.(dr))
    data = vcat((get_weather_data(station_id, granularity; year=year) for year in years)...)
    return filter_time!(data, start_date, end_date)
end


"""
    fetch_data(point::Point, granularity::Type{T};
        year::Union{Int, Nothing} = nothing,
        ) where {T <: Dates.Period}

Fetches weather data for a given point and requested granularity
"""
function fetch_data(
    point::Point, granularity::Type{T}; year::Union{Int,Nothing}=nothing, adjust_temp::Bool=true
) where {T<:Dates.Period}
    stations = get_stations(point, granularity)
    # get the nearest
    station = first(stations)
    id, name, distance, elevation = (x -> (x.id, x.name, x.distance, x.elevation))(station)
    @info "Reading data for station $name $id, at distance $distance"
    data = get_weather_data(id, granularity; year=year)
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
    kwargs...
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
    kwargs...
)
    dr = start_date:Day(1):end_date
    years = unique(year.(dr))
    data = vcat((fetch_data(point, granularity; year=year, kwargs...) for year in years)...)
    return filter_time!(data, start_date, end_date)
end