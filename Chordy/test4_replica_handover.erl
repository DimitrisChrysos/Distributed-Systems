% Test: Replica handover when a node joins.
%
% Run these:
%   erlc key.erl storage.erl node4.erl test4_replica_handover.erl
%   erl
%   test4_replica_handover:run().
%
% Explanation:
%   The value is added before node 20 joins. It is initially stored at
%   node 10 and replicated at node 30. When node 20 joins between them,
%   it must receive node 30's replica of node 10's store. Killing node 10
%   must therefore not lose key 5.

-module(test4_replica_handover).
-export([run/0]).

run() ->
    P1 = node4:start(10),
    timer:sleep(2000),
    P3 = node4:start(30, P1),
    timer:sleep(6000),

    AddRef = make_ref(),
    P1 ! {add, 5, before_join, AddRef, self()},
    receive
        {AddRef, ok} ->
            ok
    end,

    P2 = node4:start(20, P1),
    timer:sleep(5000),
    exit(P1, kill),
    timer:sleep(5000),

    LookupRef = make_ref(),
    P2 ! {lookup, 5, LookupRef, self()},
    Result = receive
        {LookupRef, {5, before_join}} ->
            io:format("PASS: the replica was transferred during the join.~n"),
            ok;
        {LookupRef, Other} ->
            io:format("FAIL: expected {5, before_join}, got ~p.~n", [Other]),
            {error, Other}
    end,
    exit(P2, kill),
    exit(P3, kill),
    Result.
