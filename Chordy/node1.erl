-module(node1).

-define(Stabilize, 1000).

% Node state: Id, Predecessor (nil | {PredKey, PredPid}), and Successor ({SuccKey, SuccPid}).

node(Id, Predecessor, Successor) ->
    receive
        {key, Qref, Peer} ->
            Peer ! {Qref, Id},
            node(Id, Predecessor, Successor);
        {notify, New} ->
            Pred = notify(New, Id, Predecessor),
            node(Id, Pred, Successor);
        {request, Peer} ->
            request(Peer, Predecessor),
            node(Id, Predecessor, Successor);
        {status, Pred} ->
            Succ = stabilize(Pred, Id, Successor),
            node(Id, Predecessor, Succ);
        stabilize ->
            stabilize(Successor),
            node(Id, Predecessor, Successor)
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
                    Spid ! {notify, {Id, self()}}
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
