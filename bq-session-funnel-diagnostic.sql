-- ============================================================================
-- bq-session-funnel-diagnostic.sql
-- ----------------------------------------------------------------------------
-- Session-level ecommerce funnel from the GA4 BigQuery export.
--
-- WHAT IT DOES
--   Counts how many SESSIONS reached each funnel step
--   (view_item -> add_to_cart -> begin_checkout -> purchase) and the
--   step-to-step conversion rates. This is the kind of diagnostic the
--   GA4 UI flattens or samples; built on the raw export it is exact.
--
-- WHY SESSION-LEVEL
--   A "session" in GA4 = user_pseudo_id + ga_session_id. Counting distinct
--   sessions (not events) stops a user who adds to cart five times from
--   inflating the add_to_cart step.
--
-- HOW TO USE
--   1. Replace `your_project.analytics_XXXXXXXXX` with your dataset.
--   2. Set the date range in the _TABLE_SUFFIX filter (YYYYMMDD).
--   3. Run in BigQuery.
-- ============================================================================

-- Step 1: pull only the events we care about, and extract the session id
--         (ga_session_id lives inside the event_params array, so we UNNEST it).
WITH funnel_events AS (
  SELECT
    user_pseudo_id,
    -- ga_session_id is an int nested in event_params; pull it out via a subquery
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id') AS ga_session_id,
    event_name
  FROM `your_project.analytics_XXXXXXXXX.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20250101' AND '20250131'   -- <-- set your dates
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
),

-- Step 2: collapse to one row per session, flagging which steps it hit.
--         A unique session key = user_pseudo_id + ga_session_id.
sessions AS (
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING)) AS session_key,
    MAX(IF(event_name = 'view_item',      1, 0)) AS hit_view_item,
    MAX(IF(event_name = 'add_to_cart',    1, 0)) AS hit_add_to_cart,
    MAX(IF(event_name = 'begin_checkout', 1, 0)) AS hit_begin_checkout,
    MAX(IF(event_name = 'purchase',       1, 0)) AS hit_purchase
  FROM funnel_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY session_key
)

-- Step 3: aggregate the funnel and compute step-to-step conversion rates.
--         SAFE_DIVIDE avoids a divide-by-zero error if a step has no sessions.
SELECT
  COUNTIF(hit_view_item      = 1) AS view_item_sessions,
  COUNTIF(hit_add_to_cart    = 1) AS add_to_cart_sessions,
  COUNTIF(hit_begin_checkout = 1) AS begin_checkout_sessions,
  COUNTIF(hit_purchase       = 1) AS purchase_sessions,

  ROUND(SAFE_DIVIDE(COUNTIF(hit_add_to_cart = 1),
                    COUNTIF(hit_view_item = 1)) * 100, 1) AS view_to_cart_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(hit_begin_checkout = 1),
                    COUNTIF(hit_add_to_cart = 1)) * 100, 1) AS cart_to_checkout_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(hit_purchase = 1),
                    COUNTIF(hit_begin_checkout = 1)) * 100, 1) AS checkout_to_purchase_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(hit_purchase = 1),
                    COUNTIF(hit_view_item = 1)) * 100, 1) AS overall_view_to_purchase_pct
FROM sessions;
