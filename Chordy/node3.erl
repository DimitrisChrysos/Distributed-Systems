-module(node3).
-export([start/1, start/2]).

-define(Stabilize, 1000).
-define(Timeout, 10000).

% Node state: Id, Predecessor (nil | {PredKey, PredRef, PredPid}), Successor ({SuccKey, SuccRef, SuccPid}), Next ({NxKey, NxPid}), and Store (list of tuples {Key, Value}).

node(Id, Predecessor, Successor, Next, Store) ->
    receive
        {key, Qref, Peer} ->
            Peer ! {Qref, Id},
            node(Id, Predecessor, Successor, Next, Store);
        {notify, New} ->
            {Pred, NewStore} = notify(New, Id, Predecessor, Store),
            node(Id, Pred, Successor, Next, NewStore);
        {request, Peer} ->
            request(Peer, Predecessor, Successor),
            node(Id, Predecessor, Successor, Next, Store);
        {status, Pred, Nx} ->
            {Succ, Nxt} = stabilize(Pred, Id, Successor, Nx),
            node(Id, Predecessor, Succ, Nxt, Store);
        stabilize ->
            stabilize(Successor),
            node(Id, Predecessor, Successor, Next, Store);
        probe ->
            create_probe(Id, Successor),
            node(Id, Predecessor, Successor, Next, Store);
        {probe, Id, Nodes, T} ->
            remove_probe(T, Nodes),
            node(Id, Predecessor, Successor, Next, Store);
        {probe, Ref, Nodes, T} -> 
            forward_probe(Ref, T, Nodes, Id, Successor),
            node(Id, Predecessor, Successor, Next, Store);
        {add, Key, Value, Qref, Client} ->
            Added = add(Key, Value, Qref, Client, Id, Predecessor, Successor, Store),
            node(Id, Predecessor, Successor, Next, Added);
        {lookup, Key, Qref, Client} ->
            lookup(Key, Qref, Client, Id, Predecessor, Successor, Store),
            node(Id, Predecessor, Successor, Next, Store);
        {handover, Elements} ->
            Merged = storage:merge(Store, Elements),
            node(Id, Predecessor, Successor, Next, Merged);
        {'DOWN', Ref, process, _, _} ->
            {Pred, Succ, Nxt} = down(Ref, Predecessor, Successor, Next),
            node(Id, Pred, Succ, Nxt, Store)
    end.

create_probe(Id, Successor) ->
    {_, _, Spid} = Successor,
    Spid ! {probe, Id, [self()], erlang:system_time(microsecond)}.

remove_probe(T, Nodes) ->
    ElapsedTime = erlang:system_time(microsecond) - T,
    io:format("Total probe round-trip duration: ~p microseconds~n", [ElapsedTime]),
    io:format("Round trip probe nodes: ~p~n", [Nodes]).

forward_probe(Ref, T, Nodes, _Id, Successor) ->
    {_, _, Spid} = Successor,
    ElapsedTime = erlang:system_time(microsecond) - T,
    io:format("Elapsed probe duration: ~p microseconds~n", [ElapsedTime]),
    io:format("Current round trip probe nodes: ~p~n", [Nodes]),
    Spid ! {probe, Ref, [self() | Nodes], T}.


add(Key, Value, Qref, Client, Id, {Pkey, _, _}, {_, _, Spid}, Store) ->
    case key:between(Key, Pkey, Id) of
        true ->
            io:format("~w (~w) is responsible for key ~w~n", [Id, self(), Key]),
            Client ! {Qref, ok},
            storage:add(Key, Value, Store);
        false ->
            io:format("~w (~w) sends key-value to ~w~n", [Id, self(), Spid]),
            Spid ! {add, Key, Value, Qref, Client},
            Store
    end.

lookup(Key, Qref, Client, Id, {Pkey, _, _}, Successor, Store) ->
    case key:between(Key, Pkey, Id) of
        true ->
            Result = storage:lookup(Key, Store),
            Client ! {Qref, Result};
        false ->
            {_, _, Spid} = Successor,
            Spid ! {lookup, Key, Qref, Client}
    end.

