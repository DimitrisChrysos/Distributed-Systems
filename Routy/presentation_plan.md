# Routy world demo plan

This plan uses:
- 2 computers (continents)
- 4 Countries (terminals); 2 on each computer
- 6 Cities (routy router processes); 3 on each computer

It demonstrates directional links, link-state flooding, Dijkstra routing, a sink node, one bidirectional pair, and monitor-based failure handling.

## 1. Topology

<!-- ```text
Athens -> Thessaloniki -> Stockholm -> Delhi -> Tokyo -> Athens
                                              |
                                              v
                                            Kyoto
                                           (sink)

Tokyo -> Delhi
``` -->

![presentation-topology](/presentation_graph.png)

It is a one-directional cycle graph that also has:
- `Tokyo -> Delhi` bidirectional pair
- Kyoto sink node

## 2. Who runs what

| Computer | Erlang node (country) | Registered router process | Logical city |
|---|---|---|---|
| Europe PC | `greece@EU_IP` | `athens_r` | Athens |
| Europe PC | `greece@EU_IP` | `thessaloniki_r` | Thessaloniki |
| Europe PC | `sweden@EU_IP` | `stockholm_r` | Stockholm |
| Asia PC | `india@ASIA_IP` | `delhi_r` | Delhi |
| Asia PC | `japan@ASIA_IP` | `tokyo_r` | Tokyo |
| Asia PC | `japan@ASIA_IP` | `kyoto_r` | Kyoto |

- Replace `EU_IP` with Dimitris pc ip `ipconfig getifaddr en0`
- Replace `ASIA_IP` with Ilias pc ip `ipconfig`

## 3. Start four Erlang terminals

### Europe PC: Greece terminal

```bash
erl -name greece@EU_IP -setcookie routy -connect_all false
```

### Europe PC: Sweden terminal

```bash
erl -name sweden@EU_IP -setcookie routy -connect_all false
```

### Asia PC: Japan terminal

```bash
erl -name japan@ASIA_IP -setcookie routy -connect_all false
```

### Asia PC: India terminal

```bash
erl -name india@ASIA_IP -setcookie routy -connect_all false
```

In each Erlang shell, compile the modules:

```erlang
c(map), c(intf), c(hist), c(dijkstra), c(routy).
```

## 4. Start the six routers

### Greece terminal

```erlang
routy:start(athens_r, athens).
routy:start(thessaloniki_r, thessaloniki).
```

### Sweden terminal

```erlang
routy:start(stockholm_r, stockholm).
```

### Japan terminal

```erlang
routy:start(tokyo_r, tokyo).
routy:start(kyoto_r, kyoto).
```

### India terminal

```erlang
routy:start(delhi_r, delhi).
```

## 5. Add the directional interfaces

### Greece terminal

```erlang
athens_r ! {add, thessaloniki, thessaloniki_r}.

thessaloniki_r !
    {add, stockholm, {stockholm_r, 'sweden@EU_IP'}}.
```

### Sweden terminal

```erlang
stockholm_r ! {add, delhi, {delhi_r, 'india@ASIA_IP'}}.
```

### India terminal

```erlang
delhi_r ! {add, tokyo, {tokyo_r, 'japan@ASIA_IP'}}.
```

### Japan terminal

```erlang
tokyo_r ! {add, athens, {athens_r, 'greece@EU_IP'}}.
tokyo_r ! {add, delhi, {delhi_r, 'india@ASIA_IP'}}.
tokyo_r ! {add, kyoto, kyoto_r}.
```

<!-- At this point the visible topology is:

```text
Athens -> Thessaloniki -> Stockholm -> Delhi -> Tokyo -> Athens
                                              |
                                              v
                                            Kyoto

Tokyo -> Delhi
``` -->
This creates the topology:
![presentation-topology](/presentation_graph.png)

## 6. Broadcast link-state information and build tables

### Greece terminal

```erlang
athens_r ! broadcast.
thessaloniki_r ! broadcast.
```

### Sweden terminal

```erlang
stockholm_r ! broadcast.
```

### India terminal

```erlang
delhi_r ! broadcast.
```

### Japan terminal

```erlang
tokyo_r ! broadcast.
kyoto_r ! broadcast.  % not needed since Kyoto has no neighbours
```

Wait:

```erlang
timer:sleep(1000).
```

Rebuild every routing table.

### Greece terminal

```erlang
athens_r ! update.
thessaloniki_r ! update.
```

### Sweden terminal

```erlang
stockholm_r ! update.
```

### India terminal

```erlang
delhi_r ! update.
```

### Japan terminal

```erlang
tokyo_r ! update.
kyoto_r ! update.
```

Wait again:

```erlang
timer:sleep(1000).
```

Show a status:
```erlang
routy:status(athens_r).
```

Explain the output as follows:

- `Hist` records the latest link-state counter seen from each origin.
- `Intf` contains only direct outgoing neighbours and monitor references.
- `Map` is the learned directional network graph.
- `Table` maps each destination to the first gateway/next hop.

## 7. Demonstrate working routing

### A. Long intercontinental route

In the Greece terminal:

```erlang
athens_r ! {send, kyoto, "Athens to Kyoto"}.
```

Expected route:

```text
Athens -> Thessaloniki -> Stockholm -> Delhi -> Tokyo -> Kyoto
```

Each forwarding router should print a routing message in its terminal. Kyoto
should print that it received the message.

### B. The one bidirectional pair

In the Japan terminal:

```erlang
tokyo_r ! {send, delhi, "Tokyo to Delhi"}.
```

This should be delivered directly through the separate `Tokyo -> Delhi` link.

### C. Sink-node limitation

In the Japan terminal:

```erlang
kyoto_r ! {send, athens, "Kyoto cannot forward this"}.
```

Kyoto has no gateway in its table because it has no outgoing interface. The
packet is dropped safely; Athens receives nothing. This is expected behaviour
for a sink node.

## 8. Demonstrate failure handling

Start with the safe failure, stop the sink node. In the Japan terminal:

```erlang
routy:stop(kyoto_r).
```

Tokyo should receive a monitor `'DOWN'` message and remove Kyoto from its
interfaces. Verify it:

```erlang
timer:sleep(100).
routy:status(tokyo_r).
```

The five-city directed cycle still exists, so it should still route normally. To refresh the learned state after the change, broadcast tokyo and update all surviving routers again but leave out `kyoto_r`.

Broadcast Tokyo:
```erlang
tokyo_r ! broadcast.
```

Then rebuild the routing tables of every surviving router:
```erlang
athens_r ! update.
thessaloniki_r ! update.
stockholm_r ! update.
delhi_r ! update.
tokyo_r ! update.
```

Then send a message that stays in the surviving cycle, for example in Greece:

```erlang
athens_r ! {send, tokyo, "Cycle still works after Kyoto failed"}.
```

Expected route:

```text
Athens -> Thessaloniki -> Stockholm -> Delhi -> Tokyo
```

## 9. Optional final limitation demonstration

```erlang
routy:stop(stockholm_r).
```

## 10. Optional whole-country node failure

```erlang
q().
```
