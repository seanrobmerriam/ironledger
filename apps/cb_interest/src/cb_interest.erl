%%%
%%% @doc Pure interest calculation functions for IronLedger core banking system.
%%%
%%% This module provides the core mathematical functions for calculating interest
%%% on bank accounts. All functions are pure and stateless, making them easy to
%%% test and reason about.
%%%
%%% == Key Concepts ==
%%%
%%% <b>Daily Rate</b>: The daily interest rate is calculated by dividing the annual
%%% interest rate by 365 (or 366 in leap years). This is the fundamental rate
%%% used for daily interest accrual in most banking systems.
%%%
%%% <b>Simple Interest</b>: Calculated using the formula:
%%% <pre>
%%%   Interest = Principal × Daily Rate × Number of Days
%%% </pre>
%%%
%%% <b>Compound Interest</b>: Interest is calculated on the principal plus
%%% previously accumulated interest. The effect of compounding is that money
%%% grows faster over time compared to simple interest.
%%%
%%% <b>Basis Points</b>: Financial industry standard for expressing interest rates.
%%% 1 basis point = 0.01% = 0.0001 in decimal form.
%%% 100 basis points = 1%
%%% 10,000 basis points = 100%
%%%
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

%%%
%%% @doc Calculate the daily interest rate from an annual interest rate.
%%%
%%% Divides the annual rate by 365 to get the daily rate. This daily rate
%%% is used for calculating interest accruals on a day-by-day basis.
%%%
%%% @param AnnualRate The annual interest rate as a decimal (e.g., 0.05 for 5% APR)
%%% @returns The daily interest rate as a decimal
%%%
-spec calculate_daily_rate(interest_rate()) -> interest_rate().
calculate_daily_rate(AnnualRate) when is_float(AnnualRate), AnnualRate >= 0 ->
    AnnualRate / ?DAYS_IN_YEAR.

%%%
%%% @doc Calculate simple interest for a given balance, rate, and number of days.
%%%
%%% This is the standard simple interest formula used in banking:
%%% <pre>
%%%   Interest = Balance × (DailyRate / 100) × Days
%%% </pre>
%%%
%%% Note: The result is truncated to an integer since all monetary amounts
%%% in IronLedger are stored in minor units (cents, pence, etc.).
%%%
%%% @param Balance The principal balance in minor units (e.g., cents)
%%% @param DailyRate The daily interest rate as a decimal
%%% @param Days The number of days to calculate interest for
%%% @returns The calculated interest amount in minor units
%%%
-spec calculate_interest(non_neg_integer(), interest_rate(), non_neg_integer()) -> non_neg_integer().
calculate_interest(Balance, DailyRate, Days) when is_integer(Balance), is_float(DailyRate), is_integer(Days), Balance >= 0, Days >= 0 ->
    DailyRateDecimal = DailyRate / 100,
    Interest = (Balance * DailyRateDecimal * Days),
    trunc(Interest).

%%%
%%% @doc Calculate compound interest with a specified compounding period.
%%%
%%% Compound interest differs from simple interest in that interest is earned
%%% on previously accumulated interest. For example, with monthly compounding:
%%% <ul>
%%% <li>Month 1: Interest on principal is added to balance</li>
%%% <li>Month 2: Interest is calculated on (principal + month 1 interest)</li>
%%% <li>And so on...</li>
%%% </ul>
%%%
%%% The more frequent the compounding, the higher the effective Annual Percentage
%%% Yield (APY) for savings accounts, or the more interest charged for loans.
%%%
%%% @param InitialBalance The starting balance in minor units
%%% @param AnnualRate The annual interest rate as a decimal
%%% @param Days Total number of days to calculate interest
%%% @param CompoundingPeriod How often interest compounds (daily, monthly, quarterly, annually)
%%% @returns The final balance including compound interest in minor units
%%%
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

%%%
%%% @doc Convert basis points to a floating-point interest rate.
%%%
%%% Basis points (bps) are the standard unit for expressing interest rate changes
%%% in banking. This function converts from bps to decimal form.
%%%
%%% Examples:
%%% <ul>
%%% <li>250 bps = 0.025 (2.5%)</li>
%%% <li>5000 bps = 0.50 (50%)</li>
%%% <li>100 bps = 0.01 (1%)</li>
%%% </ul>
%%%
%%% @param Bps The interest rate in basis points (1 bp = 0.01%)
%%% @returns The interest rate as a decimal (e.g., 0.05 for 5%)
%%%
-spec basis_points_to_float(non_neg_integer()) -> interest_rate().
basis_points_to_float(Bps) when is_integer(Bps), Bps >= 0 ->
    Bps / ?BASIS_POINTS_FACTOR.

%%%
%%% @doc Convert a floating-point interest rate to basis points.
%%%
%%% This is the inverse of basis_points_to_float/1. It converts a decimal
%%% interest rate to the integer basis points representation.
%%%
%%% Examples:
%%% <ul>
%%% <li>0.025 = 250 bps (2.5%)</li>
%%% <li>0.50 = 5000 bps (50%)</li>
%%% <li>0.01 = 100 bps (1%)</li>
%%% </ul>
%%%
%%% @param Rate The interest rate as a decimal (e.g., 0.05 for 5%)
%%% @returns The interest rate in basis points
%%%
-spec float_to_basis_points(interest_rate()) -> non_neg_integer().
float_to_basis_points(Rate) when is_float(Rate), Rate >= 0 ->
    round(Rate * ?BASIS_POINTS_FACTOR).

%%%
%%% @doc Calculate compound interest with daily compounding.
%%%
%%% This is the most frequent compounding available, providing the highest
%%% effective yield for savings accounts. Each day, interest is calculated
%%% on the current balance (which includes all previously earned interest).
%%%
%%% @param Principal The current balance in minor units
%%% @param DailyRate The daily interest rate as a decimal
%%% @param Days Number of days to compound
%%% @returns The final balance after compounding in minor units
%%%
-spec calculate_daily_compound(non_neg_integer(), interest_rate(), non_neg_integer()) -> non_neg_integer().
calculate_daily_compound(Principal, _DailyRate, 0) ->
    Principal;
calculate_daily_compound(Principal, DailyRate, Days) when Days > 0 ->
    DailyRateDecimal = DailyRate / 100,
    NewBalance = trunc(Principal * (1 + DailyRateDecimal)),
    calculate_daily_compound(NewBalance, DailyRate, Days - 1).

%%%
%%% @doc Calculate compound interest with periodic compounding (monthly, quarterly, or annually).
%%%
%%% Unlike daily compounding which calculates every day, this function calculates
%%% interest only at the end of each compounding period.
%%%
%%% @param Principal The current balance in minor units
%%% @param DailyRate The daily interest rate as a decimal
%%% @param Days Total number of days
%%% @param PeriodDays Number of days in each compounding period (30=monthly, 91=quarterly, 365=annually)
%%% @returns The final balance after periodic compounding in minor units
%%%
-spec calculate_period_compound(non_neg_integer(), interest_rate(), non_neg_integer(), pos_integer()) -> non_neg_integer().
calculate_period_compound(Principal, _DailyRate, 0, _PeriodDays) ->
    Principal;
calculate_period_compound(Principal, DailyRate, Days, PeriodDays) when Days > 0, PeriodDays > 0 ->
    DailyRateDecimal = DailyRate / 100,
    PeriodRate = DailyRateDecimal * PeriodDays,
    NewBalance = trunc(Principal * (1 + PeriodRate)),
    calculate_period_compound(NewBalance, DailyRate, Days - PeriodDays, PeriodDays).
