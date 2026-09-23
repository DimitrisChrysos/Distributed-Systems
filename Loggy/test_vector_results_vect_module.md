# Tests of Vector module

## Config: Sleep -> 100, Jitter -> 3000
```
22> test_vector:run(100,3000).
john=<0.195.0>, paul=<0.196.0>, ringo=<0.197.0>, george=<0.198.0>
queued: ringo [{ringo,1},{john,1}] {received,{hello,57}}
log: [{john,1}] john {sending,{hello,57}}
log: [{ringo,1},{john,1}] ringo {received,{hello,57}}
queued: john [{john,2},{ringo,2}] {received,{hello,77}}
log: [{paul,1}] paul {sending,{hello,68}}
queued: paul [{paul,2},{john,3},{ringo,2}] {received,{hello,90}}
log: [{ringo,2},{john,1}] ringo {sending,{hello,77}}
log: [{john,2},{ringo,2}] john {received,{hello,77}}
log: [{ringo,3},{john,1},{paul,1}] ringo {received,{hello,68}}
queued: ringo [{ringo,4},{john,1},{paul,1},{george,1}] {received,{hello,58}}
queued: paul [{paul,3},{john,3},{ringo,2}] {sending,{hello,40}}
log: [{george,1}] george {sending,{hello,58}}
log: [{ringo,4},{john,1},{paul,1},{george,1}] ringo {received,{hello,58}}
log: [{john,3},{ringo,2}] john {sending,{hello,90}}
log: [{paul,2},{john,3},{ringo,2}] paul {received,{hello,90}}
log: [{paul,3},{john,3},{ringo,2}] paul {sending,{hello,40}}
log: [{john,4},{ringo,2},{paul,3}] john {received,{hello,40}}
queued: john [{john,5},{ringo,5},{paul,3},{george,1}] {received,{hello,42}}
queued: paul [{paul,4},{john,6},{ringo,5},{george,1}] {received,{hello,84}}
log: [{ringo,5},{john,1},{paul,1},{george,1}] ringo {sending,{hello,42}}
log: [{john,5},{ringo,5},{paul,3},{george,1}] john {received,{hello,42}}
queued: ringo [{ringo,6},{john,1},{paul,1},{george,2}] {received,{hello,100}}
log: [{john,6},{ringo,5},{paul,3},{george,1}] john {sending,{hello,84}}
log: [{paul,4},{john,6},{ringo,5},{george,1}] paul {received,{hello,84}}
queued: john [{john,7},{ringo,7},{paul,3},{george,2}] {received,{hello,63}}
log: [{george,2}] george {sending,{hello,100}}
log: [{ringo,6},{john,1},{paul,1},{george,2}] ringo {received,{hello,100}}
queued: george [{george,3},{paul,5},{john,6},{ringo,5}] {received,{hello,55}}
log: [{ringo,7},{john,1},{paul,1},{george,2}] ringo {sending,{hello,63}}
log: [{john,7},{ringo,7},{paul,3},{george,2}] john {received,{hello,63}}
Command is taking a long time, type Ctrl+G, then enter 'i' to interrupt
Maximum holdback queue size: 3
stop
23> 
```

![test run](sources/test_vect_sleep_100_jitter_3000.png)
