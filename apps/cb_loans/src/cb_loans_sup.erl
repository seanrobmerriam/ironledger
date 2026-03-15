%%%===================================================================
%%%
%%% @doc Loan Supervisor Module
%%%
%%% This is the top-level supervisor for the cb_loans application.
%%% It manages the lifecycle of all loan-related worker processes.
%%%
%%% <h2>Supervision Strategy</h2>
%%%
%%% Uses `one_for_one` strategy, meaning if any child process
%%% terminates, only that process is restarted. This is appropriate
%%% because each loan subsystem operates independently.
%%%
%%% <h2>Child Processes</h2>
%%%
%%% <ol>
%%%   <li><b>cb_loan_products</b>: Manages loan product definitions</li>
%%%   <li><b>cb_loan_accounts</b>: Manages loan accounts and lifecycle</li>
%%%   <li><b>cb_loan_repayments</b>: Manages repayment tracking</li>
%%% </ol>
%%%
%%% <h2>Restart Strategy</h2>
%%%
%%% <ul>
%%%   <li><b>Intensity</b>: 5 restarts allowed</li>
%%%   <li><b>Period</b>: Within 10 seconds</li>
%%%   <li><b>Restart</b>: permanent (always restart)</li>
%%% </ul>
%%%
%%% @end
%%%===================================================================

-module(cb_loans_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

%%
%% @doc Starts the loan supervisor.
%%
%% Initializes the supervisor process and registers it locally
%% under the name `cb_loans_sup`.
%%
%% @returns {ok, pid()} on success, {error, term()} on failure
%%
-spec start_link() -> {ok, pid()} | {error, any()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%
%% @doc Initializes the supervisor with child specifications.
%%
%% Defines the supervision tree including the restart strategy
%% and all child worker processes.
%%
%% @param _Args Arguments (ignored)
%%
%% @returns {ok, {sup_flags(), [child_spec()]}}
%%
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
