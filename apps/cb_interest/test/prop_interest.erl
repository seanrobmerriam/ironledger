-module(prop_interest).

-include_lib("proper/include/proper.hrl").

-export([
    prop_zero_rate_produces_zero_interest/0,
    prop_daily_rate_is_monotonic/0,
    prop_compound_interest_never_below_principal/0
]).

-spec prop_zero_rate_produces_zero_interest() -> term().
prop_zero_rate_produces_zero_interest() ->
    ?FORALL({Balance, Days}, {range(0, 1000000), range(0, 3650)},
        begin
            DailyRate = cb_interest:calculate_daily_rate(0),
            0 =:= cb_interest:calculate_interest(Balance, DailyRate, Days)
        end
    ).

-spec prop_daily_rate_is_monotonic() -> term().
prop_daily_rate_is_monotonic() ->
    ?FORALL({RateA, RateB}, {range(0, 10000), range(0, 10000)},
        begin
            DailyA = cb_interest:calculate_daily_rate(RateA),
            DailyB = cb_interest:calculate_daily_rate(RateB),
            case RateA =< RateB of
                true -> DailyA =< DailyB;
                false -> DailyA >= DailyB
            end
        end
    ).

-spec prop_compound_interest_never_below_principal() -> term().
prop_compound_interest_never_below_principal() ->
    ?FORALL({Balance, Rate, Days, Period},
        {range(0, 1000000), range(0, 10000), range(0, 3650), compounding_period()},
        cb_interest:calculate_compound_interest(Balance, Rate, Days, Period) >= Balance
    ).

compounding_period() ->
    elements([daily, monthly, quarterly, annually]).
