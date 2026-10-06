-module(node_ring_test).

-export([
    run/1,
    addNode/2
]).

run(NumOfNodes) ->
    P1 = test:start(node2),
    register(chord1, P1),

    lists:foreach(
        fun(Node) ->
            spawn(fun() ->
                P = test:start(node2, P1),
                Name = list_to_atom("chord" ++ integer_to_list(Node)),
                register(Name, P)
            end)
        end,
        lists:seq(2, NumOfNodes)
    ),

    ok.

addNode(NodeId, ContactNode) ->
    P = test:start(node2, ContactNode),
    Name = list_to_atom("chord" ++ integer_to_list(NodeId)),
    register(Name, P).
