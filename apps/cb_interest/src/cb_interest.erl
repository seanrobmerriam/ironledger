-module(cb_interest).

-include("cb_interest.hrl").

-export([
    calculate_daily_rate/1,
    calculate_interest/3,
    calculate_compound_interest/4,
    basis_points_to_float/1,
    float_to_basis_points/1
]).

-define(DAYS_IN_YEAR, 365).
-define(BASIS_POINTS_FACTOR, 10000).

-spec calculate_daily_rate(interest_rate()) -> interest_rate().
calculate_daily_rate(AnnualRate) when is_float(AnnualRate), AnnualRate >= 0 ->
    AnnualRate / ?DAYS_IN_YEAR.

-spec calculate_interest(non_neg_integer(), interest_rate(), non_neg_integer()) -> non_neg_integer().
calculate_interest(Balance, DailyRate, Days) when is_integer(Balance), is_float(DailyRate), is_integer(Days), Balance >= 0, Days >= 0 ->
    DailyRateDecimal = DailyRate / 100,
    Interest = (Balance * DailyRateDecimal * Days),
    trunc(Interest).

-spec calculate_compound_interest(non_neg_integer(), interest_rate(), non_neg_integer(), compounding_period()) -> non_neg_integer().
calculate_compound_interest(InitialBalance, AnnualRate, Days, CompoundingPeriod) when is_integer(InitialBalance), is_float(AnnualRate), is_integer(Days), Days >= 0, InitialBalance >= 0 ->
    DailyRate = calculate_daily_rate(AnnualRate),
    case CompoundingPeriod of
        daily ->
            calculate_daily_compound(InitialBalance, DailyRate, Days);
        monthly ->
            DaysInMonth = 30,
            calculate_period_compound(InitialBalance, DailyRate, Days, DaysInMonth);
        quarterly ->
            DaysInQuarter = 91,
            calculate_period_compound(InitialBalance, DailyRate, Days, DaysInQuarter);
        annually ->
            DaysInYear = ?DAYS_IN_YEAR,
            calculate_period_compound(InitialBalance, DailyRate, Days, DaysInYear)
    end.

-spec basis_points_to_float(non_neg_integer()) -> interest_rate().
basis_points_to_float(Bps) when is_integer(Bps), Bps >= 0 ->
    Bps / ?BASIS_POINTS_FACTOR.

-spec float_to_basis_points(interest_rate()) -> non_neg_integer().
float_to_basis_points(Rate) when is_float(Rate), Rate >= 0 ->
    round(Rate * ?BASIS_POINTS_FACTOR).

-spec calculate_daily_compound(non_neg_integer(), interest_rate(), non_neg_integer()) -> non_neg_integer().
calculate_daily_compound(Principal, _DailyRate, 0) ->
    Principal;
calculate_daily_compound(Principal, DailyRate, Days) when Days > 0 ->
    DailyRateDecimal = DailyRate / 100,
    NewBalance = trunc(Principal * (1 + DailyRateDecimal)),
    calculate_daily_compound(NewBalance, DailyRate, Days - 1).

-spec calculate_period_compound(non_neg_integer(), interest_rate(), non_neg_integer(), pos_integer()) -> non_neg_integer().
calculate_period_compound(Principal, _DailyRate, 0, _PeriodDays) ->
    Principal;
calculate_period_compound(Principal, DailyRate, Days, PeriodDays) when Days > 0, PeriodDays > 0 ->
    DailyRateDecimal = DailyRate / 100,
    PeriodRate = DailyRateDecimal * PeriodDays,
    NewBalance = trunc(Principal * (1 + PeriodRate)),
    calculate_period_compound(NewBalance, DailyRate, Days - PeriodDays, PeriodDays).
