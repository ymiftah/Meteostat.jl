const STATIONS_SCHEMA = OrderedDict(
    :id => String,
    :name => String,
    :country => String,
    :region => String,
    :wmo => String,
    :icao => String,
    :latitude => Float64,
    :longitude => Float64,
    :elevation => Float64,
    :timezone => String,
    :hourly_start => Dates.Date,
    :hourly_end => Dates.Date,
    :daily_start => Dates.Date,
    :daily_end => Dates.Date,
    :monthly_start => Dates.Date,
    :monthly_end => Dates.Date,
)

"""
Reads all stations
"""
function get_stations()
    endpoint = "https://bulk.meteostat.net/v2/stations/slim.csv.gz"
    path = load_handler(endpoint, "stations.csv.gz")
    df = CSV.read(
        path,
        DataFrame,
        header=collect(keys(STATIONS_SCHEMA)),
        types=collect(values(STATIONS_SCHEMA)),
        dateformat = "yyyy-mm-dd",
        )
    return df
end

"""
Reads all stations within radius distance of the point
"""
function get_stations(point::Point; radius::Union{Float64, Nothing} = 35_000.)
    lat = point.lat
    lon = point.lon
    alt = point.alt
    stations = get_stations()
    filter_nearby!(stations, lat, lon; radius=radius)
    score_values!(stations; radius=radius, alt=alt)
    return stations
end

function get_stations(lat, lon; radius::Union{Float64, Nothing} = 35_000.)
    point = Point(lat=lat, lon=lon)
    stations = get_stations(point;radius=radius)
    return stations
end

"""
Reads all stations within radius distance of the point and where data is available for the requested granularity
"""
function get_stations(point::Point, granularity::Type{T}; radius::Union{Float64, Nothing} = 35_000.) where {T<:Dates.Period}
    stations = get_stations(point; radius=radius)
    filter_inventory!(stations, granularity)
    score_values!(stations; radius=radius, alt=point.alt)
    return stations
end

"""
Reads all stations within radius distance of the point and where data is available for the requested granularity and dates
"""
function get_stations(point::Point, granularity::Type{T}, start_date::Dates.Date, end_date::Dates.Date; radius::Union{Float64, Nothing} = 35_000.) where {T<:Dates.Period}
    stations = get_stations(point; radius=radius)
    filter_inventory!(stations, granularity, (start_date, end_date))
    score_values!(stations; radius=radius, alt=point.alt)
    return stations
end


# Filters



"""
Sort/filter weather stations by physical distance
"""
function filter_nearby!(
        stations, lat::Float64, lon::Float64; radius::Union{Float64, Nothing} = nothing)
    dropmissing!(stations, [:latitude, :longitude])
    transform!(stations,
        [:latitude, :longitude] => ByRow((x, y) -> get_distance(x, y, lat, lon)) => :distance
    )
    if !isnothing(radius)
        subset!(stations, :distance => ByRow(<=(radius)))
    end
    sort!(stations, :distance)

    if nrow(stations) == 0
        @warn "No weather stations found within radius $radius meters"
    end
    return stations
end

"""
Filter weather stations by country/region code
"""
function filter_region!(stations; country::Union{String, Nothing} = nothing,
        state::Union{String, Nothing} = nothing)
    # stations = copy(stations)
    if !isnothing(country)
        subset!(stations, :country => ByRow(==(country)))
    end
    if !isnothing(state)
        subset!(stations, :region => ByRow(==(state)))
    end

    if nrow(stations) == 0
        @warn "No weather stations found for the region"
    end
    return stations
end

"""
Filter weather stations by geographical bounds
"""
function filter_bounds!(
        stations, top_left::Tuple{Float64, Float64}, bottom_right::Tuple{Float64, Float64})
    # Return stations in boundaries
    dropmissing!(stations, [:latitude, :longitude])
    subset!(stations,
        :latitude => ByRow(<=(top_left[1])),
        :latitude => ByRow(>=(bottom_right[1])),
        :longitude => ByRow(>=(top_left[2])),
        :longitude => ByRow(<=(bottom_right[2]))
    )
    if nrow(stations) == 0
        @warn "No weather stations found within bounds"
    end
    return stations
end

"""
Filter weather stations by inventory data
"""
function filter_inventory!(
        stations,
        granularity::Type{T}
) where {T <: Union{Dates.Period, Nothing}}
    freq = Symbol(GRANULARITY_MAP[granularity] * "_start")
    dropmissing!(stations, freq)
    if nrow(stations) == 0
        @warn "No weather stations found with requested granularity"
    end
end

"""
Filter weather stations by inventory data between two dates
"""
function filter_inventory!(
        stations,
        granularity::Type{T},
        period::Tuple{Dates.Date, Dates.Date}
) where {T <: Union{Dates.Period, Nothing}}
    freq = GRANULARITY_MAP[granularity]
    freq_start = Symbol(freq * "_start")
    freq_end = Symbol(freq * "_end")
    dropmissing!(stations, freq_start)
    subset!(stations,
        freq_start => ByRow(<=(period[1])),
        freq_end => ByRow(>=(period[2]))
    )
    if nrow(stations) == 0
        @warn "No weather stations found with requested granularity and time window"
    end
    return stations
end

"""
Filter weather stations by inventory data for a given day
"""
function filter_inventory!(
        stations,
        granularity::Type{T},
        date::Dates.Date
) where {T <: Union{Dates.Period, Nothing}}
    freq = GRANULARITY_MAP[granularity]
    freq_start = Symbol(freq * "_start")
    freq_end = Symbol(freq * "_end")
    dropmissing!(stations, freq_start)
    subset!(stations,
        freq_start => ByRow(<=(date)),
        freq_end => ByRow(>=(date))
    )
    if nrow(stations) == 0
        @warn "No weather stations found with requested granularity and date"
    end
    return stations
end

"""
Filter weather stations by altitude
"""
function filter_altitude!(
        stations; alt::Union{Float64, Nothing} = nothing, alt_range::Float64 = 350.0)
    if !isnothing(alt)
        subset!(stations, :elevation => ByRow(x -> abs(x - alt) <= alt_range))
    end
    if nrow(stations) == 0
        @warn "No weather stations found within requested altitude range"
    end
    return stations
end

"""
Score weather stations
"""
function score_values!(
        stations; radius::Float64 = 35_000.0, alt::Union{Float64, Nothing} = nothing,
        alt_range::Float64 = 350.0, weight_dist::Float64 = 0.6, weight_alt::Float64 = 0.4)
    if isnothing(alt)
        alt = mean(first(stations, 5).elevation)
    end

    transform!(stations,
        [:distance, :elevation]
        => ByRow(
        (distance, elevation) -> (
        (1 - (distance / radius)) * weight_dist
    ) + (
        (1 - (abs(alt - elevation) / alt_range))
        * weight_alt
    )
    )
        => :score
    )
    sort!(stations, :score, rev=true)
    return stations
end
