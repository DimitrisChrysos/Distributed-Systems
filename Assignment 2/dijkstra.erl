-module(dijkstra).
-export([replace/4, update/4]).

% replaces the entry for Node in Sorted with a new entry having a new length N 
% and Gateway. The resulting list should, of course, be sorted.
replace(Node, N, Gateway, Sorted) ->
    WithoutOldNode = lists:keydelete(Node, 1, Sorted),
    insert({Node, N, Gateway}, WithoutOldNode).

insert(Entry, []) ->
    [Entry];

insert({_, N, _} = Entry, [{_, HeadN, _} = Head | Tail])
    when N =< HeadN ->
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