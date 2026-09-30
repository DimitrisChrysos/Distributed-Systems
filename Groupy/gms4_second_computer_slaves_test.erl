-module(gms4_second_computer_slaves_test).
-export([run/1]).

run(Leader) ->
    io:format("~n=== GMS4 Multiple Computers Test: Computer with Slaves ===~n"),

    %% A long initial delay prevents colour changes while the group forms.
    % W1 = test:first(1, gms4, 100000),
    % timer:sleep(500),
    % _W2 = test:add(2, gms4, W1, 100000),
    % timer:sleep(500),
    % _W3 = test:add(3, gms4, W1, 100000),
    % timer:sleep(500),
    % _W4 = test:add(4, gms4, W1, 100000),

    % timer:sleep(5000),
    io:format("Worker 5 requesting leader ~w to join group...~n", [Leader]),
    _W5 = test:add(5, gms4, Leader, 100000),
    % timer:sleep(1000),
    io:format("Node 5 joined group.~n"),
    % test:sleep(W1, 100),
    % timer:sleep(4000),

    io:format("Demo finished.~n"),
    ok.
