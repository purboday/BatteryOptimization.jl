using DataFrames
using Dates
using CSV

export Market, get_price

function load_caiso_prices()
    dfmt = dateformat"mm/dd/yyyy HH:MM:SS p"
    price_per_mwh = DataFrame(CSV.File("src/data/20230101-20240101 CAISO Average Price.csv"; dateformat=dfmt))
    price_per_kwh = transform(price_per_mwh, :price => (x -> x * 0.001) => :price)
    return price_per_kwh
end

function load_ercot_prices()
    dfmt = dateformat"mm/dd/yyyy HH:MM:SS p"
    price_per_mwh = DataFrame(CSV.File("src/data/20230101-20240101 ERCOT Real-time Price.csv"; dateformat=dfmt))
    price_per_kwh = transform(price_per_mwh, :price => (x -> x * 0.001) => :price)
    price_per_kwh = price_per_kwh[price_per_kwh.zone.=="LZ_HOUSTON", :]
    price_per_kwh = price_per_kwh[:, [:date, :price]]
    return price_per_kwh
end

"""
struct reprresenting a market. It is initailied y specifying an ISO and the start_timestamp and end_tiemstamp
DateTime values. Uses a custo constructor to set the price_per_kwh by loading for a local file, truncating
and scaling it.
"""
struct Market
    iso::String
    price_per_kwh::DataFrame

    function Market(iso::String, start_timestamp::DateTime, end_tiemstamp::DateTime)
        if iso == "CAISO"
            # get caiso prices
            price_per_kwh = load_caiso_prices()
        elseif iso == "ERCOT"
            # get ercot prices
            price_per_kwh = load_ercot_prices()
        else
            error("$(iso) is not supported")
        end
        price_per_kwh = price_per_kwh[start_timestamp-Dates.Hour(1).<=price_per_kwh.date.<=end_tiemstamp, :]
        return new(iso, price_per_kwh)
    end
end

"""
    get_price(market::Market; timestamp::DateTime)
Get the last known price for a timestamp.
"""
function get_price(market::Market; timestamp::DateTime)
    prices = market.price_per_kwh[market.price_per_kwh.date.<=timestamp, :]
    return prices[end, :price]
end