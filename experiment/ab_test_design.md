# A/B Test Design

## Status

**SIMULATED / PROPOSED EXPERIMENT**

No production experiment was conducted.

## Hypothesis

A lightweight guided first-session activation flow will increase D1 retention by helping new players reach successful core gameplay earlier.

## Audience

Eligible new players.

For the historical analysis, first-observed activity was used as a proxy where necessary. A real production experiment should use genuinely new users.

## Randomization

- Unit: player
- Split: 50% Control / 50% Treatment
- Assignment should remain consistent across sessions.

## Control

Existing first-session experience.

## Treatment

Guided first-session activation flow.

## Primary Metric

D1 retention.

## Activation Metric

First-session gameplay completion rate.

## Secondary Metrics

- Gameplay start rate
- D7 retention
- Sessions per player
- Time to first gameplay start
- Time to first gameplay completion

## Guardrails

- Crash / error rate
- Session abandonment
- Abnormal failure / retry increases
- Monetization regressions

## Sample Size Planning

Historical D1 baseline: 15.8%

Candidate minimum detectable effect:

15.8% → 17.3%

Absolute uplift target:

+1.5 percentage points

Planning assumptions:

- Alpha: 0.05
- Power: 0.80
- Two-sided test
- Required sample size: 9,632 users per group
- Required total sample: 19,264 users

## Simulated Result

Control D1:

15.80%

Treatment D1:

17.50%

Absolute uplift:

+1.70 percentage points

Relative uplift:

+10.76%

p-value:

0.0013

95% confidence interval:

+0.67 pp to +2.73 pp

## Decision

**Iterate**

The simulated result is statistically significant and the point estimate exceeds the predefined practical threshold.

However, the confidence interval still includes effects below the +1.5 percentage-point practical threshold.

I would therefore iterate on the treatment and validate further before recommending full rollout.
