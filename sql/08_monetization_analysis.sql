-- ============================================================
-- 09 — MONETIZATION ANALYSIS
-- Mobile Game Product & User Behavior Analytics
-- ============================================================


-- ============================================================
-- 1. PAYER CONVERSION
--
-- Business Question:
-- What share of observed players made at least one purchase?
-- ============================================================

WITH payer_flags AS (
  SELECT
    user_pseudo_id,

    MAX(
      CASE
        WHEN event_name = 'in_app_purchase'
        THEN 1 ELSE 0
      END
    ) AS is_payer

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  GROUP BY user_pseudo_id
)

SELECT
  COUNT(*) AS total_players,

  COUNTIF(is_payer = 1) AS payers,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(is_payer = 1),
      COUNT(*)
    ) * 100,
    3
  ) AS payer_conversion_pct

FROM payer_flags;



-- ============================================================
-- 2. PURCHASE PRODUCT MIX
--
-- Business Question:
-- Which products were purchased?
-- ============================================================

SELECT
  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'product_id'
  ) AS product_id,

  COUNT(*) AS purchases,

  COUNT(DISTINCT user_pseudo_id) AS payers

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'in_app_purchase'
  AND _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'

GROUP BY product_id

ORDER BY purchases DESC;



-- ============================================================
-- 3. VALIDATED vs NON-VALIDATED / MISSING VALIDATION
--
-- Business Question:
-- How much of purchase activity is explicitly validated?
-- ============================================================

SELECT
  CASE
    WHEN (
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'validated'
    ) = 1
      THEN 'validated'

    WHEN (
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'validated'
    ) IS NULL
      THEN 'missing_validation'

    ELSE 'other'
  END AS validation_status,

  COUNT(*) AS purchases

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'in_app_purchase'
  AND _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'

GROUP BY validation_status

ORDER BY purchases DESC;



-- ============================================================
-- 4. PURCHASES BY CURRENCY
--
-- Business Question:
-- Which currencies appear in the purchase data?
-- ============================================================

SELECT
  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'currency'
  ) AS currency,

  COUNT(*) AS purchases,

  COUNT(DISTINCT user_pseudo_id) AS payers

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'in_app_purchase'
  AND _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'

GROUP BY currency

ORDER BY purchases DESC;



-- ============================================================
-- 5. PURCHASE PRICE INSPECTION
--
-- IMPORTANT:
-- Price is stored as int_value in micros.
-- Example:
-- 990000 = 0.99 units of the purchase currency
--
-- We convert micros to currency units using / 1,000,000.
-- ============================================================

SELECT
  user_pseudo_id,

  TIMESTAMP_MICROS(event_timestamp)
    AS purchase_datetime,

  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'product_id'
  ) AS product_id,

  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'currency'
  ) AS currency,

  SAFE_DIVIDE(
    (
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'price'
    ),
    1000000
  ) AS price_currency_units,

  (
    SELECT ep.value.int_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'validated'
  ) AS validated

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'in_app_purchase'
  AND _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'

ORDER BY purchase_datetime;



-- ============================================================
-- 6. REVENUE BY CURRENCY
--
-- IMPORTANT:
-- DO NOT sum different currencies into one global revenue.
--
-- Revenue is reported separately by currency.
-- ============================================================

SELECT
  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'currency'
  ) AS currency,

  COUNT(*) AS purchases,

  ROUND(
    SUM(
      SAFE_DIVIDE(
        (
          SELECT ep.value.int_value
          FROM UNNEST(event_params) ep
          WHERE ep.key = 'price'
        ),
        1000000
      )
    ),
    2
  ) AS revenue_currency_units

FROM `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'in_app_purchase'
  AND _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'

GROUP BY currency

ORDER BY purchases DESC;



-- ============================================================
-- 7. USD-ONLY ARPU / ARPPU
--
-- Why USD only?
-- Mixing currencies without FX conversion would be invalid.
--
-- ARPU:
-- USD revenue / all observed players
--
-- ARPPU:
-- USD revenue / USD payers
--
-- This is a LIMITED metric because only USD transactions
-- are included.
-- ============================================================

WITH usd_purchases AS (
  SELECT
    user_pseudo_id,

    SAFE_DIVIDE(
      (
        SELECT ep.value.int_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'price'
      ),
      1000000
    ) AS price_usd

  FROM `firebase-public-project.analytics_153293282.events_*`

  WHERE event_name = 'in_app_purchase'
    AND _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND (
      SELECT ep.value.string_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'currency'
    ) = 'USD'
),

player_count AS (
  SELECT
    COUNT(DISTINCT user_pseudo_id) AS total_players
  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`
)

SELECT
  ROUND(SUM(price_usd), 2) AS usd_revenue,

  COUNT(DISTINCT user_pseudo_id) AS usd_payers,

  ROUND(
    SAFE_DIVIDE(
      SUM(price_usd),
      (SELECT total_players FROM player_count)
    ),
    4
  ) AS usd_only_arpu,

  ROUND(
    SAFE_DIVIDE(
      SUM(price_usd),
      COUNT(DISTINCT user_pseudo_id)
    ),
    2
  ) AS usd_arppu

FROM usd_purchases;