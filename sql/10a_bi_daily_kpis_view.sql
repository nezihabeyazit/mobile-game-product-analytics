CREATE OR REPLACE VIEW
`mobile-game-product-analytics.game_analytics.bi_daily_kpis_v`
AS

WITH first_activity AS (

  SELECT
    user_pseudo_id,
    MIN(activity_date) AS first_activity_date

  FROM
    `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

  GROUP BY user_pseudo_id
),

daily AS (

  SELECT
    p.activity_date,

    COUNT(DISTINCT p.user_pseudo_id) AS dau,

    SUM(p.session_starts) AS sessions,

    SUM(p.level_starts) AS level_starts,

    SUM(p.level_completes) AS level_completes,

    COUNTIF(
      p.activity_date = f.first_activity_date
    ) AS first_observed_players,

    COUNTIF(
      p.activity_date > f.first_activity_date
    ) AS returning_players

  FROM
    `mobile-game-product-analytics.game_analytics.player_daily_activity_v` p

  JOIN first_activity f
    ON p.user_pseudo_id = f.user_pseudo_id

  GROUP BY p.activity_date
)

SELECT
  activity_date,
  dau,
  sessions,
  level_starts,
  level_completes,
  first_observed_players,
  returning_players,

  ROUND(
    SAFE_DIVIDE(sessions, dau),
    2
  ) AS sessions_per_player

FROM daily;