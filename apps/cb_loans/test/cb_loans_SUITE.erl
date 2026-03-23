-module(cb_loans_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include_lib("cb_ledger/include/cb_ledger.hrl").
-include("loan.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).

%% cb_loan_calculations tests (pure functions, no gen_server needed)
-export([
    %% Happy path tests
    calculate_monthly_payment_ok/1,
    calculate_monthly_payment_zero_rate/1,
    calculate_total_interest_ok/1,
    calculate_principal_portion_ok/1,
    calculate_interest_portion_ok/1,
    calculate_flat_interest_ok/1,
    calculate_outstanding_balance_ok/1,
    %% Error path tests
    calculate_monthly_payment_invalid_amount/1,
    calculate_monthly_payment_amount_overflow/1,
    calculate_monthly_payment_invalid_term/1,
    calculate_monthly_payment_term_too_long/1,
    calculate_monthly_payment_negative_rate/1,
    calculate_monthly_payment_rate_too_high/1
]).

all() ->
    [
        %% Happy path tests
        calculate_monthly_payment_ok,
        calculate_monthly_payment_zero_rate,
        calculate_total_interest_ok,
        calculate_principal_portion_ok,
        calculate_interest_portion_ok,
        calculate_flat_interest_ok,
        calculate_outstanding_balance_ok,
        %% Error path tests
        calculate_monthly_payment_invalid_amount,
        calculate_monthly_payment_amount_overflow,
        calculate_monthly_payment_invalid_term,
        calculate_monthly_payment_term_too_long,
        calculate_monthly_payment_negative_rate,
        calculate_monthly_payment_rate_too_high
    ].

init_per_suite(Config) ->
    %% Just start mnesia - no gen_servers needed for pure functions
    mnesia:start(),
    Config.

end_per_suite(_Config) ->
    mnesia:stop(),
    mnesia:delete_schema([node()]),
    ok.

init_per_testcase(_TestCase, Config) ->
    Config.

end_per_testcase(_TestCase, _Config) ->
    ok.

%% =============================================================================
%% cb_loan_calculations Tests
%% Tests for loan calculation functions - all pure functions that don't require
%% gen_servers or database access.
%% =============================================================================

%% Happy path: Calculate monthly payment with standard inputs
calculate_monthly_payment_ok(_Config) ->
    {ok, Payment} = cb_loan_calculations:calculate_monthly_payment(10000, 12, 1200),
    ?assert(Payment > 0),
    ?assert(is_integer(Payment)),
    ok.

%% Happy path: Calculate monthly payment with zero interest rate
calculate_monthly_payment_zero_rate(_Config) ->
    {ok, Payment} = cb_loan_calculations:calculate_monthly_payment(12000, 12, 0),
    ?assertEqual(1000, Payment),
    ok.

%% Happy path: Calculate total interest
calculate_total_interest_ok(_Config) ->
    {ok, TotalInterest} = cb_loan_calculations:calculate_total_interest(10000, 12, 1200),
    ?assert(TotalInterest > 0),
    ?assert(is_integer(TotalInterest)),
    ok.

%% Happy path: Calculate principal portion
calculate_principal_portion_ok(_Config) ->
    PrincipalPortion = cb_loan_calculations:calculate_principal_portion(1000, 100, 5000),
    ?assertEqual(900, PrincipalPortion),
    ok.

%% Happy path: Calculate interest portion
calculate_interest_portion_ok(_Config) ->
    InterestPortion = cb_loan_calculations:calculate_interest_portion(10000, 1000, 1200),
    ?assert(InterestPortion > 0),
    ok.

%% Happy path: Calculate flat interest
calculate_flat_interest_ok(_Config) ->
    FlatInterest = cb_loan_calculations:calculate_flat_interest(10000, 12, 1200),
    ?assert(FlatInterest > 0),
    ok.

%% Happy path: Calculate outstanding balance
calculate_outstanding_balance_ok(_Config) ->
    Outstanding = cb_loan_calculations:calculate_outstanding_balance(10000, 3000, 3000),
    ?assertEqual(7000, Outstanding),
    ok.

%% Error path: Invalid amount (zero)
calculate_monthly_payment_invalid_amount(_Config) ->
    {error, Reason} = cb_loan_calculations:calculate_monthly_payment(0, 12, 1000),
    ?assertEqual(invalid_amount, Reason),
    ok.

%% Boundary: Amount exceeds maximum allowed
calculate_monthly_payment_amount_overflow(_Config) ->
    MaxAmount = 9999999999999,
    {error, Reason} = cb_loan_calculations:calculate_monthly_payment(MaxAmount + 1, 12, 1000),
    ?assertEqual(amount_overflow, Reason),
    ok.

%% Error path: Invalid term (zero)
calculate_monthly_payment_invalid_term(_Config) ->
    {error, Reason} = cb_loan_calculations:calculate_monthly_payment(10000, 0, 1000),
    ?assertEqual(invalid_term, Reason),
    ok.

%% Error path: Term exceeds maximum allowed
calculate_monthly_payment_term_too_long(_Config) ->
    {error, Reason} = cb_loan_calculations:calculate_monthly_payment(10000, 361, 1000),
    ?assertEqual(term_too_long, Reason),
    ok.

%% Error path: Negative interest rate
calculate_monthly_payment_negative_rate(_Config) ->
    {error, Reason} = cb_loan_calculations:calculate_monthly_payment(10000, 12, -1),
    ?assertEqual(invalid_interest_rate, Reason),
    ok.

%% Error path: Interest rate exceeds 100%
calculate_monthly_payment_rate_too_high(_Config) ->
    {error, Reason} = cb_loan_calculations:calculate_monthly_payment(10000, 12, 10001),
    ?assertEqual(interest_rate_too_high, Reason),
    ok.
