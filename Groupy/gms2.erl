-module(gms2).

-export([start/1, start/2]).

-define(timeout, 5000).

% start the first node in the group
start(Id) ->
    Self = self(),
    {ok, spawn_link(fun() -> init(Id, Self) end)}.

init(Id, Master) ->
    leader(Id, Master, [], [Master]).

% start a node that will join a group
start(Id, Grp) ->
    Self = self(),
    {ok, spawn_link(fun() -> init(Id, Grp, Self) end)}.

init(Id, Grp, Master) ->
    Self = self(),
    Grp ! {join, Master, Self},
    receive
        {view, [Leader | Slaves], Group} ->
            erlang:monitor(process, Leader),
            Master ! {view, Group},
            slave(Id, Master, Leader, Slaves, Group)
    after ?timeout ->
        Master ! {error, "no reply from leader"}
    end.

leader(Id, Master, Slaves, Group) ->
    receive
        {mcast, Msg} ->
            bcast(Id, {msg, Msg}, Slaves),
            Master ! Msg,
            leader(Id, Master, Slaves, Group);
        {join, Wrk, Peer} ->
            Slaves2 = lists:append(Slaves, [Peer]),
            Group2 = lists:append(Group, [Wrk]),
            bcast(Id, {view, [self() | Slaves2], Group2}, Slaves2),
            Master ! {view, Group2},
            leader(Id, Master, Slaves2, Group2);
        stop ->
            ok
    end.

bcast(_Id, Message, Slaves) ->
    lists:foreach(fun(Pid) -> Pid ! Message end, Slaves).

slave(Id, Master, Leader, Slaves, Group) ->
    receive
        {mcast, Msg} ->
            Leader ! {mcast, Msg},
            slave(Id, Master, Leader, Slaves, Group);
        {join, Wrk, Peer} ->
            Leader ! {join, Wrk, Peer},
            slave(Id, Master, Leader, Slaves, Group);
        {msg, Msg} ->
            Master ! Msg,
            slave(Id, Master, Leader, Slaves, Group);
        {view, [Leader | Slaves2], Group2} ->
            Master ! {view, Group2},
            slave(Id, Master, Leader, Slaves2, Group2);
        {'DOWN', _Ref, process, Leader, _Reason} ->
            io:format("~w received down from ~w~n", [Id, Leader]),
            election(Id, Master, Slaves, Group);
        stop ->
            ok
    end.

election(Id, Master, Slaves, [_ | Group]) ->
    Self = self(),
    case Slaves of
        [Self | Rest] ->
            io:format("~w becomes the new leader~n", [Id]),
            bcast(Id, {view, Slaves, Group}, Rest),
            Master ! {view, Group},
            leader(Id, Master, Rest, Group);
        [Leader | Rest] ->
            io:format("~w is monitoring new Leader: ~w~n", [Id, Leader]),
            erlang:monitor(process, Leader),
            slave(Id, Master, Leader, Rest, Group)
end.