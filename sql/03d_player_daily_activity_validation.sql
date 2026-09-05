SELECT
  user_pseudo_id,
  activity_date,
  COUNT(*) AS occurrences
FROM `mobile-game-product-analytics.game_analytics.player_daily_activity_v`
GROUP BY user_pseudo_id, activity_date
HAVING COUNT(*) > 1;