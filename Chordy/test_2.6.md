# Answers to Test 2.6

## Initialization:
- First Machine (ring):
```
erl -name ring@RING_IP -setcookie chordy.
c(node_ring_test).
```
- Second machine (clients):
```
erl -name clients@CLIENTS_IP -setcookie chordy.
c(four_clients_test).
```

## 1) One node with 4000 keys vs four nodes with 1000 keys each

### Executions:

#### 1-node ring:
- First Machine (ring):
```
node_ring_test:run(1).
```
- Second machine (clients):
```
four_clients_test:run({chord1, 'ring@RING_IP'}).
```

#### 4-node ring:
- First Machine (ring):
```
node_ring_test:run(4).
```
- Second machine (clients):
```
four_clients_test:run({chord1, 'ring@RING_IP'}).
```

#### 4+2-node ring:
- First Machine (ring):
```
node_ring_test:run(4).
```
- Second machine (clients):
```
four_clients_test:run({chord1, 'ring@RING_IP'}).
```
- First Machine (ring) again:
```
node_ring_test:addNode(5, chord1),
node_ring_test:addNode(6, chord1).
```

From the results:

- 1 node:
  - store: about 7.46 seconds per client
  - lookup: about 7.47–7.48 seconds per client

- 4 nodes:
  - store: about 7.57–7.61 seconds per client
  - lookup: about 7.38–7.42 seconds per client

- 4 + 2 dynamic nodes:
  - store: about 8.32–8.38 seconds per client
  - lookup: about 7.22–7.26 seconds per client

Conclusion:
- There is no clear performance improvement when the system grows from 1 node to 4, or 4 + 2 new ones.
- A single node handling 4000 keys is not much slower than four clients each writing 1000 keys.
- The difference between runs is small compared to the overall cost of the operations.

So the answer is: In our experiments, no, it does not take significantly longer for one machine to handle 4000 elements than for four machines to do 1000 each: the overhead is very similar. This can be attributed to factors like an unbalanced ring (there is no gurantee that our keys are evenly distributed between the nodes), and the fact that all clients send the lookup request to the same node (and thus creating a bottleneck). The executions also shows that the storage time increases as nodes increase, which can be attributed to the fact that more routing needs to be done since we have more nodes.

## 2) What is the limiting factor?

The limiting factor is not just the number of keys or number of nodes. The dominant cost appears to be:
- message passing between clients and the ring,
- lookup routing,
- and the fact that all clients contact the same node.

Even when more nodes are added, the clients still access the same contact node, so the bottleneck remains roughly the same. This means the system is limited by communication and lookup cost, not by pure storage size.

## 3) What happens when another node is added to the ring?

When a second or additional node is introduced, the performance does not improve in a meaningful way.

The results show:
- 4 nodes:
  - store is 7.57–7.61s
  - lookup is 7.38-7.42s

- 4 + 2 nodes:
  - store is 8.32-8.37s
  - lookup is 7.22–7.26s

This means:
- the ring grows, but the total time remains approximately constant,
- adding nodes does not reduce the store/lookup time noticeably,
- the system is still dominated by per-operation network overhead.

Therefore, adding nodes does not automatically improve performance in this workload.

## 4) Does it matter if all test machines access the same node?

Yes, it matters a lot.

All the tests above used the same contact node, which is the main reason the costs stay so similar. If every client sends requests to the same node, that node becomes a bottleneck.

This explains why:
- the 1-node case and the 4-node case have almost the same delay,
- adding more nodes does not help much when the access pattern is centralized.

So the access pattern is a major factor. If clients were distributed more evenly across the ring, performance might improve.

## 5) What will happen with 10,000 elements?

For 10,000 elements, we should expect the total time to increase substantially, because the number of operations grows linearly with the number of keys.

If 1000 keys per client takes about 7–8 seconds, then 10,000 keys per client would likely take around 10 times more time in a naive scaling model, assuming the same per-operation cost.

So:
- store time would increase significantly,
- lookup time would also increase significantly,
- the dominant cost would remain network/request overhead rather than the number of nodes alone.

## Final conclusion

The experiment shows that:

- a single node does not become dramatically slower than a multi-node ring for this workload,
- adding nodes does not significantly improve performance,
- all clients contacting the same node creates a bottleneck,
- the main cost is communication and routing overhead, not storage size alone.

This means the system is limited by distributed operation overhead and access concentration, rather than by the number of elements in the ring itself.

---
Execution Runs:
### With 1 node:
```
dimitris@n159-p9 Chordy % erl -name b@130.229.191.255 -setcookie chordy.
Erlang/OTP 29 [erts-17.0.5] [source] [64-bit] [smp:18:18] [ds:18:18:10] [async-threads:1] [jit] [dtrace]

Eshell V17.0.5 (press Ctrl+G to abort, type help(). for help)
(b@130.229.191.255)1> one_node_test_first_machine:run({chord1, 'a@130.229.128.169'}).
Command is taking a long time, type Ctrl+G, then enter 'i' to interrupt
client1 client stored 1000 keys
client3 client stored 1000 keys
client2 client stored 1000 keys
client4 client stored 1000 keys
client=client1 store_time_us=7464432 lookup_time_us=7474331
client=client3 store_time_us=7465834 lookup_time_us=7476769
client=client2 store_time_us=7465815 lookup_time_us=7476782
client=client4 store_time_us=7466259 lookup_time_us=7482454
```

### With 4 nodes:
```
dimitris@n159-p9 Chordy % erl -name b@130.229.191.255 -setcookie chordy.
Erlang/OTP 29 [erts-17.0.5] [source] [64-bit] [smp:18:18] [ds:18:18:10] [async-threads:1] [jit] [dtrace]

Eshell V17.0.5 (press Ctrl+G to abort, type help(). for help)
(b@130.229.191.255)1> c(four_clients_test).
{ok,four_clients_test}
(b@130.229.191.255)2> four_clients_test:run({chord1, 'a@130.229.128.169'}).
Command is taking a long time, type Ctrl+G, then enter 'i' to interrupt
client3 client stored 1000 keys
client1 client stored 1000 keys
client2 client stored 1000 keys
client4 client stored 1000 keys
client=client4 store_time_us=7617242 lookup_time_us=7385769
client=client1 store_time_us=7581802 lookup_time_us=7421819
client=client3 store_time_us=7576641 lookup_time_us=7425777
client=client2 store_time_us=7586239 lookup_time_us=7419038
```

### After adding 2 more nodes:
```
dimitris@n159-p9 Chordy % erl -name b@130.229.191.255 -setcookie chordy.
Erlang/OTP 29 [erts-17.0.5] [source] [64-bit] [smp:18:18] [ds:18:18:10] [async-threads:1] [jit] [dtrace]

Eshell V17.0.5 (press Ctrl+G to abort, type help(). for help)
(b@130.229.191.255)1> four_clients_test:run({chord1, 'a@130.229.128.169'}).
Command is taking a long time, type Ctrl+G, then enter 'i' to interrupt
client2 client stored 1000 keys
client3 client stored 1000 keys
client4 client stored 1000 keys
client1 client stored 1000 keys
client=client3 store_time_us=8342831 lookup_time_us=7245272
client=client2 store_time_us=8325368 lookup_time_us=7268164
client=client4 store_time_us=8378387 lookup_time_us=7229197
client=client1 store_time_us=8382300 lookup_time_us=7262163
```
