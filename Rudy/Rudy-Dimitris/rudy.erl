-module(rudy).
-export([start/1, start/2, stop/0]).

init(Port, Mode) ->
    Opt = [list, {active, false}, {reuseaddr, true}, {backlog, 100}],
    case gen_tcp:listen(Port, Opt) of
        {ok, Listen} ->
            run_server(Mode, Listen),
            gen_tcp:close(Listen),
            ok;
        {error, _Error} ->
            error
    end.

% Sequential mode: Use this for sequential handling of the new connections
run_server(sequential, Listen) ->
    handler(Listen);

% Process per request mode: Use this for a new process for each incoming connection
run_server(process_per_request, Listen) ->
    handler_create_new_process(Listen);

% Handler pool mode: Use this for creating a specific number of handler processes for incoming requests
run_server({pool, NumberOfHandlers}, Listen) ->
    spawn_handlers(Listen, NumberOfHandlers),
    receive
        stop -> ok
    end.


spawn_handlers(_Listen, 0) ->
    ok;
spawn_handlers(Listen, NumberOfHandlers) ->
    spawn(fun() -> handler(Listen) end),
    spawn_handlers(Listen, NumberOfHandlers - 1).

handler(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Client} ->
            request(Client),
            handler(Listen);
        {error, _Error} ->
            error
    end.

% This handler method creates a new process for each incoming connection
handler_create_new_process(Listen) ->
case gen_tcp:accept(Listen) of
    {ok, Client} ->
        spawn(fun() -> request(Client) end),
        handler_create_new_process(Listen);
    {error, _Error} ->
        error
end.

request(Client) ->
    Recv = gen_tcp:recv(Client, 0),
    case Recv of
        {ok, Str} ->
            Request = http:parse_request(Str),
            Response = reply(Request),
            gen_tcp:send(Client, Response);
        {error, Error} ->
            io:format("rudy: error: ~w~n", [Error])
    end,
    gen_tcp:close(Client).

reply({{get, _URI, _}, _, _}) ->
    timer:sleep(40),
    http:ok(":)").

start(Port) ->
    start(Port, sequential).

start(Port, Mode) ->
    register(rudy, spawn(fun() -> init(Port, Mode) end)).

stop() ->
    exit(whereis(rudy), "time to die").