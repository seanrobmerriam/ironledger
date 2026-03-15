%%%
%%% @doc Savings Products Top-Level Supervisor.
%%%
%%% This module implements the OTP supervisor behaviour for the
%%% cb_savings_products application.
%%%
%%% ## Supervisor Role
%%%
%%% The top-level supervisor (also known as the application master) is
%%% responsible for:
%%% <ul>
%%%   <li>Starting the cb_savings_products application</li>
%%%   <li>Managing the lifecycle of child processes</li>
%%%   <li>Implementing the failure recovery strategy</li>
%%% </ul>
%%%
%%% ## Supervision Strategy
%%%
%%% This supervisor uses the `one_for_one` restart strategy. If a child
%%% process terminates, only that specific process is restarted. This is
%%% appropriate for savings products because:
%%% <ul>
%%%   <li>Each operation is stateless and self-contained</li>
%%%   <li>No child processes are currently required</li>
%%%   <li>Failures in one operation don't affect others</li>
%%% </ul>
%%%
%%% ## Child Specifications
%%%
%%% Currently, this supervisor starts with an empty child list as the
%%% savings products module operates statelessly through Mnesia. If future
%%% features require persistent processes (e.g., background interest
%%% accrual workers), they would be added here.
%%%
%%% @see cb_savings_products_app
%%% @see cb_savings_products
%%% @see supervisor

-module(cb_savings_products_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

%%%
%%% @doc Starts the savings products supervisor.
%%%
%%% Registers the supervisor locally with the name `cb_savings_products_sup'
%%% and initializes it with the default configuration.
%%%
%%% @returns `{ok, Pid}' on successful startup
%%% @returns `{error, Reason}' if startup fails
%%%
%%% @example
%%% % Start from shell
%%% > cb_savings_products_sup:start_link().
%%% {ok, Pid}
%%%
-spec start_link() -> {ok, pid()} | {error, any()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%
%%% @doc Initializes the supervisor with its child specifications.
%%%
%%% This function is called by the supervisor behavior to set up the
%%% supervision tree. It defines the restart strategy and intensity,
%%% as well as any child processes to supervise.
%%%
%%% @param _Args Arguments passed from start_link (unused)
%%%
%%% @returns `{ok, {SupFlags, Children}}' containing supervisor flags
%%%          and child specifications
%%%
%%% @see supervisor:sup_flags()
%%% @see supervisor:child_spec()
%%%
-spec init(_Args :: []) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,
        period => 10
    },
    Children = [],
    {ok, {SupFlags, Children}}.
