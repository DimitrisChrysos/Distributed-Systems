-module(gms4).
-export([start/1, start/2]).

-define(timeout, 5000).
-define(arghh, 100).
-define(drop_ack, false). %% Set to true only when running gms4_ack_loss_test.

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
            io:format("~w received NEW view: ~p (N=~w)~n", [Id, Group, N]),
            erlang:monitor(process, Leader),
            Master ! {view, Group},
            slave(Id, Master, Leader, N + 1, {view, N, [Leader | Slaves], Group}, Slaves, Group)
    after ?timeout ->
        Master ! {error, "no reply from leader"}
    end.

leader(Id, Master, N, Slaves, Group) ->
    receive
        {mcast, Msg} ->
            bcast({msg, N, Msg}, Slaves),
            handle_acknowledgements({msg, N, Msg}, N, Slaves),
            Master ! Msg,
            leader(Id, Master, N + 1, Slaves, Group);
        {join, Wrk, Peer} ->
            Slaves2 = lists:append(Slaves, [Peer]),
            Group2 = lists:append(Group, [Wrk]),
            erlang:monitor(process, Peer),
            bcast({view, N, [self() | Slaves2], Group2}, Slaves2),
            Master ! {view, Group2},
            leader(Id, Master, N + 1, Slaves2, Group2);
        {ack, N, Pid} ->
            leader(Id, Master, N, Slaves, Group);
        stop ->
            ok
    end.

handle_acknowledgements({msg, N, Msg}, N, []) ->
    ok;
handle_acknowledgements({msg, N, Msg}, N, Slaves) ->
    receive
        {ack, N, Pid} ->
            Slaves2 = lists:delete(Pid, Slaves),
            handle_acknowledgements({msg, N, Msg}, N, Slaves2);
        {'DOWN', _Ref, process, Slave, _Reason} ->
            Slaves2 = lists:delete(Slave, Slaves),
            handle_acknowledgements({msg, N, Msg}, N, Slaves2)
    after ?timeout ->
        io:format("leader timeout for N=~w; retransmitting to ~p~n", [N, Slaves]),
        bcast({msg, N, Msg}, Slaves),
        handle_acknowledgements({msg, N, Msg}, N, Slaves)
    end.

bcast(Message, Slaves) ->
    lists:foreach(fun(Pid) -> maybe_send(Pid, Message) end, Slaves).

maybe_send(Pid, {msg, N, {change, _}} = Message) ->
    case get(dropped_change) of
        undefined ->
            put(dropped_change, true),
            io:format("dropping N=~w for ~p once~n", [N, Pid]),
            ok;
        true ->
            Pid ! Message
    end;
maybe_send(Pid, Message) ->
    Pid ! Message.

send_ack(Id, Leader, N) ->
    case ?drop_ack andalso (get(dropped_ack) == undefined) of
        true ->
            put(dropped_ack, true),
            io:format("~w dropping ack for N=~w once~n", [Id, N]),
            ok;
        false ->
            io:format("~w sending ack for N=~w~n", [Id, N]),
            Leader ! {ack, N, self()}
    end.

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
            send_ack(Id, Leader, I),
            slave(Id, Master, Leader, N, Last, Slaves, Group);
        {msg, N, Msg} ->
            io:format("~w received NEW message: ~w (N=~w) ~n", [Id, Msg, N]),
            % new message: save it as Last and increment N
            Master ! Msg,
            send_ack(Id, Leader, N),
            slave(Id, Master, Leader, N + 1, {msg, N, Msg}, Slaves, Group);
        {view, I, _, _} when I < N ->
            io:format("~w received old view: (I=~w, N=~w) ~n", [Id, I, N]),
            slave(Id, Master, Leader, N, Last, Slaves, Group);
        {view, N, [Leader | Slaves2], Group2} ->
            io:format("~w received NEW view: ~p (N=~w)~n", [Id, Group2, N]),
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
            bcast(Last, Rest),
            Master ! {view, Group},
            leader(Id, Master, N, Rest, Group);
        [Leader | Rest] ->
            io:format("~w is monitoring new Leader: ~w~n", [Id, Leader]),
            erlang:monitor(process, Leader),
            slave(Id, Master, Leader,  N, Last, Rest, Group)
    end.
