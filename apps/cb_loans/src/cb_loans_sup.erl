-module(cb_loans_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-spec start_link() -> {ok, pid()} | {error, any()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,
        period => 10
    },
    Children = [
        #{id => cb_loan_products,
          start => {cb_loan_products, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [cb_loan_products]},
        #{id => cb_loan_accounts,
          start => {cb_loan_accounts, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [cb_loan_accounts]},
        #{id => cb_loan_repayments,
          start => {cb_loan_repayments, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [cb_loan_repayments]}
    ],
    {ok, {SupFlags, Children}}.
