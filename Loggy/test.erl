-module(test).
-export([run/2]).

% report on your initial observations
run(Sleep, Jitter) ->
    Log = loggy:start([john, paul, ringo, george], time),
    A = worker:start(john, Log, 13, Sleep, Jitter, time),
    B = worker:start(paul, Log, 23, Sleep, Jitter, time),
    C = worker:start(ringo, Log, 36, Sleep, Jitter, time),
    D = worker:start(george, Log, 49, Sleep, Jitter, time),
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