%% @doc
%% <h2>Party Supervisor Module</h2>
%%
%% This module implements the OTP supervisor behaviour for the cb_party application.
%% It provides fault tolerance and lifecycle management for party-related processes.
%%
%% <h3>Supervision Strategy</h3>
%%
%% This supervisor uses the <b>one_for_one</b> restart strategy:
%% <ul>
%%   <li>If a supervised child process terminates, only that specific process is restarted</li>
%%   <li>Other child processes continue running unaffected</li>
%%   <li>Suitable for independent workers that don't depend on each other</li>
%% </ul>
%%
%% <h3>Restart Configuration</h3>
%% <ul>
%%   <li><b>Intensity</b>: Maximum 5 restarts allowed</li>
%%   <li><b>Period</b>: Within a 10-second window</li>
%%   <li>If exceeded, the supervisor terminates itself (fail-safe for banking systems)</li>
%% </ul>
%%
%% <h3>Child Processes</h3>
%%
%% Currently, this supervisor starts with an empty child list. This is by design -
%% the cb_party module functions are called directly as stateless operations,
%% not as separate processes.
%%
%% <b>Future extension points</b>: If future requirements need background workers
%% (e.g., batch KYC verification, periodic status checks), they would be added
%% as supervised children here.
%%
%% <h3>Fault Tolerance in Banking</h3>
%%
%% The restart limits are intentionally conservative (5 in 10 seconds). In a
%% core banking system:
%% <ul>
%%   <li>Repeated failures indicate a systemic issue (database unavailable, etc.)</li>
%%   <li>Automatic restart should not be attempted indefinitely</li>
%%   <li>Operator intervention is required to diagnose and fix the root cause</li>
%% </ul>
%%
%% @see cb_party_app for the parent application module
-module(cb_party_sup).
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
    Children = [],
    {ok, {SupFlags, Children}}.
