-module(gms3).

-export([start/1, start/2]).

-define(timeout, 5000).
-define(arghh, 100).

% start the first node in the group
start(Id) ->
    Rnd = random:uniform(1000),
    Self = self(),
    {ok, spawn_link(fun() -> init(Id, Rnd, Self) end)}.

init(Id, Rnd, Master) ->
    random:seed(Rnd, Rnd, Rnd),
    leader(Id, Master, 0, [], [Master]).

% start a node that will join a group
start(Id, Grp) ->
    Rnd = random:uniform(1000),
    Self = self(),
    {ok, spawn_link(fun() -> init(Id, Grp, Rnd, Self) end)}.

init(Id, Grp, Rnd, Master) ->
    random:seed(Rnd, Rnd, Rnd),
    Self = self(),
    Grp ! {join, Master, Self},
    receive
        {view, N, [Leader | Slaves], Group} ->
            erlang:monitor(process, Leader),
            Master ! {view, Group},
            slave(Id, Master, Leader, N, {}, Slaves, Group)
    after ?timeout ->
        Master ! {error, "no reply from leader"}
    end.

leader(Id, Master, N, Slaves, Group) ->
    receive
        {mcast, Msg} ->
            bcast(Id, {msg, N, Msg}, Slaves),
            Master ! Msg,
            leader(Id, Master, N + 1, Slaves, Group);
        {join, Wrk, Peer} ->
            Slaves2 = lists:append(Slaves, [Peer]),
            Group2 = lists:append(Group, [Wrk]),
            bcast(Id, {view, N, [self() | Slaves2], Group2}, Slaves2),
            Master ! {view, Group2},
            leader(Id, Master, N, Slaves2, Group2);
        stop ->
            ok
    end.

bcast(Id, Message, Slaves) ->
    % lists:foreach(fun(Pid) -> Pid ! Message end, Slaves).
    lists:foreach(fun(Node) -> Node ! Message, crash(Id) end, Slaves).

crash(Id) ->
    case random:uniform(?arghh) of
        ?arghh ->
            io:format("leader ~w: crash~n", [Id]),
            exit(no_luck);
        _ ->
            ok
    end.

slave(Id, Master, Leader, N, Last, Slaves, Group) ->
    receive
        {mcast, Msg} ->
            Leader ! {mcast, Msg},
            slave(Id, Master, Leader, N, Last, Slaves, Group);
        {join, Wrk, Peer} ->
            Leader ! {join, Wrk, Peer},
            slave(Id, Master, Leader, N, Last, Slaves, Group);
        {msg, I, _} when I < N ->
            io:format("~w received old message: (I=~w, N=~w) ~n", [Id, I, N]),
            % disregard duplicate messages
            slave(Id, Master, Leader, N, Last, Slaves, Group);
        {msg, N, Msg} ->
            io:format("~w received NEW message: ~w (N=~w) ~n", [Id, Msg, N]),
            % new message: save it as Last and increment N
            Master ! Msg,
            slave(Id, Master, Leader, N + 1, {msg, N, Msg}, Slaves, Group);
        {view, N, [Leader | Slaves2], Group2} ->
            Master ! {view, Group2},
            slave(Id, Master, Leader,  N + 1, {view, N, [Leader | Slaves2], Group2}, Slaves2, Group2);
        {'DOWN', _Ref, process, Leader, _Reason} ->
            io:format("~w received down from ~w~n", [Id, Leader]),
            election(Id, Master, Slaves,  N, Last, Group);
        stop ->
            ok
    end.

election(Id, Master, Slaves, N, Last, [_ | Group]) ->
    Self = self(),
    case Slaves of
        [Self | Rest] ->
            io:format("~w becomes the new leader~n", [Id]),
            io:format("~w broadcasting Last Message: ~w~n", [Id, Last]),
            bcast(Id, Last, Rest),
            Master ! {view, Group},
            leader(Id, Master, N, Rest, Group);
        [Leader | Rest] ->
            io:format("~w is monitoring new Leader: ~w~n", [Id, Leader]),
            erlang:monitor(process, Leader),
            slave(Id, Master, Leader,  N, Last, Rest, Group)
    end.