-module(gms3_simple_test).
-export([run/0]).

run() ->
    io:format("~n=== GMS3 reliable multicast demo ===~n"),

    %% A long initial delay prevents colour changes while the group forms.
    W1 = test:first(1, gms3, 100000),
    timer:sleep(500),
    _W2 = test:add(2, gms3, W1, 100000),
    timer:sleep(500),
    _W3 = test:add(3, gms3, W1, 100000),
    timer:sleep(3000),

    io:format("Group ready. Increasing traffic to trigger a leader crash...~n"),
    test:sleep(W1, 1000),
    timer:sleep(10000),

    io:format("Demo finished.~n"),
    ok.
