module BatteryOptimization
using Dates
using DataFrames
using JuMP
using HiGHS

include("Markets.jl")
include("Battery.jl")

export run_simulation, SimulationResult, get_soc, get_price

struct SimulationResult
    power_schedule::DataFrame
    objective_value::Real
end
"""
    construct_and_solve_problem(battery::Battery, prices::AbstractArray{<:Real})

Constructs a linear optimization problem for the battery charging/discharging and solves it.
It maximizes the total net revenue earned subject to battery power and state of charge constraints.
Returns a tuple of objective value and the solution variables.
"""
function construct_and_solve_problem(battery::Battery, prices::AbstractArray{<:Real})
    model = Model(HiGHS.Optimizer)
    n = length(prices) - 1
    l = ones(n) .* -battery.max_power_kw
    u = ones(n) .* battery.max_power_kw
    @variable(model, l[i] <= x[i=1:n] <= u[i])

    # add constraints
    # final soc shold be >= final_soc value
    @constraint(model, battery.capacity_kwh * (battery.final_soc - battery.initial_soc)
                       <=
                       sum(x[i] for i in 1:n))

    # # soc should be within the chosen limits
    for i in 1:n
        @constraint(model, (battery.min_soc - battery.initial_soc) * battery.capacity_kwh
                           <= sum(x[k] for k in 1:i) <= (battery.max_soc - battery.initial_soc) * battery.capacity_kwh)
    end

    # Since charging is represented as negative power flow, we need to minimize the costs
    @objective(model, Min, prices[1:n]' * x)

    optimize!(model)
    if !is_solved_and_feasible(model)
        error("Solver did not find an optimal solution")
    else
        println("Solution found. Objective value $(objective_value(model))")
        return objective_value(model), value.(x)
    end

end

"""
    run_simulation(start_timestamp::DateTime, end_timestamp::DateTime, market::Market, battery::Battery)
    
Simulate the optial operation of a battery in a given electricity market over a given period.
It solves an optiization problem to get the optimal power schedule and returns it along with the 
objective value in a struct SimulationResult.
"""
function run_simulation(start_timestamp::DateTime, end_timestamp::DateTime, market::Market, battery::Battery)
    println("Simulation running from $(start_timestamp) to $(end_timestamp)")
    simulation_range = start_timestamp:Hour(1):end_timestamp
    prices = [get_price(market, timestamp=timestamp) for timestamp in simulation_range]
    objective_value, power_schedule = construct_and_solve_problem(battery, prices)
    return SimulationResult(
        DataFrame(date=collect(simulation_range), power_kw=append!(power_schedule, 0.0)),
        objective_value
    )
end

"""
    get_soc(initial_soc::Real, capacity_kwh::Real, power_schedule::DataFrame)
Calculate and return the timeseries of state of charge (SoC) values given the initial SoC,
capacity and the power schedule. Returns a dataframe with twwo colummns, date and soc.
"""
function get_soc(initial_soc::Real, capacity_kwh::Real, power_schedule::DataFrame)
    timestamps = copy(power_schedule.date)
    soc = [initial_soc]
    append!(soc, initial_soc .+ cumsum(power_schedule.power_kw[1:end-1]) ./ capacity_kwh)
    return DataFrame(date=timestamps, soc=soc)
end

end