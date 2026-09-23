-module(test_vector).
-export([run/2]).

% report on your initial observations
run(Sleep, Jitter) ->
    Log = loggy:start([john, paul, ringo, george], vect),
    A = worker:start(john, Log, 13, Sleep, Jitter, vect),
    B = worker:start(paul, Log, 23, Sleep, Jitter, vect),
    C = worker:start(ringo, Log, 36, Sleep, Jitter, vect),
    D = worker:start(george, Log, 49, Sleep, Jitter, vect),
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