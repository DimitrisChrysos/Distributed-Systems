-module(map).
-export([new/0, update/3, reachable/2, all_nodes/1]).

% returns an empty map (an empty list)
new() ->
    [].

% updates the Map to reflect that Node has directional links to all nodes 
% in the list Links. The old entry is removed.
update(Node, Links, Map) ->
    [{Node, Links} | lists:keydelete(Node, 1, Map)].

% returns the list of nodes directly reachable from Node.
reachable(Node, Map) ->
    case lists:keyfind(Node, 1, Map) of
        {Node, Links} ->
            Links;
        false ->
            []
    end.

% returns a list of all nodes in the Map, also the ones without outgoing 
% links. So if berlin is linked to london but london does not have any 
% outgoing links (and thus no entry in the list), london should still 
% be in the returned list.
all_nodes(Map) ->
    lists:foldl(
        fun({Node, Links}, Acc) -> 
            add_nodes([Node | Links], Acc)
        end,
        [],
        Map).

add_nodes(Nodes, Acc) ->
    lists:foldl(
        fun(Node, NodesAcc) ->
            case lists:member(Node, NodesAcc) of
                true ->
                    NodesAcc;
                false ->
                    [Node | NodesAcc]
            end
        end,
        Acc,
        Nodes).


all_nodes(Map) ->
    ResultingSet = lists:foldl(fun({Node, Links}, Set) -> sets:union(Set, sets:from_list([Node | Links])) end, sets:new(), Map),
    sets:to_list(ResultingSet).