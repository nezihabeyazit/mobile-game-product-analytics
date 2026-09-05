-- ============================================================
-- 05b — PLAYER ACTIVITY KPIs
-- New vs Returning / Sessions / Active Days
-- ============================================================


-- ============================================================
-- 1. NEW vs RETURNING PLAYERS BY DAY
--
-- Definition:
-- New player:
--   activity_date = player's first observed activity date
--
-- Returning player:
--   player was already observed before this date
--
-- IMPORTANT:
-- "New" means new within THIS DATASET.
-- We cannot prove this was the player's true first-ever
-- interaction with the game.
-- ============================================================

WITH first_activity AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS first_activity_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
)

SELECT
  p.activity_date,

  COUNTIF(
    p.activity_date = f.first_activity_date
  ) AS new_players,

  COUNTIF(
    p.activity_date > f.first_activity_date
  ) AS returning_players,

  COUNT(*) AS dau

FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p

JOIN first_activity f
  ON p.user_pseudo_id = f.user_pseudo_id

GROUP BY p.activity_date
ORDER BY p.activity_date;



-- ============================================================
-- 2. VALIDATION — NEW + RETURNING = DAU
--
-- Expected:
-- 0 rows
--
-- If rows appear, classification logic is wrong.
-- ============================================================

WITH first_activity AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS first_activity_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
),

daily_status AS (
  SELECT
    p.activity_date,

    COUNTIF(
      p.activity_date = f.first_activity_date
    ) AS new_players,

    COUNTIF(
      p.activity_date > f.first_activity_date
    ) AS returning_players,

    COUNT(*) AS dau

  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p

  JOIN first_activity f
    ON p.user_pseudo_id = f.user_pseudo_id

  GROUP BY p.activity_date
)

SELECT *
FROM daily_status
WHERE new_players + returning_players != dau;



-- ============================================================
-- 3. MONTHLY NEW vs RETURNING PLAYER-DAYS
--
-- NOTE:
-- These are PLAYER-DAY observations, not unique monthly players.
-- This answers:
-- "Of daily activity generated during the month,
--  how much came from first-observed vs returning players?"
-- ============================================================

WITH first_activity AS (
  SELECT
    user_pseudo_id,
    MIN(activity_date) AS first_activity_date
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
)

SELECT
  DATE_TRUNC(p.activity_date, MONTH) AS month_start,

  COUNTIF(
    p.activity_date = f.first_activity_date
  ) AS new_player_days,

  COUNTIF(
    p.activity_date > f.first_activity_date
  ) AS returning_player_days,

  COUNT(*) AS total_player_days

FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p

JOIN first_activity f
  ON p.user_pseudo_id = f.user_pseudo_id

GROUP BY month_start
ORDER BY month_start;



-- ============================================================
-- 4. SESSIONS PER ACTIVE PLAYER BY DAY
--
-- Business question:
-- How frequently do active players start sessions?
--
-- Formula:
-- total session_start events / active players
-- ============================================================

SELECT
  activity_date,

  COUNT(*) AS active_players,

  SUM(session_starts) AS total_sessions,

  ROUND(
    SAFE_DIVIDE(
      SUM(session_starts),
      COUNT(*)
    ),
    2
  ) AS sessions_per_active_player

FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

GROUP BY activity_date
ORDER BY activity_date;



-- ============================================================
-- 5. PLAYER-LEVEL ACTIVE DAYS
--
-- Business question:
-- Across the observation period, on how many distinct
-- days was each player active?
--
-- Since grain = player × day:
-- COUNT(*) = active days for that player.
-- ============================================================

WITH player_activity AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS active_days
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
)

SELECT
  COUNT(*) AS total_players,

  ROUND(AVG(active_days), 2)
    AS avg_active_days,

  APPROX_QUANTILES(active_days, 100)[OFFSET(50)]
    AS median_active_days,

  MAX(active_days)
    AS max_active_days

FROM player_activity;



-- ============================================================
-- 6. ACTIVE DAY DISTRIBUTION
--
-- Helps reveal whether most users play only once/few times
-- while a smaller group plays repeatedly.
-- ============================================================

WITH player_activity AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS active_days
  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
  GROUP BY user_pseudo_id
)

SELECT
  CASE
    WHEN active_days = 1 THEN '1 day'
    WHEN active_days BETWEEN 2 AND 3 THEN '2-3 days'
    WHEN active_days BETWEEN 4 AND 7 THEN '4-7 days'
    WHEN active_days BETWEEN 8 AND 14 THEN '8-14 days'
    WHEN active_days BETWEEN 15 AND 30 THEN '15-30 days'
    ELSE '31+ days'
  END AS active_day_segment,

  COUNT(*) AS players,

  ROUND(
    COUNT(*) * 100.0 /
    SUM(COUNT(*)) OVER (),
    2
  ) AS player_pct

FROM player_activity

GROUP BY active_day_segment

ORDER BY
  MIN(active_days);