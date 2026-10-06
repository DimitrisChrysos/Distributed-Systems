-module(key).

-export([generate/0, between/3]).

generate() ->
    rand:uniform(1_000_000_000).

between(_Key, From, To) when From == To ->
    true; % anything is in between
between(Key, From, To) when From < To ->
    From < Key andalso Key =< To;
between(Key, From, To) ->
    % we could use the modulo operator since we know the size of the circle is 2^30
    % (bits_num=30) but this is simpler. This function does not take into account
    % the size of the identifier space, so if someones passes in a value
    % outside of the space, this function might return true when it might have been better
    % to just reject it.
    Key =< To orelse Key > From.

