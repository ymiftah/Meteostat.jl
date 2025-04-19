using Test
using TestItems

using Meteostat: Meteostat
using Dates: Dates
using DataFrames: DataFrame

@testitem "Test utilities" begin
    year = 2024
    @test_throws "Hourly granularity requested, but no year was specified." Meteostat.generate_endpoint_path(
        "foo"; granularity=Dates.Hour
    )
    @test Meteostat.generate_endpoint_path("foo"; granularity=Dates.Hour, year=year) ==
        "hourly/$year/foo.csv.gz"
    @test Meteostat.generate_endpoint_path("foo"; granularity=Dates.Day) ==
        "daily/foo.csv.gz"
    @test Meteostat.generate_endpoint_path("foo"; granularity=Dates.Month) ==
        "monthly/foo.csv.gz"
    @test Meteostat.generate_endpoint_path("foo") == "normals/foo.csv.gz"

    @test Meteostat.get_distance(130, 48, 120, 35) ≈ 1.3818349744525773e6

    @test Meteostat.adjust_temp!(
        DataFrame(; temp=[1.0, 2.0, 3.0]), 1000., 0.
    ) == DataFrame(; temp=[601.0, 602.0, 603.0])

    time_table = DataFrame(;
        time=Dates.Date(2014, 1, 29):Dates.Day(1):Dates.Date(2014, 2, 3)
    )
    @test Meteostat.filter_time!(
        time_table, Dates.Date(2014, 1, 29), Dates.Date(2014, 1, 31)
    ) == DataFrame(; time=Dates.Date(2014, 1, 29):Dates.Day(1):Dates.Date(2014, 1, 31))

    @test Meteostat.degree_mean([35, 36, 37]) == 36
    @test ismissing(Meteostat.degree_mean([missing, missing]))
end
