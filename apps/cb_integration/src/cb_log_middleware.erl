-module(cb_log_middleware).
-behaviour(cowboy_middleware).
-export([execute/2]).

-spec execute(cowboy_req:req(), cowboy_middleware:env()) -> {ok, cowboy_req:req(), cowboy_middleware:env()}.
execute(Req, Env) ->
    Method = cowboy_req:method(Req),
    Path   = cowboy_req:path(Req),
    Start  = erlang:monotonic_time(millisecond),

    %% Log the incoming request
    logger:info(#{
        event  => request_received,
        method => Method,
        path   => Path,
        time   => erlang:system_time(millisecond)
    }),

    %% Execute the rest of the middleware stack
    case cowboy_middleware:execute(Req, Env) of
        {ok, Req2, Env2} ->
            Status   = cowboy_req:resp_status(Req2),
            Duration = erlang:monotonic_time(millisecond) - Start,
            logger:info(#{
                event    => request_completed,
                method   => Method,
                path     => Path,
                status   => Status,
                duration => Duration
            }),
            {ok, Req2, Env2};
        Other ->
            logger:warning(#{event => middleware_error, method => Method, path => Path}),
            Other
    end.
