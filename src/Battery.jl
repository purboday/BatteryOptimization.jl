export Battery
Base.@kwdef struct Battery
    final_soc::Real = 0.5
    initial_soc::Real = 0.9
    max_soc::Real = 0.9
    min_soc::Real = 0.1
    capacity_kwh::Real = 30
    max_power_kw::Real = 6
end
