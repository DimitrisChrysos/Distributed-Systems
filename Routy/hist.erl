-module(hist).

-export([new/1, update/3]).

% return a new history, where messages from Name will always be seen as old.
new(Name) ->
    [{Name, inf}].

% Check if message number N from the Node
% is old or new. If it is old, then return old, but if it is new, return
% {new, Updated} where Updated is the updated history.
update(Node, N, History) ->
    case lists:keyfind(Node, 1, History) of
        {_, CurrentN} when CurrentN >= N ->
            old;
        {_, CurrentN} when CurrentN < N ->
            UpdatedHistory = lists:keyreplace(Node, 1, History, {Node, N}),
            {new, UpdatedHistory};
        false ->
            {new, [{Node, N} | History]}
    end.
