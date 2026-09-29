-module(gms4_loss_test).
-export([run/0]).

run() ->
    io:format("~n=== GMS4 lost-message recovery demo ===~n"),

    W1 = test:first(1, gms4, 1000000),
    timer:sleep(1000),
    _W2 = test:add(2, gms4, W1, 1000000),
    timer:sleep(1000),
    _W3 = test:add(3, gms4, W1, 1000000),
    timer:sleep(1000),

    io:format("Group ready. Triggering a deliberately lost colour change...~n"),
    test:sleep(W1, 1000),

    timer:sleep(7000),
    io:format("Demo finished.~n"),
    ok.
