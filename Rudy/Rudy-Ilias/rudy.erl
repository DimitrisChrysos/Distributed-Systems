
%% @doc A simple HTTP server with sequential and concurrent execution modes.
-module(rudy).

-export([start/1, stop/0, start/2, stop/1]).

%% @doc Starts a sequential server that listens on the specified port.
%% @param Port The port number on which the server will listen for incoming connections.
start(Port) ->
    register(rudy, spawn(fun() -> init(Port) end)).

%% @doc Stops the sequential server registered as rudy.
stop() ->
    exit(whereis(rudy), "time to die").

%% @doc Initializes the listening socket for the sequential server and passes it to the handler.
%% After the handler returns, the listening socket is closed.
%% @param The port number on which the server will listen for incoming connections.
init(Port) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Opt) of
        {ok, Listen} ->
            %
            handler(Listen),
            %
            gen_tcp:close(Listen),
            ok;
        {error, _Error} ->
            error
    end.

%% @doc Using a listening socket, accepts clients sequentially and handles each request.
%% After handling a request, the server continues to accept new clients until an error occurs.
%% @param The listening socket for incoming connections.
handler(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Client} ->
            %
            request(Client),
            handler(Listen);
            %
        {error, _Error} ->
            error
    end.

%% @doc Receives, parses, and responds to one client request.
%% @param The client socket of the accepted connection.
request(Client) ->
    Recv = gen_tcp:recv(Client, 0),
    case Recv of
        {ok, Str} ->
            %
            Request = http:parse_request(Str),
            %
            Response = reply(Request),
            gen_tcp:send(Client, Response);
        {error, Error} ->
            io:format("rudy: error: ~w~n", [Error])
    end,
    gen_tcp:close(Client).

%% @doc Builds a response for a GET request after simulating processing time.
reply({{get, _, _}, _, _}) ->
    timer:sleep(40),
    http:ok(":)").


%%%
%%% Concurrent version
%%%

%% @doc Starts a concurrent server with a fixed worker pool.
%% @param The port number on which the server will listen for incoming connections.
start(Port, concurrent) ->
    register(rudy, spawn(fun() -> init_concurrent(Port, 8) end)).

%% @doc Stops the concurrent server registered as rudy.
stop(concurrent) ->
    RudyPID = whereis(rudy),
    RudyPID ! stop,
    exit(RudyPID, "time to die").

%% @doc Initializes the listening socket and starts the concurrent worker pool.
%% After creating the listing socket, it binds all workers to it and waits for a stop message to close the socket.
%% @param Port The port number on which the server will listen for incoming connections.
%% @param Pool_size The number of worker processes to spawn for handling client requests.
init_concurrent(Port, Pool_size) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Opt) of
        {ok, Listen} ->
            create_process_pool(Pool_size, Listen),
            receive
                stop -> gen_tcp:close(Listen)
            end;
        {error, _Error} ->
            error
    end.

%% @doc Creates the requested number of linked workers sharing a listening socket.
%% @param N The number of worker processes to spawn.
%% @param Listen The listening socket for incoming connections.
create_process_pool(0, _Listen) ->
    ok;
create_process_pool(N, Listen) when N > 0 ->
    spawn_link(fun() -> worker(Listen) end),
    create_process_pool(N - 1, Listen).

%% @doc Accepts and handles client requests in a worker loop.
%% Each worker listens on the shared listening socket, accepts
%% a client connection, processes the request, and then loops
%% back to accept another connection.
%% @param Listen The listening socket for incoming connections.
worker(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Client} ->
            request(Client),
            worker(Listen);
        {error, closed} ->
            ok;
        {error, _Error} ->
            worker(Listen)
    end.
