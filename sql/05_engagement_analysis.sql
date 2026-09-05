-- ============================================================
-- 06 — ENGAGEMENT ANALYSIS
-- Mobile Game Product & User Behavior Analytics
-- ============================================================


-- ============================================================
-- 1. OVERALL GAMEPLAY EVENT VOLUME
--
-- Business Question:
-- Which gameplay actions occur most frequently?
-- ============================================================

SELECT
  event_name,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS unique_players

FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

WHERE event_name IN (
  'level_start',
  'level_complete',
  'level_fail',
  'level_retry',
  'level_reset',

  'level_start_quickplay',
  'level_complete_quickplay',
  'level_fail_quickplay',
  'level_retry_quickplay',
  'level_reset_quickplay'
)

GROUP BY event_name
ORDER BY event_count DESC;



-- ============================================================
-- 2. NORMAL vs QUICKPLAY ENGAGEMENT
--
-- Business Question:
-- Which gameplay mode generates more activity?
--
-- NOTE:
-- This measures event volume, NOT unique gameplay attempts.
-- ============================================================

SELECT

  CASE
    WHEN event_name LIKE '%quickplay%'
      THEN 'Quickplay'
    ELSE 'Normal'
  END AS game_mode,

  COUNT(*) AS gameplay_events,

  COUNT(DISTINCT user_pseudo_id)
    AS unique_players

FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

WHERE event_name IN (
  'level_start',
  'level_complete',
  'level_fail',
  'level_retry',
  'level_reset',

  'level_start_quickplay',
  'level_complete_quickplay',
  'level_fail_quickplay',
  'level_retry_quickplay',
  'level_reset_quickplay'
)

GROUP BY game_mode
ORDER BY gameplay_events DESC;



-- ============================================================
-- 3. GAMEPLAY ENGAGEMENT PER PLAYER
--
-- Business Question:
-- Among players who interacted with gameplay,
-- how many gameplay events did they generate?
-- ============================================================

WITH player_gameplay AS (

  SELECT
    user_pseudo_id,

    COUNT(*) AS gameplay_events,

    COUNTIF(
      event_name IN (
        'level_start',
        'level_start_quickplay'
      )
    ) AS starts,

    COUNTIF(
      event_name IN (
        'level_complete',
        'level_complete_quickplay'
      )
    ) AS completes,

    COUNTIF(
      event_name IN (
        'level_fail',
        'level_fail_quickplay'
      )
    ) AS fails,

    COUNTIF(
      event_name IN (
        'level_retry',
        'level_retry_quickplay'
      )
    ) AS retries

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  WHERE event_name IN (
    'level_start',
    'level_complete',
    'level_fail',
    'level_retry',
    'level_start_quickplay',
    'level_complete_quickplay',
    'level_fail_quickplay',
    'level_retry_quickplay'
  )

  GROUP BY user_pseudo_id
)

SELECT
  COUNT(*) AS gameplay_players,

  ROUND(AVG(gameplay_events), 2)
    AS avg_gameplay_events,

  APPROX_QUANTILES(gameplay_events, 100)[OFFSET(50)]
    AS median_gameplay_events,

  ROUND(AVG(starts), 2)
    AS avg_starts,

  ROUND(AVG(completes), 2)
    AS avg_completes,

  ROUND(AVG(fails), 2)
    AS avg_fails,

  ROUND(AVG(retries), 2)
    AS avg_retries

FROM player_gameplay;



-- ============================================================
-- 4. NORMAL LEVEL PERFORMANCE BY LEVEL
--
-- Business Question:
-- Are some normal levels associated with unusually
-- low completion or high failure?
--
-- IMPORTANT:
-- These are event-based ratios.
-- They are NOT yet a sequential funnel.
-- ============================================================

SELECT
  CAST(level AS INT64) AS level,

  COUNTIF(event_name = 'level_start')
    AS starts,

  COUNTIF(event_name = 'level_complete')
    AS completes,

  COUNTIF(event_name = 'level_fail')
    AS fails,

  COUNTIF(event_name = 'level_retry')
    AS retries,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(event_name = 'level_complete'),
      COUNTIF(event_name = 'level_start')
    ) * 100,
    2
  ) AS complete_to_start_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(event_name = 'level_fail'),
      COUNTIF(event_name = 'level_start')
    ) * 100,
    2
  ) AS fail_to_start_pct

FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

WHERE event_name IN (
  'level_start',
  'level_complete',
  'level_fail',
  'level_retry'
)
AND level IS NOT NULL

GROUP BY level

HAVING starts >= 100

ORDER BY level;



-- ============================================================
-- 5. QUICKPLAY PERFORMANCE BY BOARD
--
-- Business Question:
-- Do quickplay boards show different completion/failure
-- patterns?
-- ============================================================

SELECT
  board,

  COUNTIF(event_name = 'level_start_quickplay')
    AS starts,

  COUNTIF(event_name = 'level_complete_quickplay')
    AS completes,

  COUNTIF(event_name = 'level_fail_quickplay')
    AS fails,

  COUNTIF(event_name = 'level_retry_quickplay')
    AS retries,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(event_name = 'level_complete_quickplay'),
      COUNTIF(event_name = 'level_start_quickplay')
    ) * 100,
    2
  ) AS complete_to_start_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(event_name = 'level_fail_quickplay'),
      COUNTIF(event_name = 'level_start_quickplay')
    ) * 100,
    2
  ) AS fail_to_start_pct

FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

WHERE event_name IN (
  'level_start_quickplay',
  'level_complete_quickplay',
  'level_fail_quickplay',
  'level_retry_quickplay'
)
AND board IS NOT NULL

GROUP BY board

ORDER BY starts DESC;



-- ============================================================
-- 6. PLAYERS WITH GAMEPLAY vs WITHOUT GAMEPLAY
--
-- Business Question:
-- What share of observed players actually generated
-- one of our core gameplay events?
-- ============================================================

WITH player_flags AS (

  SELECT
    user_pseudo_id,

    MAX(
      CASE
        WHEN event_name IN (
          'level_start',
          'level_complete',
          'level_fail',
          'level_retry',
          'level_reset',

          'level_start_quickplay',
          'level_complete_quickplay',
          'level_fail_quickplay',
          'level_retry_quickplay',
          'level_reset_quickplay'
        )
        THEN 1
        ELSE 0
      END
    ) AS played_game

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  GROUP BY user_pseudo_id
)

SELECT
  played_game,

  COUNT(*) AS players,

  ROUND(
    COUNT(*) * 100.0 /
    SUM(COUNT(*)) OVER (),
    2
  ) AS player_pct

FROM player_flags

GROUP BY played_game

ORDER BY played_game DESC;