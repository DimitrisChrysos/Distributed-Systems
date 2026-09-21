-module(test_vector).
-export([run/2]).

% report on your initial observations
run(Sleep, Jitter) ->
    Log = loggy:start(vector, [john, paul, ringo, george]),
    A = worker:start(vector, john, Log, 13, Sleep, Jitter),
    B = worker:start(vector, paul, Log, 23, Sleep, Jitter),
    C = worker:start(vector, ringo, Log, 36, Sleep, Jitter),
    D = worker:start(vector, george, Log, 49, Sleep, Jitter),
    io:format("john=~w, paul=~w, ringo=~w, george=~w~n", [A, B, C, D]),
    worker:peers(A, [B, C, D]),
    worker:peers(B, [A, C, D]),
    worker:peers(C, [A, B, D]),
    worker:peers(D, [A, B, C]),
    timer:sleep(5000),
    loggy:stop(Log),
    worker:stop(A),
    worker:stop(B),
    worker:stop(C),
    worker:stop(D).