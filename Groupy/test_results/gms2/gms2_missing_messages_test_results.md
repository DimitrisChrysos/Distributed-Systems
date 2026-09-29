# GMS2 missing-message test output explained

Source: `gms2_missing_messages_test_results.txt`, produced by `gms2_missing_messages_test.erl`.

## Group setup

The workers join one at a time:

- `W1` is initially the leader, so it does not print a `NEW view` line. 
- The repeated state messages are replies from existing workers that give each joining worker the initial colour `{0,0,0}`.
- `{sleep,1000}` then makes the workers generate colour more often to trigger a crash faster.

## Leader 1 crash: two workers miss a message

```text
leader 1: crash
2 received NEW message: {change,8}
3 received down from <0.97.0>
4 received down from <0.97.0>
2 received down from <0.97.0>
3 is monitoring new Leader: <0.103.0>
4 is monitoring new Leader: <0.103.0>
2 becomes the new leader
```

The old leader sent `{change,8}` to worker 2, then crashed before sending it to workers 3 and 4. Worker 2 is elected and installs the new three-member view.

Workers 3 and 4 never receive `{change,8}`. From this point, worker 2's colour state has one extra change compared with theirs.

## Leader 2 crash: another missing message

```text
leader 2: crash
3 received NEW message: {change,13}
4 received down from <0.103.0>
3 received down from <0.103.0>
4 is monitoring new Leader: <0.107.0>
3 becomes the new leader
```

Worker 3 receives `{change,13}`, but worker 4 does not. Worker 3 becomes leader, so worker 4 is now missing both the earlier history difference and this latest change.

## Later crash

Leader 3 eventually crashes. Worker 4 is the only remaining worker, so it becomes a one-node leader.

## Result: why workers become out of sync

- Later colour changes are delivered to all surviving workers, but they are applied to different previous colours.
- Worker 2 has `{change,8}` while workers 3 and 4 do not. 
- Worker 3 also has `{change,13}` while worker 4 does not.
- `gms2` elects a new leader, but it never retransmits the interrupted message, so the workers keep different message histories and colour states.
