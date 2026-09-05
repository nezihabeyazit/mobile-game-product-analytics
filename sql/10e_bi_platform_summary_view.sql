CREATE OR REPLACE VIEW
`mobile-game-product-analytics.game_analytics.bi_platform_summary_v`
AS

SELECT
  platform,

  COUNT(DISTINCT user_pseudo_id)
    AS players,

  COUNT(*)
    AS player_days,

  ROUND(
    SAFE_DIVIDE(
      COUNT(*),
      COUNT(DISTINCT user_pseudo_id)
    ),
    2
  ) AS avg_active_days,

  ROUND(
    AVG(session_starts),
    2
  ) AS sessions_per_player_day,

  ROUND(
    AVG(level_starts),
    2
  ) AS level_starts_per_player_day

FROM
  `mobile-game-product-analytics.game_analytics.player_daily_activity_v`

GROUP BY platform;