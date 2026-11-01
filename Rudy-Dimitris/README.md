# Rudy: A Small Web Server

## How to run

### 1. Compile everything
```erlang
c(http).
c(rudy).
c(test).
```

### 2. Start server
```erlang
% for a sequential single-handler server
rudy:start(8080, sequential) % or rudy:start(8080)

% for a one handler-process per request server
rudy:start(8080, process_per_request)

% for a N pool of handler-process server
rudy:start(8080, {pool, N})
```

### 3. Run benchmarks
```erlang
% for a single client benchmark with N requests to test
test:bench(localhost, 8080, N).

% for a single client benchmark with M trials of N requests to test
test:bench_average(localhost, 8080, N, M)

% for a C amount of clients each doing a benchmark with M trials of N requests to test
[spawn(fun() -> test:bench_average(localhost, 8080, N, M) end) || _ <- lists:seq(1, C)].
```

### 4. Stop server
```erlang
rudy:stop().
```