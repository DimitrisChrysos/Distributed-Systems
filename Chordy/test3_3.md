# 3.3 failure-recovery test

## 1. Compile and start three nodes

```erlang
c(key).
c(storage).
c(node3).

P1 = node3:start(10).
timer:sleep(1200).

P2 = node3:start(20, P1).
timer:sleep(1800).

P3 = node3:start(30, P1).
timer:sleep(2500).
```

The ring should now be:

```text
10 → 20 → 30 → 10
```

Confirm with a probe:

```erlang
P1 ! probe.
```

Results:
```erlang
1> c(key).
{ok,key}
2> c(storage).
{ok,storage}
3> c(node3).
{ok,node3}
4> 
   P1 = node3:start(10).
<0.102.0>
5> timer:sleep(1200).
ok
6> 
   P2 = node3:start(20, P1).
<0.106.0>
7> timer:sleep(1800).
ok
8> 
   P3 = node3:start(30, P1).
<0.110.0>
9> timer:sleep(2500).
ok
10> P1 ! probe.
Elapsed probe duration: 4 microseconds
probe
Current round trip probe nodes: [<0.102.0>]
Elapsed probe duration: 203 microseconds
Current round trip probe nodes: [<0.106.0>,<0.102.0>]
Total probe round-trip duration: 312 microseconds
Round trip probe nodes: [<0.110.0>,<0.106.0>,<0.102.0>]
11> 
```

## 2. Kill the middle node

```erlang
exit(P2, kill).
timer:sleep(3000).
```

- Node `20` was the successor of node `10` and the predecessor of node `30`.
- Its failure should therefore exercise both `'DOWN'` cases:
    - node `10` promotes its `Next` node (`30`) to successor;
    - node `30` removes its dead predecessor.

Results:
```erlang
11> exit(P2, kill).
true
12> timer:sleep(3000).
ok
13> 
```

## 3. Verify recovery

```erlang
is_process_alive(P1).
is_process_alive(P2).
is_process_alive(P3).
```

Results:
```erlang
13> is_process_alive(P1).
true
14> is_process_alive(P2).
false
15> is_process_alive(P3).
true
16> 
```

Then run:
```erlang
P1 ! probe.
```

Results:
```erlang
16> P1 ! probe.
Elapsed probe duration: 3 microseconds
probe
Current round trip probe nodes: [<0.102.0>]
Total probe round-trip duration: 198 microseconds
Round trip probe nodes: [<0.110.0>,<0.102.0>]
17> 
```

This probe contains only the PIDs for nodes `10` and `30`, showing that the repaired ring is:

```text
10 → 30 → 10
```
