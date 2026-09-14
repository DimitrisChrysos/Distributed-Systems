-module(routy).
-export([start/2, stop/1, init/1, router/6, status/1]).

start(Reg, Name) ->
    register(Reg, spawn(fun() -> init(Name) end)).

stop(Node) -> 
    Node ! stop,
    unregister(Node).

init(Name) ->
    Intf = intf:new(),
    Map = map:new(),
    Table = dijkstra:table(Intf, Map), % TODO: maybe it should be this instead: Table = dijkstra:table(intf:list(Intf), Map),
    Hist = hist:new(Name),
    % router(Name, 0, Msgs, Intf, Table, Map).
    router(Name, 0, Hist, Intf, Table, Map). % TODO: the original line (commented out above) had "Msgs" instead of "Hist" which does not make sense

router(Name, N, Hist, Intf, Table, Map) ->
    receive
        {add, Node, Pid} ->
            Ref = erlang:monitor(process,Pid),
            Intf1 = intf:add(Node, Ref, Pid, Intf),
            router(Name, N, Hist, Intf1, Table, Map);
        {remove, Node} ->
            {ok, Ref} = intf:ref(Node, Intf),
            erlang:demonitor(Ref),
            Intf1 = intf:remove(Node, Intf), 
            router(Name, N, Hist, Intf1, Table, Map);
        {'DOWN', Ref, process, _, _} ->
            {ok, Down} = intf:name(Ref, Intf),
            io:format("~w: exit recived from ~w~n", [Name, Down]),
            Intf1 = intf:remove(Down, Intf),
            router(Name, N, Hist, Intf1, Table, Map);
        {status, From} ->
            From ! {status, {Name, N, Hist, Intf, Table, Map}},
            router(Name, N, Hist, Intf, Table, Map);
        stop ->
            ok
    end.

status(Node) ->
    Node ! {status, self()},
    receive
        {status, State} ->
            io:format("~p~n", [State])
    end.