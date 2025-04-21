using Documenter, Meteostat, Literate

makedocs(
    sitename="Meteostat.jl",
    # modules = [Meteostat],
    remotes = nothing,
    authors = "Youssef Miftah",
    pages=[
        "Welcome Page" => "index.md",
        "Examples" => [
            "Query hourly weather data by geo coordinates" => "examples/point_data.md",
        ]
    ]
    )