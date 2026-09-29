# GMS3 simple-test output explained

Source: `gms3_simple_test_results.txt`.

## Group setup and state transfer

Worker 2 joins first. Its first membership view consumes `N=0`:

```text
2 received NEW view: [<0.96.0>,<0.102.0>] (N=0)
2 received NEW message: {state_request,...} (N=1)
2 received NEW message: {state,...,{0,0,0}} (N=2)
```

Worker 3 then joins. The enlarged membership view consumes `N=3`, so both workers expect the next item at `N=4`:

```text
2 received NEW view: [<0.96.0>,<0.102.0>,<0.106.0>] (N=3)
3 received NEW view: [<0.96.0>,<0.102.0>,<0.106.0>] (N=3)
2 received NEW message: {state_request,...} (N=4)
3 received NEW message: {state_request,...} (N=4)
```

Both existing workers reply to worker 3's request, producing the two identical state replies at `N=5` and `N=6`. They are separate messages with the same colour because the group is synchronised.

## Ordered traffic

```text
2 received NEW message: {sleep,1000} (N=7)
3 received NEW message: {sleep,1000} (N=7)
2 received NEW message: {change,5} (N=8)
3 received NEW message: {change,5} (N=8)
```

The terminal may print node 3 before node 2 (in an N sequence) because Erlang processes run concurrently.

## First leader crash:

```text
leader 1: crash
2 received NEW message: {change,13} (N=35) 
3 received NEW message: {change,13} (N=35) 
2 received down from <0.97.0>
3 received down from <0.97.0>
2 becomes the new leader
3 is monitoring new Leader: <0.103.0>
2 broadcasting Last Message: {msg,35,{change,13}}
3 received old message: (I=35, N=36) 
3 received NEW message: {change,7} (N=36) 
3 received NEW message: {change,11} (N=37) 
```

Both slaves had already received message `N=35` so the leader crashed after completing that broadcast. Node 2 becomes leader and rebroadcasts its last message. Node 3 already expects `N=36`, so it recognises the replayed `N=35` as a duplicate and ignores it.

## Second leader crash

After node 2 becomes leader, only node 3 prints delivery logs because node 2 delivers messages directly to its own worker. Node 1 has crashed.

```text
leader 2: crash
3 received NEW message: {change,17} (N=103) 
3 received down from <0.103.0>
3 becomes the new leader
3 broadcasting Last Message: {msg,103,{change,17}}
```

Node 3 receives the final message, detects node 2's crash, becomes leader, and preserves its `Last` message. There are no remaining slaves to receive this replay.

## Result

This run demonstrates total order, leader election, last-message retransmission, and duplicate filtering. Its first crash happened after a complete broadcast; a true mid-broadcast recovery run would instead show one slave receiving `N`, another missing it, and the new leader replaying `N` so the missing slave accepts it as new.
