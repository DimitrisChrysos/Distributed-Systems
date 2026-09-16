# Routy

A simple link-state routing protocol implemented in Erlang for KTH ID2201 (Distributed Systems).

## Modules

- **`routy.erl`**: Core router process handling message routing, link broadcasts, and process monitoring.
- **`dijkstra.erl`**: Computes shortest-path routing tables using Dijkstra's algorithm.
- **`map.erl`**: Maintains the global network topology map.
- **`intf.erl`**: Manages direct neighbor interfaces (Name, Monitor Ref, Pid).
- **`hist.erl`**: Tracks message sequence numbers to discard duplicate broadcasts.
- **`routy_tests.erl`**: Automated test suite simulating network topology, multi-hop routing, node crashes, and recovery.

## How to Run

1. Open the Erlang shell in the `Routy` directory:
   ```bash
   erl
   ```
2. Compile and run the demo:
   ```erlang
   c(hist), c(map), c(intf), c(dijkstra), c(routy), c(routy_tests).
   routy_tests:run().
   ```
