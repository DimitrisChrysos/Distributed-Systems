# Questions in tasks

## 1.3

### Does it matter that key:between/3 allows the key Xkey to be equal to Skey?
In our implementation, it matters because if Xkey = Skey, it would seem as if the successor of a node is pointing at itself (since we dont check the PID in `stabilize()`: `{Skey, _} ->`), making the node notify it about its existence. But, when our successor receives the message, it would disregard it since it will see that `key:between(Nodekey, Pkey, Id)` reuturns false (because the node is not between us and our predecessor that has the same identifier).

### What does it mean that Xkey is equal to Skey?
For this case, if Xkey = Skey, it would mean that the identifier of the predecessor (Xkey) of our successor is the same as our successors' (Skey). Since we generate the identifiers using a random function, this would happen only if the function returned the same number (identifier) for both nodes. So we would have two nodes with different Pids but same identifiers, meaning the same spot in the identifier domain circle.

### Will Xkey be ever equal to Skey?
In our case, this would only happen if the random function we use returned the same number (identifier) for two nodes. Since the chance of this happening is about 1/1_000_000_000 (since we use uniform random numbers) for every two nodes, we can can say that this scenario is not plausible when our ring is small. As the number of nodes increases though, the chance of having a collision also increases. This is a problem that also exists in hash functions (but certain functions handle it better), but it wouldn't happen if we implemented the correct chord scheme and used the IP of a node to calculate its identifier (instead of drawing a random number each time).

## 1.4

### What are the pros and cons of a more frequent stabilizing procedure?

More frequent stabilization makes the ring repair itself faster after nodes join or leave, so predecessor/successor pointers become correct sooner. The downside is more network messages and processing overhead.

### What is delayed if we don’t do stabilizing that often?

With infrequent stabilization, updates to the ring are delayed, so new nodes take longer to be discovered and linked correctly, so routing can temporarily use outdated successor/predecessor pointers.

## 1.5

### Do we need a special case to detect that we’re pointing to ourselves?

No, if a node’s predecessor is itself, then `Pkey = Id`. Then inside `key:between(Nkey, Id, Id)` treats that as the whole ring, so it returns `true` and the new node is accepted as the predecessor.

### Do we have to inform the new node about our decision?

The node does not need to inform the candidate whether it accepted or rejected the notification. A notify is just a proposal, not something we have to reply to.

### How will it know if we have discarded its friendly proposal?

If rejected, the new node does not learn that immediately. Its periodic stabilization continues: 
- it asks its successor for predecessor information,
- adjusts its successor when necessary,
- and eventually the ring converges to the correct links.

## 1.6

### What would happen if we didn’t schedule the stabilize procedure? Would things still work?

Without scheduled stabilization, nodes would not periodically try to stabilize by asking their successors for predecessor information so we could not find if they have a new predecessor.

A newly joined node might initially connect, but the other nodes would not be able to reliably update their successor and predecessor pointers. So the ring could be incomple or outdated and the routing could be incorrect.

A single-node ring would still work, but with more nodes the ring would not reliably converge to correctness without stabilization happening.