# Routy: Final Deliverables Discussion Guide

The final work has two deliverables:

1. A 2-3 page report.
2. An automated test that starts at least five routers and demonstrates Routy's functionality.

## Before the report

Verify that Routy can demonstrate all of the following:

- Adding and removing interfaces.
- Detecting a crashed neighbour with Erlang monitors.
- Broadcasting and forwarding link-state messages.
- Rejecting duplicate or old link-state messages with `hist`.
- Rebuilding routing tables with Dijkstra.
- Delivering direct messages and forwarding multi-hop messages.
- Safely dropping messages for unknown or unreachable destinations.

## Suggested report structure

### 1. Introduction

Briefly explain that Routy is a small Erlang implementation of a link-state routing protocol. Routers learn a directional network map, then use Dijkstra's algorithm to select a next-hop gateway.

### 2. Implementation overview

- `map.erl`: stores the directional network topology.
- `dijkstra.erl`: computes routing tables from a map and direct gateways.
- `intf.erl`: stores direct neighbours, monitor references, and process identifiers.
- `hist.erl`: records the newest link-state counter seen from each router.
- `routy.erl`: runs the router process and handles interfaces, link-state messages, updates, and ordinary routed messages.

### 3. Difficulties and solutions

Discuss the difficulties we actually encountered, for example:

- Keeping Dijkstra's working entries sorted after replacing a path.
- Understanding that links are directional, so known nodes can still be unreachable.
- Avoiding link-state flooding loops and stale updates with message counters.
- Working with Erlang processes, registered names, PIDs, monitors, and asynchronous messages.
- Handling the temporary difference between the frequently updated map and the manually updated routing table.

### 4. Possible improvements

- Use a hashmap instead of a list in the `map` module.
   - This will make operations like `intf:remove()`, `intf:lookup()` and `intf:ref()` faster, since hashmap lookup is O(1), while searching through a list is O(n). A map entry could have the format: `Name: {Ref, Pid}` (for faster operations by name). We could also have a second map in the format of `Ref: Name`, in order to make `intf:name()` more efficient (but we also increase the space complexity since each interface will need to be stored in two maps).
- In `dijkstra:table()`, iterate the list only once instead of twice (have a check like: if node is a gateway->{node,0,node} else->{node, inf, unknown}).
- Maybe use different data structures for the interfaces and history (maybe set for interfaces and hashmap for history)?
- Broadcast link-state information automatically when an interface changes.
- Rebuild the routing table automatically when the map changes.
- Support weighted links instead of treating every link as one hop.
- Remove or refresh old link-state information after network failures.
- Return useful errors or acknowledgements for dropped packets.
- Add timeouts, clearer logs, and more readable status output.

### 5. Testing and results

Describe the five-router topology, the messages sent, the selected paths, and what happened after a router failure. Add terminal screenshots if appropriate for the course.

## Automated five-router test

Five router processes on one Erlang machine are sufficient. A useful topology is:

```text
stockholm <-> lund <-> malmo <-> gothenburg
                         |
                      uppsala
```

The test should automatically:

1. Start five routers.
2. Add interfaces to form the topology.
3. Broadcast every router's link-state message.
4. Wait briefly for link-state forwarding.
5. Send `update` to every router.
6. Inspect important routing-table entries through status messages.
7. Send messages across several hops, such as Stockholm to Gothenburg.
8. Try an unknown destination and confirm that it is dropped safely.
9. Stop one router, confirm that its neighbour removes the interface, and test the behaviour of any stale route.
10. Stop every remaining router so the test cleans up after itself.

## Questions to decide together

- Which exact five-router topology will make shortest paths easy to demonstrate?
- How will the automated test inspect and assert router state?
- Which implementation difficulties are worth describing honestly in the report?
- Which improvements are realistic extensions versus larger protocol redesigns?
