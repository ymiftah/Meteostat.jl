"""Schema of the stations dataframe"""
const STATIONS_SCHEMA = OrderedDict(
    :id => String => "The Meteostat ID of the weather station",
    :name => String => "The English name of the weather station",
    :country => String => "The ISO 3166-1 alpha-2 country code of the weather station",
    :region => String => "The ISO 3166-2 state or region code of the weather station",
    :wmo => String => "The WMO ID of the weather station",
    :icao => String => "The ICAO ID of the weather station",
    :latitude => Float64 => "The latitude of the weather station in degrees",
    :longitude => Float64 => "The longitude of the weather station in degrees",
    :elevation =>
        Float64 => "The elevation of the weather station in meters above sea level",
    :timezone => String => "The time zone of the weather station",
    :hourly_start => Dates.Date => "The first day on record for hourly data",
    :hourly_end => Dates.Date => "The last day on record for hourly data",
    :daily_start => Dates.Date => "The first day on record for daily data",
    :daily_end => Dates.Date => "The last day on record for daily data",
    :monthly_start => Dates.Date => "The first day on record for monthly data",
    :monthly_end => Dates.Date => "The last day on record for monthly data",
)

"""
    get_stations()

Reads all stations
"""
function get_stations()
    endpoint = "https://bulk.meteostat.net/v2/stations/slim.csv.gz"
    path = load_handler(endpoint, "stations.csv.gz")
    df = CSV.read(
        path,
        DataFrame;
        header=collect(keys(STATIONS_SCHEMA)),
        types=collect((x -> x.first).(values(STATIONS_SCHEMA))),
        dateformat="yyyy-mm-dd",
    )
    for (col, values) in STATIONS_SCHEMA
        metadata = values.second
        if !isnothing(metadata)
            colmetadata!(df, col, "label", metadata; style=:note)
        end
    end
    return df
end

"""
    get_stations(point::Point; radius::Union{Float64,Nothing}=35_000.0)

Reads all stations within radius distance of the point
"""
function get_stations(point::Point; radius::Union{Float64,Nothing}=35_000.0)
    lat = point.lat
    lon = point.lon
    alt = point.alt
    stations = get_stations()
    filter_nearby!(stations, lat, lon; radius=radius)
    _score_values!(stations; radius=radius, alt=alt)
    return stations
end
"""
    get_stations(lat, lon; radius::Union{Float64,Nothing}=35_000.0)

Reads all stations within radius distance of the point
"""
function get_stations(lat, lon; radius::Union{Float64,Nothing}=35_000.0)
    point = Point(; lat=lat, lon=lon)
    stations = get_stations(point; radius=radius)
    return stations
end

"""
    get_stations(point::Point, granularity::Type{T}; radius::Union{Float64,Nothing}=35_000.0) where {T<:Dates.Period}

Reads all stations within radius distance of the point and where data is available for the requested granularity
"""
function get_stations(
    point::Point, granularity::Type{T}; radius::Union{Float64,Nothing}=35_000.0
) where {T<:Dates.Period}
    stations = get_stations(point; radius=radius)
    filter_inventory!(stations, granularity)
    _score_values!(stations; radius=radius, alt=point.alt)
    return stations
end

"""
    get_stations(
        point::Point,
        granularity::Type{T},
        start_date::Dates.Date,
        end_date::Dates.Date;
        radius::Union{Float64,Nothing}=35_000.0,
    )

Reads all stations within radius distance of the point and where data is available for the requested granularity and date range
"""
function get_stations(
    point::Point,
    granularity::Type{T},
    start_date::Dates.Date,
    end_date::Dates.Date;
    radius::Union{Float64,Nothing}=35_000.0,
) where {T<:Dates.Period}
    stations = get_stations(point; radius=radius)
    filter_inventory!(stations, granularity, (start_date, end_date))
    _score_values!(stations; radius=radius, alt=point.alt)
    return stations
end

# Filters

