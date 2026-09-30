-module(gms4_first_computer_leader_test).
-export([run/0]).

run() ->
    io:format("~n=== GMS4 Multiple Computers Test: Computer with Leader and some Slaves ===~n"),

    %% A long initial delay prevents colour changes while the group forms.
    W1 = test:first(1, gms4, 100000),
    % io:format("Leader PID: ~w~n", [W1]),
    register(leader, W1),
    timer:sleep(500),
    _W2 = test:add(2, gms4, W1, 100000),
    timer:sleep(500),
    _W3 = test:add(3, gms4, W1, 100000),
    timer:sleep(500),
    _W4 = test:add(4, gms4, W1, 100000),

    io:format("Four-node group ready. Wait 5 seconds for node 5 to join...~n"),
    timer:sleep(10000),
    % _W5 = test:add(5, gms4, W1, 100000),
    % timer:sleep(1000),

    io:format("Increasing traffic to trigger leader crashes...~n"),
    test:sleep(W1, 5000),
    timer:sleep(4000),

    io:format("Demo finished.~n"),
    ok.
