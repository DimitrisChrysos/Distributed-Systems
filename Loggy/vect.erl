-module(vect).
-export([zero/0, inc/2, merge/2, leq/2, clock/1, update/3, safe/2, rank/1]).

% Time is a list of {ProcessName, Counter} tuples (e.g. [] or [{john,2}, {paul,4}])

zero() ->
    [].

inc(Name, Time) ->
    case lists:keyfind(Name, 1, Time) of
        {Name, Timestamp} ->
            lists:keyreplace(Name, 1, Time, {Name, Timestamp + 1});
        false -> [ {Name, 1} |Time]
    end.


merge([], Time) ->
    Time;
merge([{Name, Ti} | Rest], Time) ->
    case lists:keyfind(Name, 1, Time) of
        {Name, Tj} ->
            [{Name, max(Ti, Tj)} | merge(Rest, lists:keydelete(Name, 1, Time))];
        false ->
            [{Name, Ti} | merge(Rest, Time)]
        end.

leq([], _) ->
    true;
leq([{Name, Ti} | Rest],Time) ->
    case lists:keyfind(Name, 1, Time) of
        {Name, Tj} ->
            if 
                Ti =< Tj ->
                    leq(Rest, Time);
                true ->
                    false
            end;
        false ->
            false
    end.

clock(_) ->
    [].

update(From, Time, Clock) ->
    {From, Timestamp} = lists:keyfind(From, 1, Time),
    case lists:keyfind(From, 1, Clock) of
        {From, _} ->
            lists:keyreplace(From, 1, Clock, {From, Timestamp});
        false -> [{From, Timestamp} | Clock]
    end.

safe(Time, Clock) ->
    leq(Time, Clock).

% A causally later vector has no smaller counters and at least one larger
% counter, so its counter sum is strictly greater and preserves causal order.
rank(Vector) ->
    lists:sum([Counter || {_Name, Counter} <- Vector]).