"""
    filter_nearby!(
        stations, lat::Float64, lon::Float64; radius::Union{Float64,Nothing}=nothing
    )
Sort/filter weather stations by physical distance
"""
function filter_nearby!(
    stations, lat::Float64, lon::Float64; radius::Union{Float64,Nothing}=nothing
)
    dropmissing!(stations, [:latitude, :longitude])
    transform!(
        stations,
        [:latitude, :longitude] =>
            ByRow((x, y) -> get_distance(x, y, lat, lon)) => :distance,
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
    filter_region!(
        stations; country::Union{String,Nothing}=nothing, state::Union{String,Nothing}=nothing
    )
    
Filter weather stations by country/region code
"""
function filter_region!(
    stations; country::Union{String,Nothing}=nothing, state::Union{String,Nothing}=nothing
)
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
    filter_bounds!(
        stations, top_left::Tuple{Float64,Float64}, bottom_right::Tuple{Float64,Float64}
    )

Filter weather stations by geographical bounds
"""
function filter_bounds!(
    stations, top_left::Tuple{Float64,Float64}, bottom_right::Tuple{Float64,Float64}
)
    # Return stations in boundaries
    dropmissing!(stations, [:latitude, :longitude])
    subset!(
        stations,
        :latitude => ByRow(<=(top_left[1])),
        :latitude => ByRow(>=(bottom_right[1])),
        :longitude => ByRow(>=(top_left[2])),
        :longitude => ByRow(<=(bottom_right[2])),
    )
    if nrow(stations) == 0
        @warn "No weather stations found within bounds"
    end
    return stations
end

"""
    filter_inventory!(stations, granularity::Type{T}) where {T<:Union{Dates.Period,Nothing}}

Filter weather stations by inventory data (pass `nothing` for normals)
"""
function filter_inventory!(
    stations, granularity::Type{T}
) where {T<:Union{Dates.Period,Nothing}}
    freq = Symbol(GRANULARITY_MAP[granularity] * "_start")
    dropmissing!(stations, freq)
    if nrow(stations) == 0
        @warn "No weather stations found with requested granularity"
    end
    return stations
end

"""
    function filter_inventory!(
        stations, granularity::Type{T}, period::Tuple{Dates.Date,Dates.Date}
    )

Filter weather stations by inventory data between two dates (pass `nothing` for normals)
"""
function filter_inventory!(
    stations, granularity::Type{T}, period::Tuple{Dates.Date,Dates.Date}
) where {T<:Union{Dates.Period,Nothing}}
    freq = GRANULARITY_MAP[granularity]
    freq_start = Symbol(freq * "_start")
    freq_end = Symbol(freq * "_end")
    @info freq_end
    dropmissing!(stations, freq_start)
    subset!(stations, freq_start => ByRow(<=(period[1])), freq_end => ByRow(>=(period[2])))
    if nrow(stations) == 0
        @warn "No weather stations found with requested granularity and time window"
    end
    return stations
end

"""
    function filter_inventory!(
        stations, granularity::Type{T}, date::Dates.Date
    )

Filter weather stations by inventory data for a given day  (pass `nothing` for normals)
"""
function filter_inventory!(
    stations, granularity::Type{T}, date::Dates.Date
) where {T<:Union{Dates.Period,Nothing}}
    freq = GRANULARITY_MAP[granularity]
    freq_start = Symbol(freq * "_start")
    freq_end = Symbol(freq * "_end")
    dropmissing!(stations, freq_start)
    subset!(stations, freq_start => ByRow(<=(date)), freq_end => ByRow(>=(date)))
    if nrow(stations) == 0
        @warn "No weather stations found with requested granularity and date"
    end
    return stations
end

"""
    filter_altitude!(
        stations; alt::Union{Float64,Nothing}=nothing, alt_range::Float64=350.0
    )

Filter weather stations by altitude
"""
function filter_altitude!(
    stations; alt::Union{Float64,Nothing}=nothing, alt_range::Float64=350.0
)
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
function _score_values!(
    stations;
    radius::Float64=35_000.0,
    alt::Union{Float64,Nothing}=nothing,
    alt_range::Float64=350.0,
    weight_dist::Float64=0.6,
    weight_alt::Float64=0.4,
)
    if isnothing(alt)
        alt = mean(first(stations, 5).elevation)
    end

    transform!(
        stations,
        [:distance, :elevation] =>
            ByRow(
                (distance, elevation) ->
                    ((1 - (distance / radius)) * weight_dist) +
                    ((1 - (abs(alt - elevation) / alt_range)) * weight_alt),
            ) => :score,
    )
    sort!(stations, :score; rev=true)
    return stations
end
