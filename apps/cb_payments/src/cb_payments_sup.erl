%%%
%% @doc CB Payments Supervisor
%%
%% This is the top-level supervisor for the cb_payments application. It follows
%% the OTP supervisor behavior and is responsible for:
%%
%% <ul>
%%   <li>Starting and managing payment processing workers</li>
%%   <li>Implementing fault tolerance via restart strategies</li>
%%   <li>Providing a supervision tree for the payments subsystem</li>
%% </ul>
%%
%% ## Supervision Strategy
%%
%% The supervisor uses the <tt>one_for_one</tt> restart strategy, which means
%% if a child process crashes, only that specific process is restarted. Other
%% child processes are unaffected. This is appropriate for payment workers that
%% are independent of each other.
%%
%% ## Intensity and Period
%%
%% The intensity is set to 5 and period to 10, meaning if more than 5 child
%% process terminations occur within 10 seconds, the supervisor itself will
%% terminate. This prevents infinite restart loops in case of persistent
%% failures.
%%
%% ## Child Processes
%%
%% Currently, this supervisor runs with no child processes. Payment operations
%% are handled directly via Mnesia transactions. Child processes can be added
%% as the system evolves (e.g., for async processing, background workers, etc.).
%%
%% @see cb_payments
%% @see cb_payments_app

-module(cb_payments_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

%%
%% @doc Start the payments supervisor
%%
%% Starts the supervisor as a locally registered process.
%%
%% @returns <tt>{ok, Pid}</tt> of the supervisor, or <tt>{error, Reason}</tt>

-spec start_link() -> {ok, pid()} | {error, any()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%
%% @private
%%
%% Initializes the supervisor with its restart strategy and child specifications.
%%
%% @param _Args Initialization arguments (ignored)
%%
%% @returns <tt>{ok, {SupFlags, Children}}</tt> where SupFlags defines the
%%          restart strategy and intensity limits, and Children is the list
%%          of child process specifications

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,
        period => 10
    },
    Children = [],
    {ok, {SupFlags, Children}}.
