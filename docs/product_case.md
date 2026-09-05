# Product Opportunity & Recommendation

## Problem

Early-player retention is weak, and one-day players are much less likely to enter and complete core gameplay than players who return on multiple days.

## Evidence

- D1 retention: 15.8%
- D7 retention: 7.4%
- D30 retention: 2.89%
- 51.77% of observed players were active on only one day.
- One-day players:
  - Gameplay start: 67.58%
  - Gameplay complete: 35.23%
- 2+ day players:
  - Gameplay start: 93.07%
  - Gameplay complete: 75.12%

## Product Opportunity

Improve early-player activation and help players reach a successful core gameplay experience during their first session.

## Proposed Solution

A lightweight Guided First-Session Activation Flow that may include:

- Clearer direction toward core gameplay
- Contextual first-gameplay guidance
- One-time help after an early failure
- Clear progress feedback after first completion
- A lightweight replay / continue CTA

## User Story

As a new player, I want to understand the core gameplay quickly and complete my first meaningful game with minimal friction so that I feel progress and have a reason to return.

## Why This Was Prioritized

Levels 27 and 29 showed strong progression friction, but they affect a smaller and already more engaged subset of players.

Early activation affects a much larger share of the player base and is more closely aligned with the observed retention problem.

## Success Metrics

Primary:
- D1 retention

Activation:
- First-session gameplay completion rate

Secondary:
- Gameplay start rate
- D7 retention
- Sessions per player
- Time to first gameplay completion

Guardrails:
- Crash / error rate
- Session abandonment
- Abnormal retry / failure increases
- Monetization regression
