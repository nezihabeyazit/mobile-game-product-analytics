# Power BI Report

This folder contains the Power BI report file for the project:

`mobile_game_product_analytics.pbix`

## Dashboard Pages

The report contains four pages:

1. Product Overview
2. Retention & Activation
3. Gameplay & Funnel
4. Segments & Monetization

## Data Source

The report uses aggregated BigQuery views created from the Google Flood It! Firebase/GA public dataset.

The full raw 5.7M-event dataset was not imported directly into Power BI. Aggregations were performed in BigQuery first, and Power BI was used as the visualization and decision-support layer.

## Validation

Key Power BI metrics were cross-checked against BigQuery outputs, including:

- DAU and sessions per player
- D1 / D7 / D30 retention
- Activation metrics
- Level 27 and Level 29 funnel metrics
- Payer conversion and purchase mix

Dashboard screenshots are available in the `dashboard/` folder.
