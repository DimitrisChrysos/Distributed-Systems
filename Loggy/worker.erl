-module(worker).
-export([start/6, stop/1, peers/2]).

start(Name, Logger, Seed, Sleep, Jitter, TimeModule) ->
    spawn_link(fun() -> init(Name, Logger, Seed, Sleep, Jitter, TimeModule) end).

stop(Worker) ->
    Worker ! stop.

init(Name, Log, Seed, Sleep, Jitter, TimeModule) ->
    random:seed(Seed, Seed, Seed),
    receive
        {peers, Peers} ->
            loop(Name, Log, Peers, Sleep, Jitter, TimeModule:zero(), TimeModule);
        stop ->
            ok
    end.

peers(Wrk, Peers) ->
    Wrk ! {peers, Peers}.

loop(Name, Log, Peers, Sleep, Jitter, LamportCounter, TimeModule) ->
    Wait = random:uniform(Sleep),
    receive
        {msg, Time, Msg} ->
            % our new counter is max(LamportCounter, Tj) + 1 after receiving a message from process with counter Tj
            UpdateLamportCounter = TimeModule:inc(Name, TimeModule:merge(LamportCounter, Time)),
            Log ! {log, Name, UpdateLamportCounter, {received, Msg}},
            loop(Name, Log, Peers, Sleep, Jitter, UpdateLamportCounter, TimeModule);
        stop ->
            ok;
        Error ->
            Log ! {log, Name, time, {error, Error}}
    after Wait ->
        Selected = select(Peers),
        Time = TimeModule:inc(Name, LamportCounter), % we increase the counter for the event "send message"
        Message = {hello, random:uniform(100)},
        Selected ! {msg, Time, Message}, % the message contains the updated counter
        jitter(Jitter),
        Log ! {log, Name, Time, {sending, Message}},
        loop(Name, Log, Peers, Sleep, Jitter, Time, TimeModule) % our new counter is the update one
    end.

select(Peers) ->
    lists:nth(random:uniform(length(Peers)), Peers).

jitter(0) -> ok;
jitter(Jitter) -> timer:sleep(random:uniform(Jitter)).