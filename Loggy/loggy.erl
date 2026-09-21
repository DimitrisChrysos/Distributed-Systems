-module(loggy).
-export([start/1, stop/1]).

start(Nodes) ->
    spawn_link(fun() ->init(Nodes) end).

stop(Logger) ->
    Logger ! stop.

init(Nodes) ->
    Clock = time:clock(Nodes),
    HoldbackQueue = [],
    loop(Nodes, Clock, HoldbackQueue, 0).

loop(Nodes, Clock, HoldbackQueue, MaxQueueSize) ->
    receive
        {log, From, Time, Msg} ->
            UpdatedClock = time:update(From, Time, Clock),
            UpdatedHoldbackQueue = [{From, Time, Msg} | HoldbackQueue],
            {SafeQueue, UnsafeQueue} = get_safe_and_unsafe_queue(UpdatedClock, UpdatedHoldbackQueue),
            UpdatedMaxQueueSize = erlang:max(MaxQueueSize, length(UnsafeQueue)),
            log_safe_queue(SafeQueue),
            loop(Nodes, UpdatedClock, UnsafeQueue, UpdatedMaxQueueSize);
        stop ->
            io:format("Maximum holdback queue size: ~p~n", [MaxQueueSize]),
            ok
    end.

get_safe_and_unsafe_queue(Clock, Queue) ->
    lists:partition(
        fun({_From, Time, _Msg}) ->
            time:safe(Time, Clock)
        end,
        Queue
    ).

log_safe_queue(SafeQueue) ->
    OrderedSafe = lists:keysort(2, SafeQueue),
    lists:foreach(
        fun({From, Time, Msg}) -> log(From, Time, Msg) end, OrderedSafe
    ).

log(From, Time, Msg) ->
    io:format("log: ~w ~w ~p~n", [Time, From, Msg]).