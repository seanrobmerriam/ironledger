%%%===================================================================
%%%
%%% @doc Loan calculation functions using integer basis-point arithmetic.
%%%
%%% All annual rates are expressed in basis points. Monetary calculations remain
%%% in integer minor units throughout.
%%%
%%%===================================================================

-module(cb_loan_calculations).
-include("loan.hrl").
-include_lib("cb_ledger/include/cb_ledger.hrl").

-export([
         calculate_monthly_payment/3,
         calculate_total_interest/3,
         calculate_principal_portion/3,
         calculate_interest_portion/3,
         calculate_flat_interest/3,
         calculate_outstanding_balance/3
        ]).

-define(MAX_AMOUNT, 9999999999999).
-define(MONTHS_PER_YEAR, 12).
-define(BPS_FACTOR, 10000).
-define(MONTHLY_RATE_DIVISOR, ?MONTHS_PER_YEAR * ?BPS_FACTOR).

-spec calculate_monthly_payment(amount(), integer(), non_neg_integer()) ->
    {ok, amount()} | {error, atom()}.
calculate_monthly_payment(Principal, TermMonths, AnnualRateBps) ->
    case validate_loan_params(Principal, TermMonths, AnnualRateBps) of
        ok ->
            {ok, do_calculate_amortizing_payment(Principal, TermMonths, AnnualRateBps)};
        Error ->
            Error
    end.

-spec calculate_total_interest(amount(), integer(), non_neg_integer()) ->
    {ok, amount()} | {error, atom()}.
calculate_total_interest(Principal, TermMonths, AnnualRateBps) ->
    case calculate_monthly_payment(Principal, TermMonths, AnnualRateBps) of
        {ok, MonthlyPayment} ->
            {ok, (MonthlyPayment * TermMonths) - Principal};
        Error ->
            Error
    end.

-spec calculate_principal_portion(amount(), amount(), amount()) -> amount().
calculate_principal_portion(TotalPayment, InterestPortion, _OutstandingBalance) ->
    max(0, TotalPayment - InterestPortion).

-spec calculate_interest_portion(amount(), amount(), non_neg_integer()) -> amount().
calculate_interest_portion(OutstandingBalance, _MonthlyPayment, AnnualRateBps) ->
    round_div(OutstandingBalance * AnnualRateBps, ?MONTHLY_RATE_DIVISOR).

-spec calculate_flat_interest(amount(), integer(), non_neg_integer()) -> amount().
calculate_flat_interest(Principal, TermMonths, AnnualRateBps) ->
    round_div(Principal * AnnualRateBps * TermMonths, ?MONTHLY_RATE_DIVISOR).

-spec calculate_outstanding_balance(amount(), amount(), amount()) -> amount().
calculate_outstanding_balance(Principal, TotalPaid, _PrincipalPortion) ->
    max(0, Principal - TotalPaid).

-spec do_calculate_amortizing_payment(amount(), pos_integer(), non_neg_integer()) -> amount().
do_calculate_amortizing_payment(Principal, TermMonths, 0) ->
    ceil_div(Principal, TermMonths);
do_calculate_amortizing_payment(Principal, TermMonths, AnnualRateBps) ->
    LowerBound = ceil_div(Principal, TermMonths),
    UpperBound = max(LowerBound, Principal + calculate_flat_interest(Principal, TermMonths, AnnualRateBps)),
    find_min_payment(LowerBound, UpperBound, Principal, TermMonths, AnnualRateBps).

-spec find_min_payment(amount(), amount(), amount(), pos_integer(), non_neg_integer()) -> amount().
find_min_payment(Low, High, _Principal, _TermMonths, _AnnualRateBps) when Low >= High ->
    Low;
find_min_payment(Low, High, Principal, TermMonths, AnnualRateBps) ->
    Mid = (Low + High) div 2,
    case payment_clears_balance(Principal, Mid, TermMonths, AnnualRateBps) of
        true ->
            find_min_payment(Low, Mid, Principal, TermMonths, AnnualRateBps);
        false ->
            find_min_payment(Mid + 1, High, Principal, TermMonths, AnnualRateBps)
    end.

-spec payment_clears_balance(amount(), amount(), pos_integer(), non_neg_integer()) -> boolean().
payment_clears_balance(Principal, Payment, TermMonths, AnnualRateBps) ->
    simulate_balance(Principal, Payment, TermMonths, AnnualRateBps) =:= 0.

-spec simulate_balance(amount(), amount(), non_neg_integer(), non_neg_integer()) -> amount().
simulate_balance(Balance, _Payment, 0, _AnnualRateBps) ->
    Balance;
simulate_balance(Balance, Payment, MonthsRemaining, AnnualRateBps) ->
    InterestPortion = calculate_interest_portion(Balance, Payment, AnnualRateBps),
    PrincipalPortion = max(0, Payment - InterestPortion),
    NewBalance = max(0, Balance - PrincipalPortion),
    simulate_balance(NewBalance, Payment, MonthsRemaining - 1, AnnualRateBps).

-spec ceil_div(non_neg_integer(), pos_integer()) -> non_neg_integer().
ceil_div(Numerator, Denominator) ->
    (Numerator + Denominator - 1) div Denominator.

-spec round_div(non_neg_integer(), pos_integer()) -> non_neg_integer().
round_div(Numerator, Denominator) ->
    (Numerator + (Denominator div 2)) div Denominator.

-spec validate_loan_params(amount(), integer(), integer()) -> ok | {error, atom()}.
validate_loan_params(Principal, TermMonths, AnnualRateBps) ->
    case Principal of
        P when P =< 0 -> {error, invalid_amount};
        P when P > ?MAX_AMOUNT -> {error, amount_overflow};
        _ ->
            case TermMonths of
                T when T =< 0 -> {error, invalid_term};
                T when T > 360 -> {error, term_too_long};
                _ ->
                    case AnnualRateBps of
                        R when not is_integer(R) -> {error, invalid_interest_rate};
                        R when R < 0 -> {error, invalid_interest_rate};
                        R when R > ?BPS_FACTOR -> {error, interest_rate_too_high};
                        _ -> ok
                    end
            end
    end.
