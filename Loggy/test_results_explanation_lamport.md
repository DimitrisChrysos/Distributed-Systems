# Test runs of test.erl with workers that use Lamport counters

## Test Run with 3000 jitter

![test run](sources/test_run_jitter_3000_lamport.png)

```
log: 2 ringo {received,{hello,57}}
log: 1 john {sending,{hello,57}}
```
* `john` sends to `ringo` (increasing john's Lamport counter by 1 (0 -> 1)), and ringo computes `max(0, 1) + 1 -> 2`, but ringo logs the `received` event, before john logs the `sending` event. By examining the Lamport counters, we can conclude that the order is wrong, since event '2' is logged before event '1'.

```
log: 4 john {received,{hello,77}}
log: 3 ringo {sending,{hello,77}}
```
* `ringo` sends to `john` (increasing ringo's Lamport counter by 1 (2 -> 3)), and john computes `max(1, 3) + 1 -> 4`, but john logs the `received` event, before ringo logs the `sending` event. By examining the Lamport counters, we can conclude that the order is wrong, since event '4' is logged before event '3'.

```
log: 1 paul {sending,{hello,68}}
log: 4 ringo {received,{hello,68}}
```
* `paul` sends to `ringo` (increasing paul's Lamport counter by 1 (0 -> 1)), and ringo computes `max(3, 1) + 1 -> 4`, and the logging order is correct. We can see that the Lamport counter '1' is logged before counter '4'.

```
log: 6 paul {received,{hello,90}}
log: 5 john {sending,{hello,90}}
```
* `john` sends to `paul` (increasing john's Lamport counter by 1 (4 -> 5)), and paul computes `max(1, 5) + 1 -> 6`, but paul logs the `received` event, before john logs the `sending` event. By examining the Lamport counters, we can conclude that the order is wrong, since event '6' is logged before event '5'.

```
log: 5 ringo {received,{hello,58}}
log: 1 george {sending,{hello,58}}
```
* `george` sends to `ringo` (increasing george's Lamport counter by 1 (0 -> 1)), and ringo computes `max(4, 1) + 1 -> 5`, but ringo logs the `received` event, before george logs the `sending` event. By examining the Lamport counters, we can conclude that the order is wrong, since event '5' is logged before event '1'.

```
log: 7 paul {sending,{hello,40}}
log: 8 john {received,{hello,40}}
```
* `paul` sends to `john` (increasing paul's Lamport counter by 1 (6 -> 7)), and john computes `max(5, 7) + 1 -> 8`, and the logging order is correct. We can see that the Lamport counter '7' is logged before counter '8'.