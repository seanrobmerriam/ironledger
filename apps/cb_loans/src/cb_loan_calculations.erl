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

-spec calculate_monthly_payment(amount(), integer(), float()) ->
    {ok, amount()} | {error, term()}.
calculate_monthly_payment(Principal, TermMonths, AnnualRate) ->
    case validate_loan_params(Principal, TermMonths, AnnualRate) of
        ok ->
            MonthlyRate = AnnualRate / ?MONTHS_PER_YEAR,
            Payment = do_calculate_amortizing_payment(Principal, TermMonths, MonthlyRate),
            {ok, Payment};
        Error ->
            Error
    end.

-spec calculate_total_interest(amount(), integer(), float()) ->
    {ok, amount()} | {error, term()}.
calculate_total_interest(Principal, TermMonths, AnnualRate) ->
    case validate_loan_params(Principal, TermMonths, AnnualRate) of
        ok ->
            {ok, MonthlyPayment} = calculate_monthly_payment(Principal, TermMonths, AnnualRate),
            TotalPayments = MonthlyPayment * TermMonths,
            TotalInterest = TotalPayments - Principal,
            {ok, TotalInterest};
        Error ->
            Error
    end.

-spec calculate_principal_portion(amount(), amount(), amount()) -> amount().
calculate_principal_portion(TotalPayment, InterestPortion, _OutstandingBalance) ->
    max(0, TotalPayment - InterestPortion).

-spec calculate_interest_portion(amount(), amount(), float()) -> amount().
calculate_interest_portion(OutstandingBalance, _MonthlyPayment, AnnualRate) ->
    MonthlyRate = AnnualRate / ?MONTHS_PER_YEAR,
    erlang:round(OutstandingBalance * MonthlyRate).

-spec calculate_flat_interest(amount(), integer(), float()) -> amount().
calculate_flat_interest(Principal, TermMonths, AnnualRate) ->
    erlang:round(Principal * AnnualRate * TermMonths / ?MONTHS_PER_YEAR).

-spec calculate_outstanding_balance(amount(), amount(), amount()) -> amount().
calculate_outstanding_balance(Principal, TotalPaid, _PrincipalPortion) ->
    max(0, Principal - TotalPaid).

do_calculate_amortizing_payment(Principal, TermMonths, MonthlyRate) ->
    case MonthlyRate of
        +0.0 ->
            erlang:round(Principal / TermMonths);
        _ ->
            RateFactor = math:pow(1 + MonthlyRate, TermMonths),
            Payment = Principal * (MonthlyRate * RateFactor) / (RateFactor - 1),
            erlang:round(Payment)
    end.

validate_loan_params(Principal, TermMonths, AnnualRate) ->
    case Principal of
        P when P =< 0 -> {error, invalid_amount};
        P when P > ?MAX_AMOUNT -> {error, amount_overflow};
        _ -> 
            case TermMonths of
                T when T =< 0 -> {error, invalid_term};
                T when T > 360 -> {error, term_too_long};
                _ -> 
                    case AnnualRate of
                        R when R < 0.0 -> {error, invalid_interest_rate};
                        R when R > 1.0 -> {error, interest_rate_too_high};
                        _ -> ok
                    end
            end
    end.
