# Migration Guide

This document gathered all breaking changes and migrations requirement between versions.

<!--
When new content need to be added to the migration guide, make sure they're following the format:
1. Add a version in the *Breaking versions* section, with a version anchor.
2. Use *Summary* and *Details* to introduce the migration.
-->

## Breaking versions

- [2.6.0](#260)

## 2.6.0

### Summary

- `ConnectionManager.getConnection` now requires redirection records as a parameter.

### Details

#### `ConnectionManager.getConnection`

```diff
 /// Get the connection(may reuse) for each request.
 Future<ClientTransportConnection> getConnection(
   RequestOptions options,
+  List<RedirectRecord> redirects,
 );
```
