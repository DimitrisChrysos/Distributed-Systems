# Reliable Multicast in GMS3

In a distributed group membership service, a critical failure scenario occurs when a leader crashes *while* broadcasting a message. Because network delivery is not instantaneous, some nodes might receive the message before the leader dies, while others only receive the `DOWN` notification and miss the data message entirely.

The `gms3` implementation solves this by introducing a sequence counter (`N`) and a "rebroadcast" mechanism upon leader election.

## How the Mechanism Works

1. **Sequence Numbers (N):** Every message sent by the leader includes a strictly incrementing integer (`N`). Each node keeps track of what `N` it should expect to receive in the next message.
2. **State Preservation:** Slaves always hold the last message they received in their state.
3. **Rebroadcasting:** When a leader dies and a new leader is elected, the very first action the new leader takes is to broadcast the *last message* it received from the old leader.
4. **Duplicate Filtering:** When a node receives a message, it checks the incoming `N` value. If `N` is smaller than what the node expected (based on past messages it received and its current counter), it means the node already processed this message before the leader crashed, so it safely discards the duplicate. If the incoming `N` is equal to the number it expected, it processes the message.

## Execution Result: Surviving Mid-Broadcast Crashes

* We first start one leader (`1`) and three slaves (`2`, `3`, `4`)

```text
2 received NEW message: {change,11} (N=12)
3 received NEW message: {change,11} (N=12)
4 received NEW message: {change,11} (N=12)
2 received NEW message: {change,14} (N=13)
3 received NEW message: {change,14} (N=13)
4 received NEW message: {change,14} (N=13)
2 received NEW message: {change,1} (N=14)
3 received NEW message: {change,1} (N=14)
4 received NEW message: {change,1} (N=14)
2 received NEW message: {change,5} (N=15)
3 received NEW message: {change,5} (N=15)
4 received NEW message: {change,5} (N=15)
2 received NEW message: {change,16} (N=16)
3 received NEW message: {change,16} (N=16)
...
```

During broadcasting, all three slaves receive the same state changes from the leader, increasing their `N` counter (since all messages are new).

### Crash Scenario 1 (Leader 1 Fails at N=25)

First crash:

```text
...
2 received NEW message: {change,7} (N=24)
3 received NEW message: {change,7} (N=24)
4 received NEW message: {change,7} (N=24)
leader 1: crash
2 received NEW message: {change,1} (N=25)
3 received down from <0.87.0>
4 received down from <0.87.0>
2 received down from <0.87.0>
```

Here, Leader 1 attempts to broadcast `{change,1}` as message `N=25`. Node 2 receives it, but Leader 1 crashes immediately after. Nodes 3 and 4 *never get message 25*; they only get the `DOWN` notification.

Without the reliable multicast mechanism, Node 2 would be at state `N=25`, while Nodes 3 and 4 would be stuck at `N=24`. The group would no longer be coordinated.

However, after Node 2 takes over:

```text
2 becomes the new leader
2 broadcasting Last Message: {msg,25,{change,1}}
3 received NEW message: {change,1} (N=25)
4 received NEW message: {change,1} (N=25)
...
```

Node 2 immediately resends its last known message (`N=25`). Nodes 3 and 4, which were waiting for `N=25`, receive it, process it, and perfectly synchronize their state with the new leader.

### Crash Scenario 2 (Leader 2 Fails at N=59)

The exact same protection mechanism kicks in during the second failure:

```text
...
3 received NEW message: {change,8} (N=58)
4 received NEW message: {change,8} (N=58)
leader 2: crash
3 received NEW message: {change,7} (N=59)
4 received down from <0.94.0>
3 received down from <0.94.0>
```

Node 2 crashes while sending `N=59`. Node 3 gets it, but Node 4 doesn't.

```text
3 becomes the new leader
3 broadcasting Last Message: {msg,59,{change,7}}
4 received NEW message: {change,7} (N=59)
...
```

Node 3 gets elected, resends `N=59`, and Node 4 successfully catches up.

---
## To test the reliable multicast implementation, run `gms3_test.erl`:

* `gms3_test.erl` also showcases the dynamic addition of new nodes, and how they can stay coordinated with the already existing nodes.

In the following logs of the execution of `gms3_test.erl`, we can see a case where the leader (node 3) crashed, after the broadcasting was done (all nodes received the latest message). This makes nodes 5 and 6 disregard the re-broadcasted message from node 4 (new leader).

```text
...
4 received NEW message: {change,9} (N=76)
5 received NEW message: {change,9} (N=76)
6 received NEW message: {change,9} (N=76)
leader 3: crash
4 received NEW message: {change,5} (N=77)
5 received NEW message: {change,5} (N=77)
6 received NEW message: {change,5} (N=77)
4 received down from <0.138.0>
5 received down from <0.138.0>
6 received down from <0.138.0>
4 becomes the new leader
5 is monitoring new Leader: <0.142.0>
6 is monitoring new Leader: <0.142.0>
4 broadcasting Last Message: {msg,77,{change,5}}
5 received old message: (I=77, N=78)
6 received old message: (I=77, N=78)
...
```

## Conclusion

By coupling monitor-based failure detection with sequence numbers and last-message rebroadcasting, `gms3` ensures reliable multicasting. Even if a leader is removed from the network mid-broadcast, the next-in-line node will seamlessly finish the broadcast, ensuring no peer is permanently left behind and group coordination remains intact.
