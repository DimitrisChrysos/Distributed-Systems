# Optional task for extra bonus: What could pos- sibly go wrong

## How would we change the implementation to handle the possibly lost messages? How would this impact performance?

- We implemented acknowledgements in `gms4`. After broadcasting `{msg, N, Msg}`, the leader keeps the message and waits for `{ack, N, Pid}` from every slave.
- A timeout causes retransmission only to slaves whose acknowledgements are missing.
- A receiver delivers a sequence number only once, but acknowledges duplicates again, since the previous acknowledgement may have been lost.

The leader waits for all acknowledgements before broadcasting sequence `N + 1`. This ensures that every member in the current test group has received each message before the next one is sent.

### Implementation and tests

- `gms4_loss_test.erl` deliberately drops one colour-change message. The leader times out, retransmits it to the missing worker, and the worker catches up before `N + 1` is sent.
- `gms4_ack_loss_test.erl` deliberately drops one acknowledgement. The leader retransmits the message, the worker recognises the duplicate, does not deliver it twice, and sends the acknowledgement again.

### Performance impact

**Broadcast cost**
  - Current broadcast with `k` workers: about `k - 1` sends.
  - With acknowledgements: about `2(k - 1)` sends—one message and one acknowledgement for each slave.

**Retransmissions**
  - If the leader times out while waiting for a worker's acknowledgement, it retransmits the message.
  - Retransmissions require duplicate-message handling: the worker may already have received the original message, while its acknowledgement was lost.

**Throughput**
  - Throughput decreases because the leader waits for acknowledgements from all live workers before broadcasting the next message.
