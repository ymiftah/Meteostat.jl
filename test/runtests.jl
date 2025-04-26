using Test
using TestItems

using Meteostat

@testitem "Test utilities - Data processing" begin
    using Dates
    using DataFrames: DataFrame
    @test Meteostat.get_distance(130, 48, 120, 35) ≈ 1.3818349744525773e6

    # should decrease temperatures by 1000 * 0.6 = 6*C
    @test Meteostat.adjust_temp!(DataFrame(; temp=[1.0, 2.0, 3.0]), 1000.0, 0.0) ==
        DataFrame(; temp=[-5.0, -4.0, -3.0])

    # No adjustment if altitude is missing
    @test Meteostat.adjust_temp!(DataFrame(; temp=[1.0, 2.0, 3.0]), nothing, 0.0) ==
        DataFrame(; temp=[1.0, 2.0, 3.0])

    time_table = DataFrame(;
        time=Dates.Date(2014, 1, 29):Dates.Day(1):Dates.Date(2014, 2, 3)
    )
    @test Meteostat.filter_time!(
        time_table, Dates.Date(2014, 1, 29), Dates.Date(2014, 1, 31)
    ) == DataFrame(; time=Dates.Date(2014, 1, 29):Dates.Day(1):Dates.Date(2014, 1, 31))

    @test Meteostat.degree_mean([35, 36, 37]) == 36
    @test ismissing(Meteostat.degree_mean([missing, missing]))
    @test Meteostat.degree_mean([35, missing]) == 35
end

@testitem "Test utilities - Endpoint paths" begin
    using Dates
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
end

@testitem "Aqua.jl" begin
    using Aqua
    Aqua.test_all(Meteostat)
end
