% 1 node ring handling 4000 keys, with 4 clients querying it (each client added 1000 keys)

-module(four_clients_test).

-export([
    % run/0,
    run/1
    % benchmark/0
    % benchmark/1
]).

%% 1 node ring handling 4000 keys, with 4 clients querying it (each client added 1000 keys)

% % run() ->
% %     benchmark().

% run(ContactNode) ->
%     benchmark(ContactNode).

% % benchmark() ->
% %     benchmark('node1@127.0.0.1').

% benchmark(ContactNode) ->
% % benchmark() ->

%     % P1 = test:start(node2),

%     % timer:sleep(5000), % Sleep for 5 seconds

%     Clients = [
%         {'client1@127.0.0.1', 1000},
%         {'client2@127.0.0.1', 1000},
%         {'client3@127.0.0.1', 1000},
%         {'client4@127.0.0.1', 1000}
%     ],

%     AllKeys = lists:foldl(
%         fun({Client, Count}, Acc) ->
%             Keys = generate_keys(Count, Client, []),
%             insert_keys(ContactNode, Keys),
%             Acc ++ Keys
%         end,
%         [],
%         Clients
%     ),

%     timer:sleep(5000), % Sleep for 5 seconds
%     {Us, _} = timer:tc(fun() -> lookup_all(P1, AllKeys) end),
%     io:format("lookup_time_us=~p~n", [Us]).

% generate_keys(Count, Client, List) ->
%     if
%         Count =:= 0 ->
%             List;
%         true ->
%             generate_keys(Count - 1, Client, [{key:generate(), myValue} | List])
%     end.

% insert_keys(ContactNode, Keys) ->
%     lists:foreach(
%         fun({Key, Value}) ->
%             % storage:put(ContactNode, Key, Value)
%             ContactNode ! {add, Key, Value, make_ref(), self()}
%         end,
%         Keys
%     ).

% lookup_all(ContactNode, Keys) ->
%     lists:foreach(
%         fun({Key, _Value}) ->
%             Ref = make_ref(),
%             ContactNode ! {lookup, Key, Ref, self()},
%             receive
%                 {Ref, Value} ->
%                     Value
%             after 5000 ->
%                 {error, "timeout"}
%             end
%         end,
%         Keys
%     ).



run(ContactNode) ->
    % ContactNode = test:start(node1),
    % timer:sleep(1000),

    Clients = [client1, client2, client3, client4],
    Pids = [
        spawn(fun() ->
            client_work(Client, ContactNode, 1000)
        end)
        || Client <- Clients
    ],

    lists:foreach(fun(Pid) -> receive {Pid, done} -> ok end end, Pids),
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

    io:format("client=~p store_time_us=~p lookup_time_us=~p~n",
              [Client, StoreUs, LookupUs]),
    % ok.
    self() ! {self(), done}.

generate_keys(Count, Client, Acc) ->
    if
        Count =:= 0 -> Acc;
        true ->
            Key = key:generate(),
            NewStore = storage:add(Key, {Client, Key}, Acc),
            generate_keys(Count - 1, Client, NewStore)
    end.