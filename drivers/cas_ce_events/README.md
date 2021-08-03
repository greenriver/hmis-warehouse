# CasCeEvents

Propagate CAS generated CE events from CAS generated  referral events
(in the `cas_referral_events` table) into the synthetic events table, and
finally as sythetic events in the HUD events table.

## CAS Configuration

In order to attach synthetic events to enrollments, CAS Programs must be
associated with HMIS Projects.

## Warehouse Configuration

To distinguish synthetic events, they are stored in a warehouse data source
'CAS'.