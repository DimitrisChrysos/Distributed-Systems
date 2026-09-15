-module(routy_tests).

-export([run/0]).

run() ->
    io:format("~n=== Routy demo: five-router network ===~n", []),
    setup(),
    io:format("~n1) Connecting the topology~n", []),
    connect_topology(),
    print_statuses([r1, r2, r3, r4, r5]),
    io:format("~n2) Broadcasting link-state information~n", []),
    broadcast_all([r1, r2, r3, r4, r5]),
    io:format("~n3) Recomputing routing tables~n", []),
    update_all([r1, r2, r3, r4, r5]),
    print_statuses([r1, r2, r3, r4, r5]),
    io:format("~n4.1) Sending a multi-hop message from athens to katerini~n", []),
    r1 ! {send, katerini, "hello from athens"},
    timer:sleep(200),
    io:format("~n4.2) Sending a multi-hop message from patras to athens~n", []),
    r2 ! {send, athens, "hello from patras"},
    timer:sleep(200),
    io:format("~n5) Trying an unknown destination~n", []),
    r1 ! {send, nowhere, "this should be dropped"},
    timer:sleep(200),
    io:format("~n6) Killing a router to simulate a crash~n", []),
    % exit(whereis(r5), kill),
    routy:stop(r5),
    timer:sleep(300),
    print_statuses([r1, r2, r3, r4]), % r5 is dead so we cant 'status' it
    io:format("~n7) Broadcasting the links for all nodes~n", []),
    broadcast_all([r3]),
    print_statuses([r1, r2, r3, r4]), % r5 is dead so we cant 'status' it
    io:format("~n8) Rebuilding routing tables after the failure~n", []),
    update_all([r1, r2, r3, r4]), % r5 is dead
    print_statuses([r1, r2, r3, r4]),
    io:format("~n9) Restarting the dead router and rejoining the network~n", []),


    % here, something weird happens. For some reason, when we
    % restart larisa and add it to thessaloniki again, thessaloniki
    % reinserts the tuples {athens, larisa}, {patras, larisa} to its table (after broadcast+update),
    % even though the link larisa -> athens has not been created. This is because
    % thessaloniki's map is not updated after larisa dies (only thessaloniki's interfaces list is updated)
    % and thus when we recreate thessalonikis's table when larisa respawns, it is done
    % with the old map, where larisa had the link larisa -> athens.
    % We probably need to update the map whenever we receive a DOWN message in order
    % to remove the dead processes from it.
    % Or maybe this is the expected behaviour and whenever a dead process respawns, it
    % keeps its old connections.

    routy:start(r5, larisa),
    r3 ! {add, larisa, whereis(r5)},
    broadcast_all([r1, r2, r3, r4, r5]),
    update_all([r1, r2, r3, r4, r5]),
    print_statuses([r1, r2, r3, r4, r5]),
    io:format("~n10) Cleanup~n", []),
    teardown(),
    io:format("~nDemo complete.~n", []).

setup() ->
    lists:foreach(
        fun({Reg, Name}) ->
            case whereis(Reg) of
                undefined -> routy:start(Reg, Name);
                _Pid -> ok
            end
        end,
        [{r1, athens}, {r2, patras}, {r3, thessaloniki}, {r4, katerini}, {r5, larisa}]
    ),
    ok.

connect_topology() ->
    % athens -> patras
    r1 ! {add, patras, whereis(r2)},
    % patras -> thessaloniki
    r2 ! {add, thessaloniki, whereis(r3)},
    % thessaloniki -> katerini
    % thessaloniki -> larisa
    r3 ! {add, katerini, whereis(r4)},
    r3 ! {add, larisa, whereis(r5)},

    % larisa -> athens
    r5 ! {add, athens, whereis(r1)},

    % patras -> katerini
    r2 ! {add, katerini, whereis(r4)},
    timer:sleep(100),
    ok.

broadcast_all(Routers) ->
    lists:foreach(
        fun(Node) ->
            io:format("broadcast from ~p~n", [Node]),
            routy:broadcast(Node),
            timer:sleep(80)
        end,
        % [r1, r2, r3, r4, r5]
        Routers
    ),
    ok.

update_all(Routers) ->
    lists:foreach(
        fun(Node) ->
            io:format("update from ~p~n", [Node]),
            routy:update(Node),
            timer:sleep(80)
        end,
        % [r1, r2, r3, r4, r5]
        Routers
    ),
    ok.

print_statuses(Routers) ->
    lists:foreach(
        fun(Node) ->
            io:format("~n-- status for ~p --~n", [Node]),
            % io:format("~p~n", [status_for(Node)])
            io:format("~p~n", [routy:status(Node)])
        end,
        % [r1, r2, r3, r4, r5]
        Routers
    ),
    ok.

% status_for(Node) ->
%     Node ! {status, self()},
%     receive
%         {status, State} ->
%             State
%     after 2000 ->
%         {status_timeout, Node}
%     end.

teardown() ->
    lists:foreach(
        fun(Reg) ->
            case whereis(Reg) of
                undefined -> ok;
                _ -> routy:stop(Reg)
            end
        end,
        [r1, r2, r3, r4, r5]
    ),
    ok.
