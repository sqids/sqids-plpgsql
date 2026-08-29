# CHANGELOG

## V0.1
-Created install.sql with working but probably under tested working encode/decode

## V0.2
-Added spec tests & fixed any failures

## V0.3
-Marked pure helpers and decode as IMMUTABLE
-Kept table-backed encode STABLE (it reads sqids.blocklist)
-Added sqids.encodeImmutable for generated columns (compiled-in default blocklist, or a TEXT[] argument)
-Reject negative and NULL numbers instead of hanging in toId
