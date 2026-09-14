-module(hist).

-export([new/1, update/3]).

new(Name) ->
    [{Name, inf}].

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
