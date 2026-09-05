SELECT
  COUNT(*) AS player_day_rows,
  COUNT(DISTINCT user_pseudo_id) AS unique_players,
  MIN(activity_date) AS first_date,
  MAX(activity_date) AS last_date,
  SUM(event_count) AS reconstructed_events
FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`;