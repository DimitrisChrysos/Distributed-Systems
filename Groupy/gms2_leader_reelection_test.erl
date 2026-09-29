-module(gms2_leader_reelection_test).
-export([run/0]).

run() ->
    io:format("~n=== Starting GMS2 Test: Leader Re-election ===~n"),

    io:format("Spawning 3 nodes...~n"),
    L1 = test:first(1, gms2, 1000),
    timer:sleep(1500),
    _L2 = test:add(2, gms2, L1, 1000),
    timer:sleep(1500),
    _L3 = test:add(3, gms2, L1, 1000),

    %% Let the workers sync and generate some natural traffic
    timer:sleep(5000),

    io:format("~n-> CRASHING LEADER 1...~n"),
    L1 ! stop.
