-module(gms3_complex_test).
-export([run/0]).

run() ->
    io:format("~n=== GMS3 four-node group with delayed joins ===~n"),

    %% A long initial delay prevents colour changes while the group forms.
    W1 = test:first(1, gms3, 100000),
    timer:sleep(500),
    _W2 = test:add(2, gms3, W1, 100000),
    timer:sleep(500),
    _W3 = test:add(3, gms3, W1, 100000),
    timer:sleep(500),
    _W4 = test:add(4, gms3, W1, 100000),

    io:format("Four-node group ready. Wait before node 5 joins...~n"),
    timer:sleep(3000),
    _W5 = test:add(5, gms3, W1, 100000),
    timer:sleep(1000),

    io:format("Node 5 joined. Increasing traffic to trigger leader crashes...~n"),
    test:sleep(W1, 100),
    timer:sleep(4000),

    io:format("Demo finished.~n"),
    ok.
