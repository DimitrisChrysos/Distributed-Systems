# Optional task for extra bonus: What could pos- sibly go wrong

## How would we change the implementation to handle the possibly lost messages? How would this impact performance?

- We could add acknowledgements. After broadcasting `{msg, N, Msg}`, the leader stores the message and waits for `{ack, N, Pid}` from every live slave.
- A timeout causes retransmission to slaves whose acknowledgements are missing. 
- A receiver delivers a sequence number only once, but acknowledges duplicates again, since the previous acknowledgement may have been lost. 
- A `DOWN` notification removes a crashed slave from the acknowledgement set.

The leader waits for all acknowledgements before broadcasting sequence `N + 1`. This ensures that every live member has received each message before the next one is sent.

### Performance impact

**Broadcast cost**
  - Current broadcast with `k` workers: about `k - 1` sends.
  - With acknowledgements: about `2(k - 1)` sends-one message and one acknowledgement for each slave.

**Retransmissions**
  - If the leader times out while waiting for a worker's acknowledgement, it retransmits the message.
  - Retransmissions require duplicate-message handling: the worker may already have received the original message, while its acknowledgement was lost.

**Throughput**
  - Throughput decreases because the leader waits for acknowledgements from all live workers before broadcasting the next message.