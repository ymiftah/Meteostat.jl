"""
Generate Meteostat Bulk path
"""

const GRANULARITY_MAP = Dict(
    Dates.Hour => "hourly",
    Dates.Day => "daily",
    Dates.Month => "monthly",
    nothing => "normals"
)


"""
    generate_endpoint_path(
    station::String;
    granularity::Type{T}=Nothing,
    year::Union{Int,Nothing}=nothing,
    map_file::Bool=false,  # Is a source map file?
)::String where {T<:Union{Dates.Period, Nothing}}

Generate the path suffix for the Meteostat API
"""
function generate_endpoint_path(
    station::String;
    granularity::Type{T}=Nothing,
    year::Union{Int,Nothing}=nothing,
    map_file::Bool=false,  # Is a source map file?
)::String where {T<:Union{Dates.Period, Nothing}}

    # Base path
    mapped_granularity = get(GRANULARITY_MAP, granularity, "normals")
    path = "$(mapped_granularity)/" # May need to map the values to Dates

    if (granularity == Dates.Hour)
        isnothing(year) && throw("Hourly granularity requested, but no year was specified.")
        path *= "$(year)/"
    end

    appendix = map_file ? ".map" : ""

    return "$(path)$(station)$(appendix).csv.gz"
end


"""
Reads file from local cache, or downloads from a Meteostat endpoint
"""
function load_handler(
    endpoint::String,
    path_suffix::String,
)
    path = joinpath(CACHE_PATH, path_suffix)
    if isfile(path)
        @info "Reading local file $path"
    else
        @info "Downloading $endpoint to $path"
        dir, _ = splitdir(path)
        mkpath(dir)
        Downloads.download(endpoint, path)
    end
    return path
end








"""
Calculate distance between weather station and geo point
"""
function get_distance(lat1, lon1, lat2, lon2)
    # Earth radius in meters
    radius = 6371000

    # Degress to radian
    lat1, lon1, lat2, lon2 = deg2rad.([lat1, lon1, lat2, lon2])

    # Deltas
    dlat = lat2 - lat1
    dlon = lon2 - lon1

    # Calculate distance
    arch = sin(dlat / 2) ^ 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ^ 2
    arch_sin = 2 * asin(sqrt(arch))

    return radius * arch_sin
end

"""
Adjust temperature-like columns for altitude
"""
function adjust_temp(table, altitude)
    # Default temperature difference by 100 meters
    temp_diff = 0.6

    # Temperature-like columns
    temp_like = map(Symbol, ("temp", "dwpt", "tavg", "tmin", "tmax"))
    adjust_transform(x) = x + (altitude * temp_diff)

    # Adjust values for all temperature-like data
    columns = Dict(col => adjust_transform for col in temp_like if col ∈ Tables.columnnames(table))
    if length(columns) > 0
        table = TableOperations.transform(table, columns) |> Tables.columntable
    end
    return table
end

"""
Filter a table by date range
"""
function filter_time!(table, start_date, end_date)
    subset!(table, :time => ByRow(<=(end_date)), :time => ByRow(>=(start_date)))
end

"""
Return the mean of a list of degrees
"""
function degree_mean(series)
    all(ismissing, series) && return missing

    rads = deg2rad.(series)
    sums = atan(sum(sin.(rads)), sum(cos.(rads)))
    return (rad2deg(sums) + 360) % 360
end

function _add_time_column!(table, ::Type{Dates.Hour})
    transform!(table, [:date, :hour] => ByRow((date, hour) -> Dates.DateTime(date, Dates.Time(hour))) => :time)
    select!(table, Not([:date, :hour]))
    select!(table, :time, Not(:time))
    return table
end


function _add_time_column!(table, ::Type{Dates.Day})
    rename!(table, Dict(:date => :time))
    return table
end


function _add_time_column!(table, ::Type{Dates.Month})
    transform!(table, [:year, :month] => ByRow((year, month) -> Dates.Date(year, month)) => :time)
    select!(table, Not([:year, :month]))
    select!(table, :time, Not(:time))
    return table
end