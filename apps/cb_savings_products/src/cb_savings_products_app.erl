-module(cb_savings_products_app).
-behaviour(application).

-export([start/2, stop/1]).

-spec start(normal, any()) -> {ok, pid()} | {error, any()}.
start(_StartType, _StartArgs) ->
    cb_savings_products_sup:start_link().

-spec stop(any()) -> ok.
stop(_State) ->
    ok.
