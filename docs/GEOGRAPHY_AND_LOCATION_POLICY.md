# Geography and Location Policy

Use WGS84 latitude/longitude and validate coordinate ranges.

Hierarchy: country -> state/admin-area-1 -> region -> LGA/admin-area-2 -> district -> zone -> store.

A coordinate authorizes an allocation only after the configured hierarchy resolves consistently. A spatial implementation may use PostGIS ST_Covers for polygon/multipolygon boundaries.

Retain coordinate source, effective timestamp, resolved hierarchy, matched boundary codes, policy result, correlation and operation IDs.

GPS is telemetry and is not cryptographic proof of physical presence.
