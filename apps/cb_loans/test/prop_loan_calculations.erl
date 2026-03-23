-module(prop_loan_calculations).

-include_lib("proper/include/proper.hrl").

-export([
    prop_zero_rate_payment_matches_ceiling_division/0,
    prop_total_interest_matches_payment_schedule/0,
    prop_outstanding_balance_stays_within_bounds/0
]).

-spec prop_zero_rate_payment_matches_ceiling_division() -> term().
prop_zero_rate_payment_matches_ceiling_division() ->
    ?FORALL({Principal, TermMonths}, {valid_amount(), valid_term()},
        begin
            {ok, Payment} = cb_loan_calculations:calculate_monthly_payment(Principal, TermMonths, 0),
            Payment =:= ceil_div(Principal, TermMonths)
        end
    ).

-spec prop_total_interest_matches_payment_schedule() -> term().
prop_total_interest_matches_payment_schedule() ->
    ?FORALL({Principal, TermMonths, AnnualRateBps}, {valid_amount(), valid_term(), valid_rate()},
        begin
            {ok, Payment} = cb_loan_calculations:calculate_monthly_payment(Principal, TermMonths, AnnualRateBps),
            {ok, TotalInterest} = cb_loan_calculations:calculate_total_interest(Principal, TermMonths, AnnualRateBps),
            TotalInterest =:= (Payment * TermMonths) - Principal andalso
            Payment >= ceil_div(Principal, TermMonths)
        end
    ).

-spec prop_outstanding_balance_stays_within_bounds() -> term().
prop_outstanding_balance_stays_within_bounds() ->
    ?FORALL({Principal, TotalPaid}, {valid_amount(), range(0, 2000000)},
        begin
            Outstanding = cb_loan_calculations:calculate_outstanding_balance(Principal, TotalPaid, 0),
            Outstanding >= 0 andalso Outstanding =< Principal
        end
    ).

valid_amount() ->
    range(1, 1000000).

valid_term() ->
    range(1, 360).

valid_rate() ->
    range(0, 10000).

ceil_div(Numerator, Denominator) ->
    (Numerator + Denominator - 1) div Denominator.
