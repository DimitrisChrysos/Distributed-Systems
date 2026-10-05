# Questions in tasks

## 1.4

### What are the pros and cons of a more frequent stabilizing procedure?

More frequent stabilization makes the ring repair itself faster after nodes join or leave, so predecessor/successor pointers become correct sooner. The downside is more network messages and processing overhead.

### What is delayed if we don’t do stabilizing that often?

With infrequent stabilization, updates to the ring are delayed, so new nodes take longer to be discovered and linked correctly, so routing can temporarily use outdated successor/predecessor pointers.