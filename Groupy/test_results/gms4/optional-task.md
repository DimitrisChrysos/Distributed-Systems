# Optional task for extra bonus: What could possibly go wrong

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

## What if the failure detector is not perfect?

For example, a three-worker group splits into `A` and `B,C`. `A` may still believe it is leader, while `B` and `C` receive `DOWN` and elect a new leader. Both sides could then multicast different messages.

### Election

1. `B` proposes a newer view, for example `View 6: leader B`, and asks every member to vote.
2. `B` votes for itself and `C` votes for `B`, giving it two of three votes.
3. `B` can now install View 6.
4. `A` has only one vote, so it cannot install a conflicting view.

### Reconnection

- When the network connection becomes available again, `A` receives a heartbeat or reconnects to a known group member. It sends a rejoin request containing its last view number.
- `B` replies with the newer view and any missed state/messages.
- Since `A` sees that View 6 is newer than its View 5, it stops acting as leader, catches up, and rejoins the group.

## What if only incorrect nodes deliver a message?

### How it can happen

1. Leader `A` sends message `M` to worker `B`.
2. `B` delivers `M`.
3. `A` crashes before sending `M` to any correct worker.
4. `B` also crashes.
5. Only incorrect nodes have delivered `M`. No correct worker will ever deliver it.

### Why reliable sends and perfect failure detection do not help

Every send that `A` actually performs succeeds: `B` receives `M`. The problem is that `A` crashes before sending `M` to a correct worker. A perfect failure detector can correctly report that `A` and `B` crashed, but it cannot recover a message stored only in those crashed workers.

### Likelihood

This needs two failures in a short window: 
1. `A` must crash after `B` delivers `M`.
2. And `B` must crash before recovery. 
It is therefore unlikely but not impossible. 
3. With independent failure probability `p`, it is about `p^2`

### Solution: confirm the message before delivery

1. Workers store and acknowledge `M`, but do not deliver it to the application layer yet.
2. The leader receives acknowledgements from a majority of workers.
3. The leader broadcasts a commit message.
4. A worker delivers `M` only after receiving the commit.

Assuming fewer than half of the workers crash, a majority ensures that any later majority shares at least one worker that stored `M`.
