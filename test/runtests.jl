using BatteryOptimization
using BatteryOptimization.Dates
using BatteryOptimization.DataFrames
using Test

@testset "BatteryOptimization.jl" begin
    battery = Battery(capacity_kwh=100, max_power_kw=25)
    market = Market("CAISO", DateTime("2023-06-01T00:00:00"), DateTime("2023-06-01T03:00:00"))
    result = run_simulation(DateTime("2023-06-01T00:00:00"), DateTime("2023-06-01T03:00:00"), market, battery)
    @test length(result.power_schedule.power_kw) == 4
    @test result.objective_value isa Real
    @test all(result.power_schedule.power_kw .<= battery.max_power_kw)
    @test all(result.power_schedule.power_kw .>= -battery.max_power_kw)
    @test sum(result.power_schedule.power_kw) >= battery.capacity_kwh * (battery.final_soc - battery.initial_soc)
    @test all(get_soc(battery.initial_soc, battery.capacity_kwh, result.power_schedule).soc .<= battery.max_soc)
    @test all(get_soc(battery.initial_soc, battery.capacity_kwh, result.power_schedule).soc .>= battery.min_soc)
end

@testset "Markets.jl" begin
    @testset "Test Market $(iso)" for iso in ["CAISO", "ERCOT"]
        market = Market(iso, DateTime("2023-06-01T00:00:00"), DateTime("2023-06-01T03:00:00"))
        @test market.price_per_kwh isa DataFrame
        @test !isempty(market.price_per_kwh)
        @test all(market.price_per_kwh.date .>= DateTime("2023-05-31T23:00:00"))
        @test all(market.price_per_kwh.date .<= DateTime("2023-06-1T03:00:00"))
        @test get_price(market, timestamp=DateTime("2023-06-01T04:00:00")) == market.price_per_kwh[end, :price]
    end
    @test_throws ErrorException Market("XYZ", DateTime("2023-06-01T00:00:00"), DateTime("2023-06-1T03:00:00"))
end