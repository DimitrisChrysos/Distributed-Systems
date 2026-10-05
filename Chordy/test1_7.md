# 1.7 test

## 1. Compile

```bash
c(key).
c(node1).
```

## 2. Test one node locally

Create one node and send it a probe:

```erlang
P1 = node1:start(10).
timer:sleep(1500).
P1 ! probe.
```

### Results
```sh
6> P1 = node1:start(10).
<0.117.0>
7> timer:sleep(1500).
ok
8> P1 ! probe.
Total probe round-trip duration: 1 microseconds
probe
Round trip probe nodes: [<0.117.0>]
9> 
```

Note: In a single-node Chord ring, the node is both its own successor and, after stabilization, its own predecessor. A probe therefore completes immediately after returning to the same node.

## 3. Test a local three-node ring

In a fresh Erlang shell, add nodes one at a time and wait for stabilization between joins:

```erlang
P1 = node1:start(10).
timer:sleep(1200).

P2 = node1:start(20, P1).
timer:sleep(1800).

P3 = node1:start(30, P1).
timer:sleep(2500).

P1 ! probe.
```

### Results

```sh
1> P1 = node1:start(10).
<0.87.0>
2> timer:sleep(1200).
ok
3> 
   P2 = node1:start(20, P1).
<0.91.0>
4> timer:sleep(1800).
ok
5> 
   P3 = node1:start(30, P1).
<0.95.0>
6> timer:sleep(2500).
ok
7> 
   P1 ! probe.
Elapsed probe duration: 4 microseconds
probe
Current round trip probe nodes: [<0.87.0>]
Elapsed probe duration: 282 microseconds
Current round trip probe nodes: [<0.91.0>,<0.87.0>]
Total probe round-trip duration: 468 microseconds
Round trip probe nodes: [<0.95.0>,<0.91.0>,<0.87.0>]
8> 
```
Note:
If the output contains fewer than three nodes, wait a few seconds and send `P1 ! probe.` again. Nodes join asynchronously and need time to stabilize.

## 4. Test two terminals on the same computer

1. Open two terminals in this project folder.
2. Use the same cookie in both terminals. 
3. For two Erlang runtimes on this computer, use `127.0.0.1`. For separate computers, use each computer's reachable LAN IP address.

```bash
erl -name chord_a@127.0.0.1 -setcookie chordy .
```

Then run:

```erlang
P1 = node1:start(10).
register(chord1, P1).
```

In terminal B:

```bash
erl -name chord_b@127.0.0.1 -setcookie chordy .
```

Then connect a new node through the registered entry node from terminal A:

```erlang
Peer = {chord1, 'chord_a@127.0.0.1'}.
```

```erlang
P2 = node1:start(20, Peer).
timer:sleep(2500).
P2 ! probe.
```

### Results
```sh
(chord_a@127.0.0.1)1> P1 = node1:start(10).
<0.93.0>
(chord_a@127.0.0.1)2> register(chord1, P1).
true
Elapsed probe duration: 156 microseconds
Current round trip probe nodes: [<11592.94.0>]
(chord_a@127.0.0.1)3> 
```

```sh
(chord_b@127.0.0.1)1> Peer = {chord1, 'chord_a@127.0.0.1'}.
{chord1,'chord_a@127.0.0.1'}
(chord_b@127.0.0.1)2> P2 = node1:start(20, Peer).
<0.94.0>
(chord_b@127.0.0.1)3> timer:sleep(2500).
ok
(chord_b@127.0.0.1)4> P2 ! probe.
probe
Total probe round-trip duration: 637 microseconds
Round trip probe nodes: [<11287.93.0>,<0.94.0>]
(chord_b@127.0.0.1)5> 
```

Note:
- The probe starts at `P2` in terminal B, travels to `P1` in terminal A, then returns to `P2`. 
- Terminal A displays `P2` as a remote PID (`<11592.94.0>`), while terminal B displays `P1` as a remote PID (`<11287.93.0>`).
- This confirms that messages were exchanged between the two Erlang runtimes.

## 5. Test on separate computers

Use two computers connected to the same network.

- On mac get ip with:
```bash
ipconfig getifaddr en0
```
- On windows get ip with:
```bash
ipconfig
```

### Computer A

Replace `<ip-a>` with actual ip

```bash
erl -name chord_a@<ip-a> -setcookie chordy
```

Create and register the first Chord node:

```erlang
P1 = node1:start(10).
register(chord1, P1).
```

### Computer B

Replace `<ip-b>` with actual ip

```bash
erl -name chord_b@<ip-b> -setcookie chordy
```

Join a second Chord node through the registered node on computer A and run a probe (Replace `<ip-a>` with actual ip):

```erlang
Peer = {chord1, 'chord_a@<ip-a>'}.
```

```erlang
P2 = node1:start(20, Peer).
timer:sleep(2500).
P2 ! probe.
```

### Results
```sh
(chord_a@130.229.159.9)1> P1 = node1:start(10).
<0.93.0>
(chord_a@130.229.159.9)2> register(chord1, P1).
true
Elapsed probe duration: -39684 microseconds
Current round trip probe nodes: [<11589.99.0>]
(chord_a@130.229.159.9)3> 
```

```sh
(chord_b@130.229.191.255)4> Peer = {chord1, 'chord_a@130.229.159.9'}.
{chord1,'chord_a@130.229.159.9'}
(chord_b@130.229.191.255)5> P2 = node1:start(20, Peer).
<0.99.0>
(chord_b@130.229.191.255)6> timer:sleep(2500).
ok
(chord_b@130.229.191.255)7> P2 ! probe.
probe
Total probe round-trip duration: 8951 microseconds
Round trip probe nodes: [<10550.93.0>,<0.99.0>]
```

Note:
- The cross-computer test succeeded.
- P2 connected to P1 using the registered node name and shared cookie then a probe travelled through both nodes and returned to its origin.
- The negative intermediate time on computer A is caused by small differences between the two computers system clocks.
- The final round-trip time measured on the originating node is valid, because both timestamps of the calculation come from the same computer system clock.