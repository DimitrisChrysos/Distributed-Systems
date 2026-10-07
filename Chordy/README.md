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

## 2.5

### What Store part should be handed over to our new predecessor during handover()?

Since the new node in the ring has an identifer *X*, it should receives the existing keys with identifiers between **(*successor_node_id*, *X*]**. Previous_node_id is the id of the successor the node notified about its existence. This is the correct range, because if we have only one node in the ring (and thus stores all keys), with identifier *10*, and a new node joins with identifier *20*, when notifying node *10*, node *10* needs to handover keys in **(10, 20]** to node *20*, but keep keys in between **(20, 10]**. If node *10* only had keys in between **(20, 10]**, all is correct and nothing will get handovered to *20*.

## 3.3

### What will happen if a node is falsely detected as being dead?
A false 'DOWN' message can make a healthy node look dead, (usually because of a network partition or temporary connectivity problem). The remaining nodes may replace it and repair the ring without it, while the unavailable node may still be running and believe that the other nodes have failed. This can split the system into separate rings, causing inconsistent routing. If the dead node gets restored though, it will manage to eventually stabilize with the rest of the ring and receive any key-values that its successor collected while it was dead. In that case, if the successor hands it over some keys that are already stored in the dead node, the node can overide its own values that are old).

### What will happen if a node has only been temporally unavailable (and in the worst case, it might think that the rest of the network is gone)
The remaining nodes may replace that "dead" node and form a repaired ring. Meanwhile, the unavailable node may still be running and may believe that the rest of the ring has failed. This can create two separate rings with conflicting routing and data updates. When connectivity returns, the node will be stabilized again and receive any key-values that should become its responsibility.

### How much would you gamble in trusting the ’DOWN’ message?
In a real distributed store, we should not be able to trust it since connectivity issues such as network partitions are very frequent. We could use mechanisms, such a retries, before treating a node as definitively dead.

## 4.2

### What does it mean that an element has been added to the store?
An element should only be considered added when it exists both in the responsible node’s Store and in its successor’s Replica.

### Can we send a confirmation to the client and then replicate the element, what if we fail?
No. If the node confirms first and then fails before replication is complete, the client may believe the value was stored even though it has been lost.

### Who should send the confirmation?
The successor should confirm the replication to the responsible node. Once it knows that the value is stored locally and replicated successfully, the responsible node should send the final confirmation to the client.

### What happens if the element was added the first time but the confirmation message was lost?
The value may already be stored and replicated successfully, but the client does not know this because it never received ok. If the client resends the add request, the same value may be added again.

### Will we handle duplicates properly?
Currently storage:add/3 appends every {Key, Value} pair without checking whether that key already exists. The duplicate will also be replicated.

### Another problem has to do with a joining node in combination with adding a new value. You have to think twice before realizing we have a problem. What would a solution look like?

- A join changes which node owns a key interval.

- The old successor must transfer the relevant Store entries to the joining node. Its old Replica becomes the joining node’s Replica, while the transferred Store entries become the old successor’s new Replica.

- This transfer happens through several asynchronous messages, so it is not atomic.

- A client may add a key from the moving interval during the handover. The add may be processed according to the old ownership information and therefore be omitted from the transfer or replicated to the wrong successor.

- A solution is to mark that interval as being handed over and temporarily queue or forward writes for it.

- The nodes should transfer the Store and Replica data, confirm that the transfer is complete, and then finish the ownership change.

- Any queued writes should then be processed by the new owner and replicated to its successor.

### Are there more devils? Will we have an implementation with no obvious faults or an implementation with obviously no faults?
There are always more possible problems, such as network partitions delayed messages, or multiple nodes failing at once.
We can fix the problems we find, but we cannot easily prove that no other problems exist. We can aim for an implementation with no obvious faults, but not one that is obviously fault-free.