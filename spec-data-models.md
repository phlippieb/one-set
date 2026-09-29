# Data Models

This document defines the persisted and non-persisted data used by One Set. It supplements `spec.md`.

## Principles

- Persist only completed workout data entered by the user.
- Keep the hardcoded workout plan in application code rather than duplicating it in the database.
- Compute cycle status, history summaries, and recommendations from persisted workouts.
- Treat workout dates as calendar days, not moments in time.

## Persisted Models

### Workout

A `Workout` represents the workout logged for one calendar day.

Fields:

- `dayKey: String`
  - The workout's calendar date in zero-padded ISO format: `YYYY-MM-DD`.
  - Example: `2026-09-21`.
  - Uses the Gregorian calendar.
  - Generated from the device's local date and current time zone when the workout is added.
  - Immutable after creation.
  - Unique across workouts.
- `notes: String`
  - Free-form notes.
  - May be empty.
- `performedSets: [PerformedSet]`
  - The sets performed in this workout.
  - Collection order has no persisted meaning; presentation order is computed.
  - Deleting the workout cascade-deletes these sets.

Invariants:

- `dayKey` must identify a valid Gregorian calendar date and use the exact `YYYY-MM-DD` representation.
- There may be at most one workout for a given `dayKey`.
- A workout must have at least one performed set and at most three.
- A workout may have at most one performed set for each target group.
- New workouts can only use today's local day key.

### PerformedSet

A `PerformedSet` represents one target group's completed set within a workout.

Fields:

- `workout: Workout`
  - The owning workout.
  - Every performed set must belong to exactly one workout.
- `formID: String`
  - A stable identifier for the performed exercise form.
  - The application exposes this as a typed `ExerciseForm` value rather than passing arbitrary strings through domain logic.
- `weightKg: Int`
  - The performed weight in kilograms.
- `reps: Int`
  - The number of completed repetitions.
- `shouldRepeat: Bool`
  - Whether the same weight and repetition count should be recommended the next time this form is performed during its focus cycle.

Stable form identifiers:

- `biceps.curls`
- `biceps.hammer-curls`
- `triceps.overhead-extensions`
- `triceps.skull-crushers`
- `shoulders.shoulder-presses`
- `shoulders.lateral-raises`

Invariants:

- `formID` must be one of the known hardcoded form identifiers.
- `weightKg` must be one of the hardcoded available weights: `7`, `10`, `12`, or `15`.
- `reps` must be at least `1`. Rep-range floors and ceilings do not restrict logged values.

## Date Semantics

An ISO day key is stored instead of a Foundation `Date` because a workout belongs to a civil calendar day rather than an absolute instant.

- Changing the device's time zone must not change a saved workout's date.
- Today's key is generated using the device's current local date when a workout is added.
- Saved day keys are interpreted as Gregorian dates for display and date arithmetic.
- Dates are localized for display after converting the key to date components.
- Fixed-width ISO keys sort chronologically, so they can be used directly for newest-first ordering and before/after comparisons.
- Day differences for focus-cycle calculations are calendar-day differences, not elapsed 24-hour periods. This avoids daylight-saving-time errors.

The focus-cycle epoch is likewise the date-only value `2026-09-21`. It is not stored as an absolute timestamp.

## Hardcoded Domain Values

The following values are defined in application code and are not SwiftData models:

- `MuscleGroup`
- `ExerciseForm`, including its stable ID, display name, muscle group, rep floor, and rep ceiling
- Available weights
- Form order within each muscle group
- Focus-cycle order
- Focus-cycle duration
- Focus-cycle epoch

A target group is derived from `PerformedSet.formID`; it is not stored separately.

## Representing Skips

Only performed sets are persisted. If a workout has no performed set for a target group, that group was skipped.

There are no persisted skip flags or placeholder set records. A workout in which all three groups were skipped is invalid and cannot be saved.

## Computed State

The following values are derived from workout history and are not persisted:

- The focus cycle for any calendar day, including past workout days, today, and future days
- Focus-cycle progress
- Presentation order of sets
- Last performed form for a target group
- Next form in a target group's alternation
- Last performance for a form
- Maximum performance for a form
- Max badges in the workout log
- Prefilled values for a new set
- Recommended values for a new set
- Whether a target group was skipped

Maximum performance is compared first by weight and then by reps at that weight. When displaying one historical entry for a tied maximum, use the most recent. Every workout-log entry matching the maximum weight and reps receives a Max badge.

## Deliberately Omitted Fields and Models

The MVP does not persist:

- Separate IDs generated by the application; SwiftData supplies model identity.
- Creation or update timestamps.
- Exercise-form or muscle-group records.
- Focus-cycle records.
- Recommendation records.
- Derived last or maximum values.

These can be introduced later only if a concrete product requirement needs them.
