/**
 * environment-measurement-id-router.js
 * ------------------------------------------------------------------
 * A GTM "Custom JavaScript" variable that returns the correct GA4
 * Measurement ID for the current environment.
 *
 * WHY THIS EXISTS
 * A single GTM container usually serves dev, QA, staging and production.
 * If every environment sends to the same GA4 property, test traffic
 * pollutes production reporting. If the routing has no fail-safe, a
 * missing/late environment signal can silently dump production traffic
 * into the QA property. This variable centralises the routing in ONE
 * place with an explicit fail-safe default, so that failure mode can't
 * happen.
 *
 * HOW TO USE
 * 1. In GTM: Variables -> New -> Custom JavaScript -> paste this function.
 * 2. In your GA4 Configuration/Event tags, set the Measurement ID field
 *    to this variable (e.g. {{GA4 - Measurement ID Router}}) instead of
 *    a hard-coded ID.
 * 3. Replace the placeholder IDs below with your real property IDs.
 *
 * The environment signal is read from a data-layer variable. Create a
 * Data Layer Variable in GTM (e.g. "DLV - page.environment") that reads
 * page.environment, then reference it where marked below.
 * ------------------------------------------------------------------
 */
function () {
  // Read the environment string from the data layer.
  // Replace {{DLV - page.environment}} with your Data Layer Variable.
  // Fallback to '' so the code never throws if the signal is missing.
  var environment = String({{DLV - page.environment}} || '').toLowerCase();

  // Ordered routing table. First matching pattern wins.
  // Keep production FIRST so an exact 'production' never partial-matches
  // a test rule by accident.
  var routes = [
    { pattern: /^prod(uction)?$/, id: 'G-PRODXXXXXX' }, // live property
    { pattern: /^(dev|qa|stage|staging|uat)$/, id: 'G-TESTXXXXXX' } // non-prod property
  ];

  for (var i = 0; i < routes.length; i++) {
    if (routes[i].pattern.test(environment)) {
      return routes[i].id;
    }
  }

  // FAIL-SAFE: if the environment is unknown, empty, or arrived late,
  // route to the TEST property. The guiding rule is simple and strict:
  // when in doubt, never contaminate production.
  return 'G-TESTXXXXXX';
}
