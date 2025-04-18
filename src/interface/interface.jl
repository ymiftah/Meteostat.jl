@kwdef struct BaseInterface
    # Base URL of the Meteostat bulk data interface
    endpoint::String = "https://bulk.meteostat.net/v2/"
    cache_dir::String = joinpath(homedir(), ".meteostat", "cache") # Cache directory
    autoclean::Bool = true # Auto clean cache directories?
    max_age::Int = 24 * 60 * 60  # Maximum age of a cached file in seconds
    # # Number of processes used for processing files
    # processes:: Int = 1
    # # Number of threads used for processing files
    # threads:: Int = 1
end

@kwdef struct Point
    lat::Float64
    lon::Float64
    alt::Union{Float64, Nothing} = nothing
end

Point(lat, lon) = Point(lat=lat, lon=lon)