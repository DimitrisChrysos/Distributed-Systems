# GMS4 lost-acknowledgement recovery test explained

Source: `gms4-ack-loss-test-results.txt`, produced by `gms4_ack_loss_test.erl`.

---

```text
2 received NEW message: {state_request,...} (N=1)
2 dropping ack for N=1 once
```

Worker 2 processes `N=1` once and advances its expected sequence number to `N=2`, but the test intentionally drops its first acknowledgement.

## Timeout and duplicate message

```text
leader timeout for N=1; retransmitting to [<0.93.0>]
2 received old message: (I=1, N=2)
2 sending ack for N=1
```

The leader waits five seconds for the missing acknowledgement and retransmits `N=1`. Worker 2 has already processed that sequence number, so it identifies the retransmission as old and does not deliver the state request twice. It sends the acknowledgement again instead.

## Recovery

```text
2 received NEW message: {state,...,{0,0,0}} (N=2)
2 sending ack for N=2
```

After receiving the replacement acknowledgement for `N=1`, the leader continues with `N=2`. This confirms that a lost acknowledgement causes a safe retry.
