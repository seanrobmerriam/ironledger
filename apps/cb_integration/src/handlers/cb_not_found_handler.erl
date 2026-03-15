%% @doc 404 Not Found Handler
%%
%% This handler catches all requests that don't match any defined route.
%% It's the catch-all handler configured as the last route in the router.
%%
%% <h2>Why 404 Responses Matter</h2>
%%
%% Proper 404 handling is important for:
%% <ul>
%%   <li>API usability - Clients can distinguish between missing resources and errors</li>
%%   <li>Debugging - Helps identify routing misconfigurations</li>
%%   <li>SEO (for web) - Search engines know not to index non-existent pages</li>
%%   <li>Rate limiting - Prevents probing attacks from wasting resources</li>
%% </ul>
%%
%% <h2>Error Response Format</h2>
%%
%% Returns a JSON error response:
%% <pre>
%% {
%%   "error": "not_found",
%%   "message": "Resource not found"
%% }
%% </pre>
%%
%% @see cb_router
-module(cb_not_found_handler).

-export([init/2]).

-spec init(cowboy_req:req(), any()) -> {ok, cowboy_req:req(), any()}.
init(Req, State) ->
    Body = jsone:encode(#{
        error => <<"not_found">>,
        message => <<"Resource not found">>
    }),
    Headers = maps:merge(#{<<"content-type">> => <<"application/json">>}, cb_cors:headers()),
    Req2 = cowboy_req:reply(404, Headers, Body, Req),
    {ok, Req2, State}.
