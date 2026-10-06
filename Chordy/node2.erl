-module(node2).
-export([start/1, start/2]).

-define(Stabilize, 1000).
-define(Timeout, 10000).

% Node state: Id, Predecessor (nil | {PredKey, PredPid}), and Successor ({SuccKey, SuccPid}).

node(Id, Predecessor, Successor, Store) ->
    receive
        {key, Qref, Peer} ->
            Peer ! {Qref, Id},
            node(Id, Predecessor, Successor, Store);
        {notify, New} ->
            Pred = notify(New, Id, Predecessor),
            node(Id, Pred, Successor, Store);
        {request, Peer} ->
            request(Peer, Predecessor),
            node(Id, Predecessor, Successor, Store);
        {status, Pred} ->
            Succ = stabilize(Pred, Id, Successor),
            node(Id, Predecessor, Succ, Store);
        stabilize ->
            stabilize(Successor),
            node(Id, Predecessor, Successor, Store);
        probe ->
            create_probe(Id, Successor),
            node(Id, Predecessor, Successor, Store);
        {probe, Id, Nodes, T} ->
            remove_probe(T, Nodes),
            node(Id, Predecessor, Successor, Store);
        {probe, Ref, Nodes, T} -> 
            forward_probe(Ref, T, Nodes, Id, Successor),
            node(Id, Predecessor, Successor, Store);
        {add, Key, Value, Qref, Client} ->
            Added = add(Key, Value, Qref, Client, Id, Predecessor, Successor, Store),
            node(Id, Predecessor, Successor, Added);
        {lookup, Key, Qref, Client} ->
            lookup(Key, Qref, Client, Id, Predecessor, Successor, Store),
            node(Id, Predecessor, Successor, Store)
    end.

create_probe(Id, Successor) ->
    {_, Spid} = Successor,
    Spid ! {probe, Id, [self()], erlang:system_time(microsecond)}.

remove_probe(T, Nodes) ->
    ElapsedTime = erlang:system_time(microsecond) - T,
    io:format("Total probe round-trip duration: ~p microseconds~n", [ElapsedTime]),
    io:format("Round trip probe nodes: ~p~n", [Nodes]).

forward_probe(Ref, T, Nodes, _Id, Successor) ->
    {_, Spid} = Successor,
    ElapsedTime = erlang:system_time(microsecond) - T,
    io:format("Elapsed probe duration: ~p microseconds~n", [ElapsedTime]),
    io:format("Current round trip probe nodes: ~p~n", [Nodes]),
    Spid ! {probe, Ref, [self() | Nodes], T}.


add(Key, Value, Qref, Client, Id, {Pkey, _}, {_, Spid}, Store) ->
    case key:between(Key, Pkey, Id) of
        true ->
            io:format("~w (~w) is responsible for key ~w~n", [Id, self(), Key]),
            Client ! {Qref, ok},
            [{Key, Value} | Store];
        false ->
            io:format("~w (~w) sends key-value to ~w~n", [Id, self(), Spid]),
            Spid ! {add, Key, Value, Qref, Client},
            Store
    end.

lookup(Key, Qref, Client, Id, {Pkey, _}, Successor, Store) ->
    case key:between(Key, Pkey, Id) of
        true ->
            Result = storage:lookup(Key, Store),
            Client ! {Qref, Result};
        false ->
            {_, Spid} = Successor,
            Spid ! {lookup, Key, Qref, Client}
    end.

stabilize(Pred, Id, Successor) ->
    {Skey, Spid} = Successor,
    case Pred of
        nil ->
            %
            % successor is not pointing to a predecessor - notify it about our existence
            Spid ! {notify, {Id, self()}},
            Successor;
        {Id, _} ->
            %
            % successor points back at us - no need to do anything
            Successor;
        {Skey, _} ->
            %
            % successor points to itself - notify them about our existence
            Spid ! {notify, {Id, self()}},
            Successor;
        {Xkey, _Xpid} ->
            % successor points to a different node
            case key:between(Xkey, Id, Skey) of
                true ->
                    %
                    % node is between us and successor - adopt the node as our successor
                    % we use nil in order to notify the node about our existence.
                    % maybe it would be better to pass its real predeccesor (do we know it?).
                    stabilize(nil, Id, Pred);
                false ->
                    %
                    % node is before us - notify successor about our existence
                    Spid ! {notify, {Id, self()}},
                    Successor
            end
    end.

schedule_stabilize() ->
    timer:send_interval(?Stabilize, self(), stabilize).

stabilize({_, Spid}) ->
    Spid ! {request, self()}.

request(Peer, Predecessor) ->
    case Predecessor of
        nil ->
            Peer ! {status, nil};
        {Pkey, Ppid} ->
            Peer ! {status, {Pkey, Ppid}}
    end.

notify({Nkey, Npid}, Id, Predecessor) -> 
    case Predecessor of
        nil ->
            {Nkey, Npid};
        {Pkey, _} ->
            case key:between(Nkey, Pkey, Id) of
                true ->
                    {Nkey, Npid};
                false ->
                    Predecessor
            end
    end.

start(Id) ->
    start(Id, nil).

start(Id, Peer) ->
    timer:start(),
    spawn(fun() -> init(Id, Peer) end).

init(Id, Peer) ->
    Predecessor = nil,
    {ok, Successor} = connect(Id, Peer), % we might need to handle the error case here too instead of just printing the error
    schedule_stabilize(),
    node(Id, Predecessor, Successor, storage:create()).

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
