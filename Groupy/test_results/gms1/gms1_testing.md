# Groupy — gms1 tests (section 2.4)

```erlang
c(gms1).
c(worker).
c(gui).
c(test).
```

## Test 1: add workers manually

```erlang
W1 = test:first(1, gms1, 1000).
W2 = test:add(2, gms1, W1, 1000).
W3 = test:add(3, gms1, W1, 1000).
```

Expected: three windows open and keep the same colour sequence.

Stop all workers:

```erlang
test:stop(W1).
```

## Test 2: create several workers at once

```erlang
W1 = test:more(5, gms1, 1000).
```

Expected: five windows open and keep the same colour sequence.

Stop all workers:

```erlang
test:stop(W1).
```
