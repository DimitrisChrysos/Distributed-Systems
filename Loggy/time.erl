-module(time).

-export([zero/0, inc/2, leq/2, merge/2]).

% return an initial Lamport value (could it be 0)
zero() -> 0.

% return the time T incremented by one (you will probably
% ignore the Name, but we will use it later)
inc(Name, T) -> T + 1.

% true if Ti is less than or equal to Tj
leq(Ti, Tj) -> Ti =< Tj.

% merge the two Lamport time stamps (i.e., take the
% maximum value)
merge(Ti, Tj) ->
    case leq(Ti, Tj) of
        true -> Tj;
        false -> Ti
    end.
