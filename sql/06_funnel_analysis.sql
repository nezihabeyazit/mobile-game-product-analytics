-- ============================================================
-- 07 — FUNNEL / PLAYER JOURNEY ANALYSIS
-- Mobile Game Product & User Behavior Analytics
-- ============================================================


-- ============================================================
-- 1. NORMAL LEVEL REACH BY PLAYER
--
-- Business Question:
-- How many unique players reached each normal level?
--
-- Definition:
-- A player "reached" a level if they generated level_start
-- for that level at least once.
--
-- Grain:
-- 1 row = 1 level
-- ============================================================

SELECT
  CAST(level AS INT64) AS level,
  COUNT(DISTINCT user_pseudo_id) AS players_reached

FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

WHERE event_name = 'level_start'
  AND level IS NOT NULL

GROUP BY level
ORDER BY level;



-- ============================================================
-- 2. NORMAL LEVEL PLAYER-LEVEL START → COMPLETE
--
-- Business Question:
-- Among players who started a level, what share ever completed
-- that same level?
--
-- IMPORTANT:
-- This is player-level conversion, not event-count ratio.
-- ============================================================

WITH level_players AS (

  SELECT
    user_pseudo_id,
    CAST(level AS INT64) AS level,

    MAX(
      CASE WHEN event_name = 'level_start'
      THEN 1 ELSE 0 END
    ) AS started,

    MAX(
      CASE WHEN event_name = 'level_complete'
      THEN 1 ELSE 0 END
    ) AS completed,

    MAX(
      CASE WHEN event_name = 'level_fail'
      THEN 1 ELSE 0 END
    ) AS failed

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  WHERE event_name IN (
    'level_start',
    'level_complete',
    'level_fail'
  )
  AND level IS NOT NULL

  GROUP BY
    user_pseudo_id,
    level
)

SELECT
  level,

  COUNTIF(started = 1) AS players_started,

  COUNTIF(started = 1 AND completed = 1)
    AS players_completed,

  COUNTIF(started = 1 AND failed = 1)
    AS players_failed,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(started = 1 AND completed = 1),
      COUNTIF(started = 1)
    ) * 100,
    2
  ) AS player_completion_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(started = 1 AND failed = 1),
      COUNTIF(started = 1)
    ) * 100,
    2
  ) AS player_failure_pct

FROM level_players

GROUP BY level

HAVING players_started >= 100

ORDER BY level;



-- ============================================================
-- 3. LEVEL-TO-LEVEL PROGRESSION
--
-- Business Question:
-- Of players who reached level N,
-- what share also reached level N+1?
--
-- This is closer to a progression funnel.
-- ============================================================

WITH reached AS (

  SELECT DISTINCT
    user_pseudo_id,
    CAST(level AS INT64) AS level

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  WHERE event_name = 'level_start'
    AND level IS NOT NULL
),

progression AS (

  SELECT
    a.level,

    COUNT(DISTINCT a.user_pseudo_id)
      AS players_at_level,

    COUNT(DISTINCT b.user_pseudo_id)
      AS players_reaching_next_level

  FROM reached a

  LEFT JOIN reached b
    ON a.user_pseudo_id = b.user_pseudo_id
   AND b.level = a.level + 1

  GROUP BY a.level
)

SELECT
  level,
  players_at_level,
  players_reaching_next_level,

  ROUND(
    SAFE_DIVIDE(
      players_reaching_next_level,
      players_at_level
    ) * 100,
    2
  ) AS next_level_conversion_pct,

  ROUND(
    (1 - SAFE_DIVIDE(
      players_reaching_next_level,
      players_at_level
    )) * 100,
    2
  ) AS dropoff_pct

FROM progression

WHERE players_at_level >= 100

ORDER BY level;



-- ============================================================
-- 4. QUICKPLAY PLAYER-LEVEL START → COMPLETE / FAIL
--
-- Business Question:
-- How do S / M / L boards compare at player level?
--
-- Grain:
-- 1 row = 1 board
-- ============================================================

WITH board_players AS (

  SELECT
    user_pseudo_id,
    board,

    MAX(
      CASE WHEN event_name = 'level_start_quickplay'
      THEN 1 ELSE 0 END
    ) AS started,

    MAX(
      CASE WHEN event_name = 'level_complete_quickplay'
      THEN 1 ELSE 0 END
    ) AS completed,

    MAX(
      CASE WHEN event_name = 'level_fail_quickplay'
      THEN 1 ELSE 0 END
    ) AS failed

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  WHERE event_name IN (
    'level_start_quickplay',
    'level_complete_quickplay',
    'level_fail_quickplay'
  )
  AND board IS NOT NULL

  GROUP BY
    user_pseudo_id,
    board
)

SELECT
  board,

  COUNTIF(started = 1) AS players_started,

  COUNTIF(started = 1 AND completed = 1)
    AS players_completed,

  COUNTIF(started = 1 AND failed = 1)
    AS players_failed,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(started = 1 AND completed = 1),
      COUNTIF(started = 1)
    ) * 100,
    2
  ) AS player_completion_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(started = 1 AND failed = 1),
      COUNTIF(started = 1)
    ) * 100,
    2
  ) AS player_failure_pct

FROM board_players

GROUP BY board

ORDER BY players_started DESC;



-- ============================================================
-- 5. CORE GAMEPLAY ENTRY FUNNEL
--
-- Business Question:
-- Of all observed players:
-- how many reached gameplay?
-- how many completed any gameplay?
-- how many failed any gameplay?
--
-- ============================================================

WITH player_flags AS (

  SELECT
    user_pseudo_id,

    MAX(
      CASE
        WHEN event_name IN (
          'level_start',
          'level_start_quickplay'
        )
        THEN 1 ELSE 0
      END
    ) AS started_gameplay,

    MAX(
      CASE
        WHEN event_name IN (
          'level_complete',
          'level_complete_quickplay'
        )
        THEN 1 ELSE 0
      END
    ) AS completed_gameplay,

    MAX(
      CASE
        WHEN event_name IN (
          'level_fail',
          'level_fail_quickplay'
        )
        THEN 1 ELSE 0
      END
    ) AS failed_gameplay

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  GROUP BY user_pseudo_id
)

SELECT
  COUNT(*) AS total_players,

  COUNTIF(started_gameplay = 1)
    AS players_started_gameplay,

  COUNTIF(completed_gameplay = 1)
    AS players_completed_gameplay,

  COUNTIF(failed_gameplay = 1)
    AS players_failed_gameplay,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(started_gameplay = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS gameplay_start_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(completed_gameplay = 1),
      COUNTIF(started_gameplay = 1)
    ) * 100,
    2
  ) AS gameplay_completion_among_starters_pct

FROM player_flags;