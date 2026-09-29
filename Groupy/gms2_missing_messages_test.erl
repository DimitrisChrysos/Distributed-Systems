-module(gms2_missing_messages_test).
-export([run/0]).

run() ->
    io:format("~n=== GMS2 missing-message demo ===~n"),

    %% Avoid random colour changes until all four nodes have joined.
    InitialSleep = 100000,
    W1 = test:more(4, gms2, InitialSleep),
    timer:sleep(2000),

    io:format("Group ready. Increasing traffic to trigger a leader crash...~n"),
    test:sleep(W1, 1000),
    timer:sleep(5000),

    io:format("Demo finished.~n"),
    ok.
