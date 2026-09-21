# Test runs of test.erl

## Test Run with 3000 jitter 

![test run](sources/test_run_jitter_3000.png)

```
log: na ringo {received,{hello,57}}
log: na john {sending,{hello,57}}
```
* `john` sends to `ringo`, but ringo logs the `received` event, before john logs the `sending` event (happens because john jitters before logging its event).

```
log: na john {received,{hello,77}}
log: na ringo {sending,{hello,77}}
```
* `ringo` sends to `john`, but john logs the `received` event, before ringo logs the `sending` event (happens because ringo jitters before logging its event).

```
log: na paul {sending,{hello,68}}
log: na ringo {received,{hello,68}}
```
* `paul` sends to `ringo`, and the logging order is correct (probably because ringo was processing another message and thus paul had enough time to log its own event first).

```
log: na paul {received,{hello,90}}
log: na john {sending,{hello,90}}
```
* `john` sends to `paul`, but paul logs the `received` event, before john logs the `sending` event (happens because john jitters before logging its event).

```
log: na ringo {received,{hello,58}}
log: na george {sending,{hello,58}}
```
* `george` sends to `ringo`, but ringo logs the `received` event, before george logs the `sending` event (happens because george jitters before logging its event).

```
log: na paul {sending,{hello,40}}
log: na john {received,{hello,40}}
```
* `paul` sends to `john`, and the logging order is correct (probably because john was processing another message and thus paul had enough time to log its own event first)

---

## Test Run with 0 jitter 

![test run](sources/test_run_jitter_0.png)

In this test run every `sending` message arrived to loggy before the `received` one. Since jitter is zero, sleep between sending a message to the worker and sending a message to loggy is also zero.

---

## Test Run with 50 jitter 

![test run](sources/test_run_jitter_50.png)

In this configuration, with only a jitter of 50, several receive messages from loggy were printed before the sending ones with the same identifier.