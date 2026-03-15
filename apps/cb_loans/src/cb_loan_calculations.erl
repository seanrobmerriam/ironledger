%%%===================================================================
%%%
%%% @doc Loan Calculation Functions
%%%
%%% This module provides comprehensive loan calculation functions
%%% including amortization schedules, interest calculations, and
%%% payment breakdowns.
%%%
%%% <h2>Loan Mathematics</h2>
%%%
%%% <h3>Amortization Formula</h3>
%%%
%%% The standard amortization formula calculates the fixed monthly payment:
%%%
%%% <pre>
%%% M = P * [r(1+r)^n] / [(1+r)^n - 1]
%%%
%%% Where:
%%%   M = Monthly payment
%%%   P = Principal (loan amount)
%%%   r = Monthly interest rate (annual rate / 12)
%%%   n = Number of payments (term in months)
%%% </pre>
%%%
%%% <h3>Interest Types</h3>
%%%
%%% <ul>
%%%   <li><b>Flat Interest</b>: Calculated on original principal for entire term</li>
%%%   <li><b>Declining Balance</b>: Calculated on remaining balance (standard amortizing)</li>
%%% </ul>
%%%
%%% <h3>Payment Breakdown</h3>
%%%
%%% Each payment consists of:
%%% <ul>
%%%   <li><b>Principal Portion</b>: Payment applied to reduce the balance</li>
%%%   <li><b>Interest Portion</b>: Payment covering the cost of borrowing</li>
%%% </ul>
%%%
%%% @end
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

%%
%% @doc Calculates the monthly payment amount for an amortizing loan.
%%
%% Uses the standard amortization formula to compute the fixed
%% monthly payment that will fully repay the loan over the term.
%%
%% @param Principal The loan principal amount in minor units
%% @param TermMonths The loan term in months
%% @param AnnualRate The annual interest rate (e.g., 0.05 = 5%)
%%
%% @returns {ok, amount()} The monthly payment in minor units,
%%          or {error, term()} if parameters are invalid
%%
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

%%
%% @doc Calculates the total interest paid over the life of the loan.
%%
%% Computes the total interest cost by subtracting the principal
%% from the sum of all payments.
%%
%% @param Principal The loan principal amount in minor units
%% @param TermMonths The loan term in months
%% @param AnnualRate The annual interest rate
%%
%% @returns {ok, amount()} Total interest in minor units,
%%          or {error, term()} on failure
%%
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

%%
%% @doc Calculates the principal portion of a loan payment.
%%
%% Determines how much of a payment goes toward reducing the
%% principal balance (as opposed to interest).
%%
%% @param TotalPayment The total payment amount
%% @param InterestPortion The interest portion of this payment
%% @param OutstandingBalance The current outstanding balance (unused)
%%
%% @returns amount() The principal portion in minor units
%%
-spec calculate_principal_portion(amount(), amount(), amount()) -> amount().
calculate_principal_portion(TotalPayment, InterestPortion, _OutstandingBalance) ->
    max(0, TotalPayment - InterestPortion).

%%
%% @doc Calculates the interest portion of a loan payment.
%%
%% Computes the interest charge for the current period based
%% on the outstanding balance and annual rate.
%%
%% @param OutstandingBalance The current principal balance
%% @param MonthlyPayment The scheduled monthly payment (unused)
%% @param AnnualRate The annual interest rate
%%
%% @returns amount() The interest portion in minor units
%%
-spec calculate_interest_portion(amount(), amount(), float()) -> amount().
calculate_interest_portion(OutstandingBalance, _MonthlyPayment, AnnualRate) ->
    MonthlyRate = AnnualRate / ?MONTHS_PER_YEAR,
    erlang:round(OutstandingBalance * MonthlyRate).

%%
%% @doc Calculates flat (simple) interest for a loan.
%%
%% Flat interest is calculated on the original principal amount
%% for the entire term, regardless of payments made. This is
%% typically used in consumer lending products.
%%
%% @param Principal The loan principal amount
%% @param TermMonths The loan term in months
%% @param AnnualRate The annual interest rate
%%
%% @returns amount() The total interest in minor units
%%
-spec calculate_flat_interest(amount(), integer(), float()) -> amount().
calculate_flat_interest(Principal, TermMonths, AnnualRate) ->
    erlang:round(Principal * AnnualRate * TermMonths / ?MONTHS_PER_YEAR).

%%
%% @doc Calculates the remaining outstanding balance after payments.
%%
%% Determines the current principal balance by subtracting
%% total payments made from the original principal.
%%
%% @param Principal The original loan principal
%% @param TotalPaid Total amount paid toward principal
%% @param PrincipalPortion Current payment's principal portion (unused)
%%
%% @returns amount() The outstanding balance (never negative)
%%
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
