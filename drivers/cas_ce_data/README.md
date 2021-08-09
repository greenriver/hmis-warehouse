# CasCeData

Propagate CAS generated CE assessments and events from CAS generated 
assessments (in the `cas_ce_assessments` table), and referral events
(in the `cas_referral_events` table) into the synthetic events table;
and then reflect them as as synthetic events in the HUD events table.

## CAS Configuration

In order to attach synthetic data to enrollments, CAS Programs must be
associated with HMIS Projects.

## Warehouse Configuration

To distinguish CAS synthetic data, it is stored in a warehouse data source
with the short name 'CAS'.