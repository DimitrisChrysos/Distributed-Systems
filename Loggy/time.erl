-module(time).
-export([zero/0, inc/2, leq/2, merge/2, clock/1, update/3, safe/2, zero/1, inc/3, merge/3, safe/3, leq/3, clock/2]).

% return an initial Lamport value (could it be 0)
zero() -> 0.

% return an initial vector clock value (map of zeroes)
zero(Nodes) -> maps:from_keys(Nodes, 0).

% return the time T incremented by one (you will probably
% ignore the Name, but we will use it later)
inc(Name, T) -> T + 1.

% increment the vector counter of 'Pid' by 1, and return the entire vector
inc(vector, Pid, VectorCounter) ->
    maps:update_with(Pid, fun(V) -> inc(Pid, V) end, VectorCounter).

% true if Ti is less than or equal to Tj
leq(Ti, Tj) -> Ti =< Tj.

% merge the two Lamport time stamps (i.e., take the
% maximum value)
merge(Ti, Tj) ->
    case leq(Ti, Tj) of
        true -> Tj;
        false -> Ti
    end.

% merge the two vector clocks (i.e., update each element
% in the current vector by taking the maximum of the value
% in its own vector clock and the value in the vector in the
% received vector (for every element).
% NOTE: Before calling this method, we should first call time:inc(vector, Pid, VectorCounter)
% according to the vector clock algorithm
merge(vector, VectorCounterCurrent, VectorCounterSender) ->
    maps:merge_with(fun(_Key, X, Y) -> max(X, Y) end, VectorCounterCurrent, VectorCounterSender).

% return a clock that can keep track of the nodes
clock(Nodes) ->
    maps:from_keys(Nodes, zero()).

% return a clock that can keep track of the vector counter of each node
clock(vector, Nodes) ->
    maps:from_keys(Nodes, zero(Nodes)).

% return a clock that has been updated given that we have received a log message from a node at a given time
update(Node, Time, Clock) ->
    maps:put(Node, Time, Clock).

% is it safe to log an event that happened at a given time, true or false?
safe(Time, Clock) ->
    lists:all(fun(NodeTime) -> leq(Time, NodeTime) end, maps:values(Clock)).

leq(vector, A, B) ->
    maps:fold(fun(K, V, Acc) -> Acc andalso V =< maps:get(K, B, 0) end, true, A).
safe(vector, VectorCounter, Clock) ->
    lists:all(fun(Vector) -> leq(vector, VectorCounter, Vector) end, maps:values(Clock)).
