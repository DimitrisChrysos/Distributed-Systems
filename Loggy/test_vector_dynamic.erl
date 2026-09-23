-module(test_vector_dynamic).
-export([run/2]).

run(Sleep, Jitter) ->
    Log = loggy:start([], vect),
    A = worker:start(john, Log, 13, Sleep, Jitter, vect),
    B = worker:start(paul, Log, 23, Sleep, Jitter, vect),
    worker:peers(A, [B]),
    worker:peers(B, [A]),
    timer:sleep(1000),
    C = worker:start(ringo, Log, 36, Sleep, Jitter, vect),
    D = worker:start(george, Log, 49, Sleep, Jitter, vect),
    worker:peers(C, [A, B, D]),
    worker:peers(D, [A, B, C]),
    timer:sleep(5000),
    worker:stop(A),
    worker:stop(B),
    worker:stop(C),
    worker:stop(D),
    timer:sleep(200),
    loggy:stop(Log).
