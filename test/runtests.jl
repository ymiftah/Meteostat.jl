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
    ) == DataFrame(; time=Dates.Date(2014, 1, 29):Dates.Day(1):Dates.Date(2014, 1, 30))

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

@testitem "Test stations" begin
    # Get data for some day at Frankfurt Airport
    stations = get_stations();
    @test size(stations, 1) > 0
end

@testitem "Test Hourly" begin
    # Get data for some day at Frankfurt Airport
    using Dates
    data = fetch_data("10637", Hour, Date(2018, 1, 1), Date(2018, 1, 2))
    @test size(data, 1) == 24
end

@testitem "Test Daily" begin
    # Get data for some day at Frankfurt Airport
    using Dates
    data = fetch_data("10637", Day, Date(2018, 1, 1), Date(2018, 1, 5))
    @test size(data, 1) == 4
end

@testitem "Test Monthly" begin
    # Get data for some day at Frankfurt Airport
    using Dates
    data = fetch_data("10637", Month, Date(2018, 1, 1), Date(2018, 9, 1))
    @test size(data, 1) == 8
end

@testitem "Test Point" begin
    using Dates
    # Create Point for Vancouver, BC
    point = Point(49.2497, -123.1193, 70.0)

    # Get count of weather stations
    stations = get_stations(point, Hour, Date(2020, 1, 1), Date(2020, 1, 31))

    # Check if the stations are returned
    @test size(stations, 1) == 10
end
