# GMS3 complex-test output explained

Source: `gms3_complext_test_results.txt`.

## Group formation and delayed join

Views consume sequence numbers. The initial group grows to four workers through views `N=0`, `N=3`, and `N=7`. The delayed fifth worker joins through view `N=13`:

```text
5 received NEW view: [...] (N=13)
2 received NEW view: [...] (N=13)
3 received NEW view: [...] (N=13)
4 received NEW view: [...] (N=13)
```

Worker 5 then multicasts a state request at `N=14`. The four already-running workers reply with the same colour `{0,0,13}` at `N=15` through `N=18`, showing that the group was synchronised before worker 5 started normal operation.

## Ordered traffic

```text
2 received NEW message: {sleep,100} (N=19) 
5 received NEW message: {sleep,100} (N=19) 
3 received NEW message: {sleep,100} (N=19) 
4 received NEW message: {sleep,100} (N=19) 
```

Every slave prints the same sequence number and payload. The order of terminal lines may differ because the processes print concurrently.

## First two crashes: safe duplicate replay

Leader 1 crashes after all slaves have received `N=22`. Node 2 becomes leader and retransmits its last message but all other nodes disregard the already read message `N=22`:

```text
leader 1: crash
2 received NEW message: {change,9} (N=22) 
3 received NEW message: {change,9} (N=22) 
5 received NEW message: {change,9} (N=22) 
4 received NEW message: {change,9} (N=22) 
2 received down from <0.87.0>
3 received down from <0.87.0>
5 received down from <0.87.0>
4 received down from <0.87.0>
2 becomes the new leader
3 is monitoring new Leader: <0.93.0>
5 is monitoring new Leader: <0.93.0>
4 is monitoring new Leader: <0.93.0>
2 broadcasting Last Message: {msg,22,{change,9}}
3 received old message: (I=22, N=23) 
4 received old message: (I=22, N=23) 
5 received old message: (I=22, N=23) 
```

- Leader 2 behaves the same at `N=44`.
    - Nodes 3, 4, and 5 already received `N=44`, so it is correctly ignored as old.

## Third crash: missing message is recovered

This is the important reliable-multicast case:

```text
leader 3: crash
4 received NEW message: {change,2} (N=78) 
5 received down from <0.97.0>
4 received down from <0.97.0>
5 is monitoring new Leader: <0.101.0>
4 becomes the new leader
4 broadcasting Last Message: {msg,78,{change,2}}
5 received NEW message: {change,2} (N=78) 
```

1. Leader 3 sent `N=78` to node 4, then crashed before node 5 received it.
2. Node 4 becomes leader and retransmits its saved `Last` message.
3. Node 5 still expects `N=78`, so it accepts the replay as **new**, and remains synchronised.

## Final crash

By the time leader 4 crashes at `N=146`, only node 5 remains. It receives `N=146`, becomes leader, and has no remaining slave to replay to.

## Result

This run shows both outcomes required by reliable multicast: 
- Already-delivered messages are ignored as duplicates
- A missed message (in our example `N=78`) is recovered by the new leader's retransmission.
