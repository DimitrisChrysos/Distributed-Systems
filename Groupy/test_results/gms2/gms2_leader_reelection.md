# GMS2: Leader re-election

produced by `gms2_leader_reelection_test.erl`.

## 1. Starting the Leader Node
Initialize the first worker. Because it is the first node, it automatically becomes the leader of the group.

* Syntax: `worker:start(Id, Module, Seed, Timeout)`

```erlang
2> worker:start(1, gms2, 42, 5000).
<0.278.0>
```

## 2. Starting the Slave Nodes
Start additional workers and instruct them to join the group by passing the Leader's worker PID.

* Syntax: `worker:start(Id, Module, Seed, LeaderPid, Timeout)`

```erlang
3> worker:start(2, gms2, 42, <0.278.0>, 5000).
<0.283.0>
4> worker:start(3, gms2, 42, <0.278.0>, 5000).
<0.288.0>
```

At this point, Node 1 is coordinating the group. Nodes 2 and 3 are slaves.

## 3. Testing Fault Tolerance (Leader Election)
To verify that the group can survive a crash, simulate a failure by sending a `stop` message to the leader's worker process.

```erlang
5> <0.278.0> ! stop.
2 received down from <0.279.0>
3 received down from <0.279.0>
stop
2 becomes the new leader
3 is monitoring new Leader: <0.284.0>
```

The coordination of the nodes does not stop (same colors still appear from every node)

You can kill the *new* leader to watch the process repeat:

```erlang
6> <0.283.0> ! stop.
3 received down from <0.284.0>
stop
3 becomes the new leader
```

---
If we were to run the workers using the `gms1` module, no election would happen after the leader got killed, and the coordination of the nodes would stop (the color of the windows would stop changing, since the masters and slaves cannot send messages to the leader (dead), and thus no broadcasting is performed).

```
53> worker:start(1, gms1, 42, 5000).
<0.299.0>
54> worker:start(2, gms1, 42, <0.299.0>, 5000).
<0.304.0>
55> worker:start(3, gms1, 42, <0.299.0>, 5000).
<0.309.0>
56> <0.299.0> ! stop.
stop
```