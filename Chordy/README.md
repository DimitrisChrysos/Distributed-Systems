# Questions in tasks

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