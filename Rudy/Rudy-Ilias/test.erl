
%% @doc Benchmark utilities for measuring request performance.
%% The benchmark functions send requests to a Rudy server and append timing
%% results to files in the current working directory.
-module(test).
-export([bench/6, complete_benchmark/4]).

%% @doc Runs a benchmark for each request count in a list and records average times.
%% @param Host The server hostname or IP address.
%% @param Port The server port.
%% @param Requests A list of request counts to benchmark.
%% @param Repetitions The number of repetitions for each request count.
%% @returns `{ok, 0}` after all benchmarks have completed.
complete_benchmark(Host, Port, [H | T], Repetitions) ->
    {ok, Avg} = bench(Host, Port, H, Repetitions, Repetitions, 0),
    file:write_file(integer_to_list(H) ++ "_results.txt", ["Average time: " ++ io_lib:format("~p", [Avg]) ++ "\n"], [append]),
    complete_benchmark(Host, Port, T, Repetitions);
complete_benchmark(_, _, [], _) ->
    {ok, 0}.

%% @doc Runs one request-count benchmark repeatedly and calculates its average time.
%% @param Host The server hostname or IP address.
%% @param Port The server port.
%% @param RequestsNum The number of requests sent in each repetition.
%% @param Repetitions The number of repetitions remaining.
%% @param Total The total number of repetitions in the benchmark.
%% @param Sum The accumulated elapsed time in microseconds.
%% @returns `{ok, AverageTime}` when all repetitions are complete.
bench(Host, Port, RequestsNum, Repetitions, Total, Sum) when Repetitions > 0 ->
    Start = erlang:system_time(micro_seconds),
    run(RequestsNum, Host, Port),
    Finish = erlang:system_time(micro_seconds),

    TotalTime = Finish - Start,

    file:write_file(integer_to_list(RequestsNum) ++ "_results.txt", [integer_to_list(TotalTime) ++ "\n"], [append]),
    bench(Host, Port, RequestsNum, Repetitions - 1, Total, Sum + TotalTime); % always pass total number of repetitions to the next call, so we can calculate the average at the end
bench(_, _, _, _, Total, Sum) ->
    {ok, Sum / Total}.

%% @doc Sends a specified number of sequential requests to a server.
%% @param N The number of requests to send.
%% @param Host The server hostname or IP address.
%% @param Port The server port.
%% @returns `ok` after all requests have completed.
run(N, Host, Port) ->
    if
        N == 0 ->
            ok;
        true ->
            request(Host, Port),
            run(N-1, Host, Port)
    end.

%% @doc Opens a connection, sends one HTTP request, and waits for its response, before closing the connection.
%% @param Host The server hostname or IP address.
%% @param Port The server port.
%% @returns `ok` after the response is received and the socket is closed.
request(Host, Port) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    {ok, Server} = gen_tcp:connect(Host, Port, Opt),
    gen_tcp:send(Server, http:get("foo")),
    % block and wait until we receive a response from the server
    Recv = gen_tcp:recv(Server, 0),
    case Recv of
        {ok, _} ->
            ok;
        {error, Error} ->
            io:format("test: error: ~w~n", [Error])
    end,
    gen_tcp:close(Server).
