-module(gms2_missing_messages_test).
-export([run/0]).

run() ->
    io:format("~n=== GMS2 missing-message demo ===~n"),

    W1 = test:first(1, gms2, 100000),
    timer:sleep(1000),
    _W2 = test:add(2, gms2, W1, 100000),
    timer:sleep(1000),
    _W3 = test:add(3, gms2, W1, 100000),
    timer:sleep(1000),
    _W4 = test:add(4, gms2, W1, 100000),
    timer:sleep(1000),

    io:format("Group ready. Increasing traffic to trigger a leader crash...~n"),
    test:sleep(W1, 1000),
    timer:sleep(5000),

    io:format("Demo finished.~n"),
    ok.
