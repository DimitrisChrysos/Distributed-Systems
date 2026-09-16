-module(dijkstra).
-export([table/2, route/2]).

% returns the length of the shortest path to the
% node or 0 if the node is not found.
entry(Node, Sorted) ->
    case lists:keyfind(Node, 1, Sorted) of
        {_, Length, _} ->
            Length;
        false ->
            0
    end.

% replaces the entry for Node in Sorted with a new entry having a new length N
% and Gateway. The resulting list should, of course, be sorted.
replace(Node, N, Gateway, Sorted) ->
    WithoutOldNode = lists:keydelete(Node, 1, Sorted),
    insert({Node, N, Gateway}, WithoutOldNode).

insert(Entry, []) ->
    [Entry];

insert({_, N, _} = Entry, [{_, HeadN, _} = Head | Tail])
    when N < HeadN ->
    [Entry, Head | Tail];

insert(Entry, [Head | Tail]) ->
    [Head | insert(Entry, Tail)].

% update the list Sorted given the information that Node can be reached in N
% hops using Gateway. If no entry is found, then no new entry is added. Only
% if we have a better (shorter) path should we replace the existing entry
update(Node, N, Gateway, Sorted) ->
    Current = entry(Node, Sorted),
    case N < Current of
        true ->
            replace(Node, N, Gateway, Sorted);
        false ->
            Sorted
    end.

update_nodes([], _, _, Sorted) ->
    Sorted;
update_nodes([H | T], N, Gateway, Sorted) ->
    UpdatedSorted = update(H, N, Gateway, Sorted),
    update_nodes(T, N, Gateway, UpdatedSorted).

iterate([], _, Table) ->
    Table;
iterate([{_, inf, _} | _], _, Table) ->
    Table;
iterate([{Node, Length, Gateway} | T], Map, Table) ->
    Neighbors = map:reachable(Node, Map),
    UpdatedSorted = update_nodes(Neighbors, Length + 1, Gateway, T),
    iterate(UpdatedSorted, Map, [{Node, Gateway} | Table]).

% construct a routing table given the gateways and a map.
table(Gateways, Map) ->
    Nodes = map:all_nodes(Map),

    Sorted = lists:map(
        fun(Node) ->
            {Node, inf, unknown}
        end,
        Nodes
    ),

    InitialSorted = lists:foldl(
        fun(Gateway, Acc) ->
            replace(Gateway, 0, Gateway, Acc)
        end,
        Sorted,
        Gateways
    ),

    iterate(InitialSorted, Map, []).

% search the routing table and return the gateway suitable to route messages
% to a node. If a gateway is found, we should return {ok, Gateway};
% otherwise, we return notfound.
route(Node, Table) ->
    case lists:keyfind(Node, 1, Table) of
        {Node, Gateway} ->
            {ok, Gateway};
        false ->
            notfound
    end.
