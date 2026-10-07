% Test: Replication after a predecessor fails.
%
% Run these:
%   erlc key.erl storage.erl node4.erl test4_replica_after_predecessor_fail.erl
%   erl
%   test4_replica_after_predecessor_fail:run().
%
% Explanation
%   - The test creates a ring with IDs 10, 20, and 30.
%   - Key 15 belongs to node 20, which replicates it to node 30.
%   - After node 20 is killed, a lookup must still return the 
%     value through node 10
%   - This is true because the repaired ring will route
%     to node 30 which now owns the key and return the 
%     {15, replicated_value} to the client).

-module(test4_replica_after_predecessor_fail).
-export([run/0]).

run() ->
    P1 = node4:start(10),
    timer:sleep(2000),
    P2 = node4:start(20, P1),
    timer:sleep(2000),
    P3 = node4:start(30, P1),
    timer:sleep(4000),

    AddRef = make_ref(),
    P1 ! {add, 15, replicated_value, AddRef, self()},
    receive
        {AddRef, ok} ->
            ok
    end,

    exit(P2, kill),
    timer:sleep(4000),

    LookupRef = make_ref(),
    P1 ! {lookup, 15, LookupRef, self()},
    Result = receive
        {LookupRef, {15, replicated_value}} ->
            io:format("PASS: the replica survived node 20 failing.~n"),
            ok;
        {LookupRef, Other} ->
            io:format("FAIL: expected {15, replicated_value}, got ~p.~n", [Other]),
            {error, Other}
    end,
    exit(P1, kill),
    exit(P3, kill),
    Result.
