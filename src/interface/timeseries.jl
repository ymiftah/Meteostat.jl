function get_schema(::Type{Dates.Day})
    OrderedDict(
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
    OrderedDict(
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
    OrderedDict(
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
Reads weather data for a given station
"""
function get_weather_data(station::String, granularity::Type{T}; year::Union{Int,Nothing}=nothing) where {T<:Union{Dates.Period, Nothing}}
    suffix = generate_endpoint_path(station; granularity=granularity, year=year)
    endpoint = "https://bulk.meteostat.net/v2/" * suffix
    path = load_handler(endpoint, suffix)

    schema = get_schema(granularity)

    df = CSV.read(
        path,
        DataFrame,
        header=collect(keys(schema)),
        types=collect(values(schema)),
        dateformat = "yyyy-mm-dd",
        )
    _add_time_column!(df, granularity)
    return df
end

function fetch(point::Point, granularity::Type{T}; year::Union{Int,Nothing}=nothing) where {T<:Dates.Period}
    stations = get_stations(point, granularity)
    # get the nearest
    station = first(stations.id)
    @debug "Reading data for station_id $station"
    get_weather_data(station, granularity; year=year)
end

function fetch(point::Point, start_date::Dates.Date, end_date::Dates.Date, granularity::Type{T}, year::Union{Int,Nothing}=nothing) where {T<:Dates.Period}
    data = fetch(point, granularity; year=year)
    filter_time!(data, start_date, end_date)
end

function fetch(point::Point, granularity::Type{Dates.Hour}, start_date::Dates.Date, end_date::Dates.Date)
    dr = start_date:Day(1):end_date
    years = unique(year.(dr))
    data = vcat(collect(
        fetch(point, granularity; year=year)
        for year in years
    )...)
    filter_time!(data, start_date, end_date)
end