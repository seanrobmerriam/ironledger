%% @doc Health Check Handler
%%
%% Provides a simple health check endpoint for monitoring and load balancer
%% readiness checks.
%%
%% <h2>Why Health Checks?</h2>
%%
%% In production environments, health checks are essential for:
%% <ul>
%%   <li>Load balancer to know which servers are healthy</li>
%%   <li>Orchestration systems (Kubernetes, Docker Swarm) for container management</li>
%%   <li>Monitoring systems to detect outages</li>
%%   <li>Readiness probes to route traffic only to ready instances</li>
%% </ul>
%%
%% This endpoint is intentionally simple and fast - it doesn't check database
%% connectivity or any external dependencies. For a more comprehensive health
%% check that verifies all systems, consider adding a separate endpoint.
%%
%% @see cb_router
-module(cb_health_handler).

-export([init/2]).

-spec init(cowboy_req:req(), any()) -> {ok, cowboy_req:req(), any()}.
init(Req, State) ->
    Body = jsone:encode(#{status => <<"ok">>}),
    Headers = maps:merge(#{<<"content-type">> => <<"application/json">>}, cb_cors:headers()),
    Req2 = cowboy_req:reply(200, Headers, Body, Req),
    {ok, Req2, State}.
