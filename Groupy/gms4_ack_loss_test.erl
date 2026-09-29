-module(gms4_ack_loss_test).
-export([run/0]).

run() ->
    io:format("~n=== GMS4 lost-acknowledgement recovery demo ===~n"),

    W1 = test:first(1, gms4, 1000000),
    timer:sleep(1000),
    _W2 = test:add(2, gms4, W1, 1000000),

    % The state-request acknowledgement is dropped once, then retried.
    timer:sleep(7000),
    io:format("Demo finished.~n"),
    ok.
