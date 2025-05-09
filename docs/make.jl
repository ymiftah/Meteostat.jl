using Documenter, Meteostat, Literate

# This code performs the automated addition of Literate - Generated Markdowns.
julia_file_filter = x -> occursin(".jl", x)
outputdir = joinpath(pwd(), "docs", "src", "examples")
files = filter(julia_file_filter, readdir(outputdir))

for file in files
    @show file
    inputfile = joinpath(outputdir, "$file")
    outputfile = replace("$file", ".jl" => "")

    Literate.markdown(
        inputfile,
        outputdir;
        name=outputfile,
        # credit = false,
        flavor=Literate.DocumenterFlavor(),
        # documenter = true,
        execute=true,
    )
end

makedocs(;
    sitename="Meteostat.jl",
    authors="Youssef Miftah",
    pages=[
        "Welcome Page" => "index.md",
        "Examples" => [
            "Query hourly weather data by geo coordinates" => "examples/point_data.md",
            "Query hourly weather data by station" => "examples/point_data_chart.md",
            "Closest weather station by coordinates" => "examples/nearby_stations.md",
            "Closest weather station by rectangular boundaries" => "examples/bounds_stations.md",
        ],
    ],
)

deploydocs(; repo="github.com/ymiftah/Meteostat.jl.git")
