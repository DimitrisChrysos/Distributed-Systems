-module(loggy).
-export([start/2, stop/1]).

start(Nodes, TimeModule) ->
    spawn_link(fun() ->init(Nodes, TimeModule) end).

stop(Logger) ->
    Logger ! stop.

init(Nodes, TimeModule) ->
    Clock = TimeModule:clock(Nodes),
    HoldbackQueue = [],
    loop(Nodes, Clock, HoldbackQueue, 0, TimeModule).

loop(Nodes, Clock, HoldbackQueue, MaxQueueSize, TimeModule) ->
    receive
        {log, From, Time, Msg} ->
            UpdatedClock = TimeModule:update(From, Time, Clock),
            print_new_unsafe_event(From, Time, Msg, UpdatedClock, TimeModule),
            UpdatedHoldbackQueue = [{From, Time, Msg} | HoldbackQueue],
            {SafeQueue, UnsafeQueue} = get_safe_and_unsafe_queue(UpdatedClock, UpdatedHoldbackQueue, TimeModule),
            UpdatedMaxQueueSize = erlang:max(MaxQueueSize, length(UnsafeQueue)),
            log_safe_queue(SafeQueue, TimeModule),
            loop(Nodes, UpdatedClock, UnsafeQueue, UpdatedMaxQueueSize, TimeModule);
        stop ->
            io:format("Maximum holdback queue size: ~p~n", [MaxQueueSize]),
            ok
    end.

print_new_unsafe_event(From, Time, Msg, UpdatedClock, TimeModule) ->
    case TimeModule:safe(Time, UpdatedClock) of
        false ->
            io:format("queued: ~p ~p ~p~n", [From, Time, Msg]);
        true ->
            ok
    end.

get_safe_and_unsafe_queue(Clock, Queue, TimeModule) ->
    lists:partition(
        fun({_From, Time, _Msg}) ->
            TimeModule:safe(Time, Clock)
        end,
        Queue
    ).

log_safe_queue(SafeQueue, TimeModule) ->
    RankedSafe = lists:map(
        fun({_, Time, _} = Event) -> {TimeModule:rank(Time), Event} end,
        SafeQueue
    ),
    OrderedSafe = [Event || {_Rank, Event} <- lists:keysort(1, RankedSafe)],
    lists:foreach(
        fun({From, Time, Msg}) -> log(From, Time, Msg) end, OrderedSafe
    ).

log(From, Time, Msg) ->
    io:format("log: ~w ~w ~p~n", [Time, From, Msg]).