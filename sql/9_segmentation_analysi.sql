-- ============================================================
-- 10 — SEGMENTATION ANALYSIS
-- Mobile Game Product & User Behavior Analytics
-- ============================================================


-- ============================================================
-- 1. PLATFORM — PLAYER ACTIVITY
--
-- Business Question:
-- Do Android and iOS players show different activity patterns?
-- ============================================================

SELECT
  platform,

  COUNT(DISTINCT user_pseudo_id) AS players,

  COUNT(*) AS player_days,

  ROUND(
    SAFE_DIVIDE(
      COUNT(*),
      COUNT(DISTINCT user_pseudo_id)
    ),
    2
  ) AS avg_active_days_per_player,

  ROUND(
    AVG(session_starts),
    2
  ) AS avg_sessions_per_player_day,

  ROUND(
    AVG(level_starts),
    2
  ) AS avg_level_starts_per_player_day

FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

GROUP BY platform
ORDER BY players DESC;



-- ============================================================
-- 2. PLATFORM RETENTION
--
-- Cohort attributes are taken from the player's first
-- observed activity day.
-- ============================================================

WITH player_cohorts AS (

  SELECT
    user_pseudo_id,
    MIN(activity_date) AS cohort_date

  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

  GROUP BY user_pseudo_id
),

cohort_platform AS (

  SELECT
    c.user_pseudo_id,
    c.cohort_date,
    ANY_VALUE(p.platform) AS platform

  FROM player_cohorts c

  JOIN `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    ON c.user_pseudo_id = p.user_pseudo_id
   AND c.cohort_date = p.activity_date

  GROUP BY
    c.user_pseudo_id,
    c.cohort_date
),

retention_flags AS (

  SELECT
    c.user_pseudo_id,
    c.cohort_date,
    c.platform,

    MAX(
      CASE
        WHEN p.activity_date =
             DATE_ADD(c.cohort_date, INTERVAL 1 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d1,

    MAX(
      CASE
        WHEN p.activity_date =
             DATE_ADD(c.cohort_date, INTERVAL 7 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d7,

    MAX(
      CASE
        WHEN p.activity_date =
             DATE_ADD(c.cohort_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0
      END
    ) AS retained_d30

  FROM cohort_platform c

  LEFT JOIN `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p
    ON c.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    c.user_pseudo_id,
    c.cohort_date,
    c.platform
)

SELECT
  platform,

  COUNT(*) AS players,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-10-02'
        AND retained_d1 = 1
      ),
      COUNTIF(
        cohort_date <= DATE '2018-10-02'
      )
    ) * 100,
    2
  ) AS d1_retention_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-09-26'
        AND retained_d7 = 1
      ),
      COUNTIF(
        cohort_date <= DATE '2018-09-26'
      )
    ) * 100,
    2
  ) AS d7_retention_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(
        cohort_date <= DATE '2018-09-03'
        AND retained_d30 = 1
      ),
      COUNTIF(
        cohort_date <= DATE '2018-09-03'
      )
    ) * 100,
    2
  ) AS d30_retention_pct

FROM retention_flags

GROUP BY platform
ORDER BY players DESC;



-- ============================================================
-- 3. COUNTRY GROUPS
--
-- We avoid comparing many tiny countries individually.
--
-- Top countries are kept separately and the rest grouped.
-- ============================================================

WITH player_country AS (

  SELECT
    user_pseudo_id,

    ANY_VALUE(country) AS country

  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

  GROUP BY user_pseudo_id
)

SELECT

  CASE
    WHEN country = 'United States' THEN 'United States'
    WHEN country = 'India' THEN 'India'
    WHEN country = 'Japan' THEN 'Japan'
    WHEN country = 'Canada' THEN 'Canada'
    WHEN country = 'United Kingdom' THEN 'United Kingdom'
    WHEN country = 'Australia' THEN 'Australia'
    ELSE 'Other'
  END AS country_group,

  COUNT(*) AS players

FROM player_country

GROUP BY country_group
ORDER BY players DESC;



-- ============================================================
-- 4. COUNTRY GROUP — ACTIVE DAYS
--
-- Business Question:
-- Do major markets show different repeat-usage patterns?
-- ============================================================

