-module(gms3_test).
-export([run/0]).

run() ->
    random:seed(42, 42, 42),
    io:format("~n=== Starting GMS3 Test: Reliable Multicast ===~n"),

    io:format("Spawning 4 nodes...~n"),
    L1 = test:first(1, gms3, 1000),
    timer:sleep(1500),
    L2 = test:add(2, gms3, L1, 1000),
    timer:sleep(1500),
    _L3 = test:add(3, gms3, L1, 1000),
    timer:sleep(1500),
    _L4 = test:add(4, gms3, L1, 1000),

    %% Allow time for workers to build up the sequence (N) counters naturally

    io:format("~nSleeping for 5 seconds...~n"),
    timer:sleep(5000),

    io:format("Spawning node 5~n"),
    % when we reach this point, node 1 has died so use node 2, the new leader
    _L5 = test:add(5, gms3, L2, 1000),
    timer:sleep(500),
    io:format("Spawning node 6~n"),
    _L6 = test:add(6, gms3, L2, 1000).
