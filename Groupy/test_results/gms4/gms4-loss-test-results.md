# GMS4 lost-message recovery test explained

Source: `gms4-loss-test-results.txt`, produced by `gms4_loss_test.erl`.

- All workers acknowledge each normal multicast before the leader continues.

`{sleep,1000}` is delivered at `N=7`, making workers generate colour changes more often.

## Deliberately lost message

```text
dropping N=8 for <0.93.0> once
3 received NEW message: {change,5} (N=8)
3 sending ack for N=8
```

The test-only `maybe_send/2` wrapper drops `{change,5}` with sequence `N=8` for worker 2. Worker 3 receives and acknowledges it normally, but worker 2 cannot acknowledge a message it never received.

## Timeout and retransmission

```text
leader timeout for N=8; retransmitting to [<0.93.0>]
2 received NEW message: {change,5} (N=8)
2 sending ack for N=8
```

After five seconds, the leader is still waiting for worker 2's acknowledgement. It retransmits only to that pending worker. Worker 2 then receives the missing message and acknowledges it.

## Recovery

From `N=9` onward, workers 2 and 3 both receive every message with the same sequence number. The leader does not advance to `N=9` until the missing `N=8` acknowledgement arrives.
