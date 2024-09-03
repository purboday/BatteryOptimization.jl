using Revise
using  BatteryOptimization
using Dates
using DataFrames
using Plots

start_timestamp = DateTime("2023-06-01T00:00:00")
end_timestamp = DateTime("2023-06-05T0:00:00")
caiso_market = Market("CAISO", start_timestamp, end_timestamp)
battery = Battery(capacity_kwh=100, max_power_kw = 25)
result = run_simulation(start_timestamp, end_timestamp, caiso_market, battery)
soc_df = get_soc(battery.initial_soc, battery.capacity_kwh, result.power_schedule)

# Plot the results
fig1 = plot(
    result.power_schedule.date, 
    -result.power_schedule.power_kw,
    label = ["Power schedule"],
    xguide = "timestamp",
    yguide = "Power",
    legend = :topright,
    title = "Simulation Result",
    color = [:blue],
    linewidth = [2],
    )

plot!(
    fig1, result.power_schedule.date, 
    [get_price(caiso_market, timestamp = x) * 1000 for x in result.power_schedule.date],
    label = ["Prices"],
    xguide = "timestamp",
    yguide = "Price",
    legend = :topright,
    color = [:green],
    linestyle = [:dash],
    linewidth = [2],
)

fig2 = plot(
    soc_df.date, 
    soc_df.soc,
    label = ["Power schedule"],
    xguide = "timestamp",
    yguide = "SoC",
    legend = :topright,
    color = [:red],
    linewidth = [2],
    )

l = @layout [a;b]
plot(fig1, fig2; layout = l)