stabilize(Pred, Id, Successor, Nx) ->
    {Skey, SRef, Spid} = Successor,
    case Pred of
        nil ->
            %
            % successor is not pointing to a predecessor - notify it about our existence
            Spid ! {notify, {Id, self()}},
            {Successor, Nx};
        {Id, _} ->
            %
            % successor points back at us - no need to do anything
            {Successor, Nx};
        {Skey, _} ->
            %
            % successor points to itself - notify them about our existence
            Spid ! {notify, {Id, self()}},
            {Successor, Nx};
        {Xkey, Xpid} ->
            % successor points to a different node
            case key:between(Xkey, Id, Skey) of
                true ->
                    drop(SRef),
                    NewSuccessor = {Xkey, monitor(Xpid), Xpid},
                    NewNext = {Skey, Spid},

                    %
                    % node is between us and successor - adopt the node as our successor
                    % we use nil in order to notify the node about our existence.
                    % maybe it would be better to pass its real predeccesor (do we know it?).
                    stabilize(nil, Id, NewSuccessor, NewNext);
                false ->
                    %
                    % node is before us - notify successor about our existence
                    Spid ! {notify, {Id, self()}},
                    {Successor, Nx}
            end
    end.

schedule_stabilize() ->
    timer:send_interval(?Stabilize, self(), stabilize).

stabilize({_, _, Spid}) ->
    Spid ! {request, self()}.

request(Peer, Predecessor, Successor) ->
    {Skey, _, Spid} = Successor,
    case Predecessor of
        nil ->
            Peer ! {status, nil, {Skey, Spid}};
        {Pkey, _, Ppid} ->
            Peer ! {status, {Pkey, Ppid}, {Skey, Spid}}
    end.

notify({Nkey, Npid}, Id, Predecessor, Store) ->
    case Predecessor of
        nil ->
            Keep = handover(Id, Store, Nkey, Npid),
            {{Nkey, monitor(Npid), Npid}, Keep};
        {Pkey, Pref, _} ->
            case key:between(Nkey, Pkey, Id) of
                true ->
                    Keep = handover(Id, Store, Nkey, Npid),
                    drop(Pref),
                    {{Nkey, monitor(Npid), Npid}, Keep};
                false ->
                    {Predecessor, Store}
            end
    end.

handover(Id, Store, Nkey, Npid) ->
    {Rest, Keep} = storage:split(Id, Nkey, Store),
    Npid ! {handover, Rest},
    Keep.

start(Id) ->
    start(Id, nil).

start(Id, Peer) ->
    timer:start(),
    spawn(fun() -> init(Id, Peer) end).

init(Id, Peer) ->
    Predecessor = nil,
    {ok, {Skey, Spid}} = connect(Id, Peer), % we might need to handle the error case here too instead of just printing the error
    Successor = {Skey, monitor(Spid), Spid},
    Next = {Skey, Spid},
    schedule_stabilize(),
    node(Id, Predecessor, Successor, Next, storage:create()).

connect(Id, nil) ->
    {ok, {Id, self()}};
connect(_Id, Peer) ->
    Qref = make_ref(),
    Peer ! {key, Qref, self()},
    receive {Qref, Skey} ->
        {ok, {Skey, Peer}}
    after ?Timeout ->
        io:format("Time out: no response~n",[])
    end.

monitor(Pid) ->
    erlang:monitor(process, Pid).

drop(nil) -> 
    ok;
drop(Ref) ->
    erlang:demonitor(Ref, [flush]).

down(Ref, {_, Ref, _}, Successor, Next) ->
    {nil, Successor, Next};
down(Ref, Predecessor, {_, Ref, _}, {Nkey, Npid}) ->
    Nref = monitor(Npid),
    self() ! stabilize,
    {Predecessor, {Nkey, Nref, Npid}, nil}.