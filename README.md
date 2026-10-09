# Enterprise Measurement Architecture — Reference Implementations

**Measurement & Marketing-Data Architect** — GA4 · Server-Side GTM · BigQuery · GMP · Adobe

This repo holds sanitized, generic reference implementations from real enterprise
measurement work — the kind of artifacts that sit underneath a clean analytics
stack. They're here to show *how* the system is designed, not to be dropped into
a site unchanged.

## What's here

| File | What it demonstrates |
|------|----------------------|
| [`ecommerce-datalayer-schema.json`](./ecommerce-datalayer-schema.json) | A complete GA4 ecommerce data-layer spec — item-scoped arrays, consent states, and refund handling. The contract a developer builds against so measurement is unambiguous. |
| [`environment-measurement-id-router.js`](./environment-measurement-id-router.js) | A GTM Custom JavaScript variable that routes hits to the correct GA4 property per environment, with a fail-safe default so test traffic never pollutes production. |
| [`bq-session-funnel-diagnostic.sql`](./bq-session-funnel-diagnostic.sql) | A session-level ecommerce funnel built on the raw GA4 BigQuery export — exact step conversion rates the GA4 UI flattens. |

## Approach

- **System first.** The data-layer spec is the source of truth; tags are downstream of it.
- **Fail safe.** Routing and consent default to the safe state, so a missing signal degrades quietly instead of corrupting production data.
- **Warehouse-native.** The hard questions (true funnels, net-of-refund revenue, attribution) get answered in BigQuery, not forced through a UI.

## Work with me

Available for freelance measurement architecture — GA4/GTM implementation,
server-side tagging, BigQuery modeling, and Google Ads measurement.
Reach out through my freelance profile to scope a project.
