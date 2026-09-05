CREATE OR REPLACE VIEW
`mobile-game-product-analytics.game_analytics.bi_monetization_v`
AS

SELECT
  (
    SELECT ep.value.string_value
    FROM UNNEST(event_params) ep
    WHERE ep.key = 'product_id'
  ) AS product_id,

  COUNT(*) AS purchases,

  COUNT(DISTINCT user_pseudo_id)
    AS payers

FROM
  `firebase-public-project.analytics_153293282.events_*`

WHERE event_name = 'in_app_purchase'

  AND _TABLE_SUFFIX
      BETWEEN '20180612'
      AND '20181003'

GROUP BY product_id;