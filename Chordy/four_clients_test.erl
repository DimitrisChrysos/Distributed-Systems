-module(four_clients_test).

-export([
    run/1
]).

run(ContactNode) ->
    Clients = [client1, client2, client3, client4],
    [
        spawn(fun() ->
            client_work(Client, ContactNode, 1000)
        end)
        || Client <- Clients
    ],

    ok.

client_work(Client, ContactNode, Count) ->
    Keys = generate_keys(Count, Client, storage:create()),

    {StoreUs, _} = timer:tc(fun() ->
        lists:foreach(
            fun({Key, Value}) ->
                Ref = make_ref(),
                ContactNode ! {add, Key, Value, Ref, self()},
                receive
                    {Ref, ok} -> ok
                after 5000 -> erlang:error(timeout)
                end
            end,
            Keys
        )
    end),

    io:format("~w client stored ~w keys~n", [Client, length(Keys)]),

    timer:sleep(5000), % wait 5 secs for all keys to be stored

    {LookupUs, _} = timer:tc(fun() ->
        lists:foreach(
            fun({Key, _Value}) ->
                Ref = make_ref(),
                ContactNode ! {lookup, Key, Ref, self()},
                receive
                    {Ref, _Val} -> ok
                after 5000 -> erlang:error(timeout)
                end
            end,
            Keys
        )
    end),

    io:format("client=~p store_time_us=~p lookup_time_us=~p~n", [Client, StoreUs, LookupUs]),
    ok.

generate_keys(Count, Client, Acc) ->
    if
        Count =:= 0 -> Acc;
        true ->
            Key = key:generate(),
            NewStore = storage:add(Key, {Client, Key}, Acc),
            generate_keys(Count - 1, Client, NewStore)
    end.