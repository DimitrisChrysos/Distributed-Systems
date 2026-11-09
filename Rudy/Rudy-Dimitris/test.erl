-module(test).
-export([bench/3, bench_average/4]).

bench_average(Host, Port, Requests, Runs) ->
    Times = bench_times(Host, Port, Requests, Runs, []),
    TotalTimes = lists:sum(Times),
    AverageTime = TotalTimes / Runs,
    AverageTimeInSeconds = AverageTime / 1000000,
    RequestsPerSecond = Requests / AverageTimeInSeconds,
    io:format("Times List (microseconds): ~p~n", [Times]),
    io:format("Average: ~f microseconds~n", [AverageTime]),
    io:format("Throughput: ~f requests per second~n",[RequestsPerSecond]),
    {AverageTime, RequestsPerSecond}.


bench_times(_Host, _Port, _Requests, 0, Times) ->
    Times;

bench_times(Host, Port, Requests, Runs, Times) ->
    Time = bench(Host, Port, Requests),
    bench_times(Host, Port, Requests, Runs - 1, [Time | Times]).
    

bench(Host, Port, N) -> 
    Start = erlang:system_time(micro_seconds),
    run(N, Host, Port),
    Finish = erlang:system_time(micro_seconds),
    Finish - Start.

run(N, Host, Port) -> 
    if 
        N == 0 -> 
            ok;
        true ->
            request(Host, Port),
            run(N-1, Host, Port)
    end.

request(Host, Port) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    {ok, Server} = gen_tcp:connect(Host, Port, Opt),
    gen_tcp:send(Server, http:get("foo")),
    Recv = gen_tcp:recv(Server, 0),
    case Recv of
        {ok, _} ->
            ok;
        {error, Error} ->
            io:format("test: error: ~w~n", [Error])
    end,
    gen_tcp:close(Server).