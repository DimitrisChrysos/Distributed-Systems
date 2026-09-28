# gms2: make the workers state out of sync experiment

Workers out of sync after a leader has crashed.

## Steps with arghh -> 100

```erlang
c(gms2).
c(worker).
c(gui).
c(test).

W1 = test:first(1, gms2, 5000).
W2 = test:add(2, gms2, W1, 5000).
W3 = test:add(3, gms2, W1, 5000).
```

When the three windows are open, increase the message rate:

```erlang
test:sleep(W1, 100).
```

This multicasts `{sleep, 100}` to every worker:

- Each worker changes its maximum random wait from `5000` ms to `100` ms to showcase crashes faster. 
- Watch the terminal for a leader crash and election.

## Potential Scenarios

Flow with leader `A` and slaves `B`, `C`:

```text
A -> B, crash check, A -> C, crash check
```

| Outcome | Probability | Result |
| --- | ---: | --- |
| A crashes after B | 1% | B receives the message but C misses it -> out of sync |
| A crashes after B and C | 99%*1%=0.99% | Both received it -> no missing message |
| A survives this broadcast | 99%*99%=98.01% | Normal delivery |

## Why states diverge when crash happens after B

If B receives colour change #2 and C misses it, B is elected leader because it is first in the ordered slave list. Later changes are delivered to both workers, but they apply them to different previous colours:

```text
B: colour #1 -> change #2 -> change #3
C: colour #1              -> change #3
```

`gms2` detects the failure and elects a leader, but it does not retransmit the interrupted last message.