WITH player_stats AS (

  SELECT
    user_pseudo_id,
    ANY_VALUE(country) AS country,
    COUNT(*) AS active_days

  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

  GROUP BY user_pseudo_id
),

country_segments AS (

  SELECT
    user_pseudo_id,
    active_days,

    CASE
      WHEN country = 'United States' THEN 'United States'
      WHEN country = 'India' THEN 'India'
      WHEN country = 'Japan' THEN 'Japan'
      WHEN country = 'Canada' THEN 'Canada'
      WHEN country = 'United Kingdom' THEN 'United Kingdom'
      WHEN country = 'Australia' THEN 'Australia'
      ELSE 'Other'
    END AS country_group

  FROM player_stats
)

SELECT
  country_group,

  COUNT(*) AS players,

  ROUND(
    AVG(active_days),
    2
  ) AS avg_active_days,

  APPROX_QUANTILES(active_days, 100)[OFFSET(50)]
    AS median_active_days,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(active_days = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS one_day_player_pct

FROM country_segments

GROUP BY country_group

HAVING players >= 100

ORDER BY players DESC;



-- ============================================================
-- 5. ACQUISITION SOURCE — PLAYER QUALITY
--
-- Business Question:
-- Do acquisition groups generate players with different
-- repeat-usage behavior?
--
-- NOTE:
-- traffic source data is very imbalanced.
-- Results for small groups must be treated cautiously.
-- ============================================================

WITH player_stats AS (

  SELECT
    user_pseudo_id,

    ANY_VALUE(traffic_source) AS traffic_source,

    ANY_VALUE(traffic_medium) AS traffic_medium,

    COUNT(*) AS active_days,

    SUM(session_starts) AS sessions,

    SUM(level_starts) AS level_starts

  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

  GROUP BY user_pseudo_id
)

SELECT
  COALESCE(traffic_source, '(unknown)')
    AS traffic_source,

  COALESCE(traffic_medium, '(unknown)')
    AS traffic_medium,

  COUNT(*) AS players,

  ROUND(
    AVG(active_days),
    2
  ) AS avg_active_days,

  APPROX_QUANTILES(active_days, 100)[OFFSET(50)]
    AS median_active_days,

  ROUND(
    AVG(sessions),
    2
  ) AS avg_sessions,

  ROUND(
    AVG(level_starts),
    2
  ) AS avg_level_starts

FROM player_stats

GROUP BY
  traffic_source,
  traffic_medium

HAVING players >= 50

ORDER BY players DESC;



-- ============================================================
-- 6. ONE-DAY PLAYER PROFILE
--
-- Business Question:
-- Since one-day players are our largest observed group,
-- what proportion of them actually entered gameplay?
-- ============================================================

WITH player_stats AS (

  SELECT
    user_pseudo_id,
    COUNT(*) AS active_days

  FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

  GROUP BY user_pseudo_id
),

gameplay_flags AS (

  SELECT
    user_pseudo_id,

    MAX(
      CASE
        WHEN event_name IN (
          'level_start',
          'level_start_quickplay'
        )
        THEN 1
        ELSE 0
      END
    ) AS started_gameplay,

    MAX(
      CASE
        WHEN event_name IN (
          'level_complete',
          'level_complete_quickplay'
        )
        THEN 1
        ELSE 0
      END
    ) AS completed_gameplay

  FROM `mobile-game-product-analytics.game_analytics.cleaned_events_v`

  GROUP BY user_pseudo_id
)

SELECT
  CASE
    WHEN p.active_days = 1 THEN '1-day player'
    ELSE '2+ day player'
  END AS player_segment,

  COUNT(*) AS players,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(g.started_gameplay = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS gameplay_start_pct,

  ROUND(
    SAFE_DIVIDE(
      COUNTIF(g.completed_gameplay = 1),
      COUNT(*)
    ) * 100,
    2
  ) AS gameplay_complete_pct

FROM player_stats p

LEFT JOIN gameplay_flags g
  ON p.user_pseudo_id = g.user_pseudo_id

GROUP BY player_segment
ORDER BY players DESC;