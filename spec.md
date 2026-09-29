# One Set

## Context

I struggle to stick to workout plans when they get too big or when tracking becomes too complex. I came up with a workout plan that I think will balance ease of adherence with acceptable progress. In this repo, I want to build an iOS app that guides me on what exactly to do on a given day, and for tracking my progress. We'll start by hardcoding my exact plan so I can dogfood it. Later, we may expand it for more general use and publish it, but we should not make any affordances for that yet.

## The workout plan

The workout is done every day, and we aim to see progress in terms of reps or weights every day.

Choose a small number of muscle groups to target -- mine are biceps, triceps, and shoulders.

Exercise every group every day.

Every day means we have room to alternate the specific exercise targeting each group. Alternating is also a good idea to mitigate risk of injury. So for each target group, we have 2 Forms:
- Biceps: Curls, Hammer curls
- Triceps: Overhead extensions, Skull crushers
- Shoulders: Shoulder presses, Lateral raises

Alternate these every day; e.g.
- Monday: Curls, Overhead extensions, Shoulder presses
- Tuesday: Hammer curls, Skull crushers, Lateral raises

Do one set of each (plus warmup if needed - not logged or part of the app, outside of perhaps some hint text).

The plan goes through broad Focus Cycles. During a given cycle, the focus is on progressive overload in only one target group. The other groups are also done, but not advanced. Each form in the focused group progresses independently.

Increase reps until a preferred ceiling, then raise the weight and drop down to a preferred floor. Progress by just one rep. Only progress if the last time doing this form felt under control.

Setbacks happen, so if you for example managed 10x Curls last time, but only manage 7x today, progress resets to 7x, making it easy to build up to 10x again. Your max of 10x is still recorded.

While one group is in progression mode, the others are in maintenance mode. You still do those every day (one set per group, alternating forms, as before), but you just keep doing the same reps+weights as your last workout.

The hope is that this produces daily workout plans that feel very doable: one focus set where you push just a little + 2 maintenance sets that are aleady within your range. The mainteance sets also ensure you don't lose your momentum until you focus on those groups again, and may even increase your strength so the next focus cycle starts off a little easier.

For now, focus cycles are 2 weeks long -- enough to see real progress, but short enough that each group gets focus in < 2 months.

## The app

Purely hardcoded to my exact plan. Priority is rapid development so that I can start testing, to discover real desired improvements.

### Stack

Native Swift app
Target min iOS version: 26
Target iPhone only
SwiftUI
SwiftData

### Layout

It consists of the following views:
- Home
- Logged workouts
- Add/Edit workout entry

#### Home

- Current focus cycle status
  - Focused group name (Biceps, Triceps or Shoulders + "Focus")
  - Cycle progress
    - This is a segmented progress bar with a segment (circle) for each day in the cycle
    - Each previous day with a logged entry is filled
    - Each previous day without a logged entry has a diagonal strikethrough
    - Today is tinted, and empty or filled depending on whether an entry is logged yet
    - Upcoming days are empty
  - Next focus cycle name + start date
- Cards for each form
  - Form name
  - If this form has never been logged (unskipped): "No workouts yet"
  - Else
    - Last logged reps+weight+date
    - Max logged reps+weight+date
- Secondary button to view full workout log
- Primary button to log a new workout to today only
  - If a workout is already logged today, the button becomes disabled and the text changes to "Today's workout is logged"

Note: Cycles are strictly date-based, regardless of skipped days. They run exactly every 2 weeks. The cycles are hardcoded: Bicep focus started on Monday 21st Sep 2026 in device local timezone; the order is Biceps -> Triceps -> Shoulders.

#### Logged workouts

Simple list view; each row shows
- Date
- Forms logged with reps+weight
  - "Max" badge if this weight+rep is the max -- true for all entries where this is true, if there are multiple
- Notes

Newest first.

Tapping a row navigates to the Add/Edit workout entry view.

#### Add/Edit workout entry

A form view with two modes: add or edit.

UI elements:
- Date
  - Read-only
  - Format: "Monday 21 September 2026"
  - Defaults to today in add mode; displays stored date in edit mode
- List view showing one form item row per target group
  - Each form row has:
    - The form name (e.g. Bicep Curls)
      - In add mode, the forms are automatically pre-selected based on the plan. Auto-selection is based on the previous one that was logged, not the date.
      - The form can be changed to another one from the target group by tapping on the form name, which brings up a selection picker.
        - Selecting a different form in Add mode will immediately re-populate the pre-filled weight and rep values and update the target recommendation text
        - Selecting a different form in Edit mode does not change the weight and rep values (and no target recommendation text is shown, so no update needed)
    - Weight
      - Hardcoded to kg
      - +/- buttons, jump between hardcoded weights
      - In Add mode, pre-fill with the last recorded weight
    - Reps
      - +/- buttons, increment by 1
      - In Add mode, pre-fill with the last recorded reps
    - "Skipped" toggle
        - When toggled, this form is not logged as part of the workout, so its weight/reps do not show up as the last one
    - "Repeat" toggle, for when a form felt too hard to progress next time
      - Always pre-populated to false in Add mode
    - In Add mode: hint/footer text recommending today's target based on previous entries for this form.
      - If form is in maintenance mode, recommend the previous entry's values.
      - Else if previous entry for this form has "repeat" toggled, the recommended target is the same as the previous entry
      - Else if the previous entry for this form's reps are at or over this form's ceiling, the recommended target bumps weight to the next hardcoded value and drops reps to this form's floor
        - If the highest hardcoded weight and rep ceiling are reached, recommend the same values
      - Else, the recommended target keeps weight the same and increments reps by one
  - The forms are sequenced according to the workout's phase in the focus cycle (according to the workout's date). The focus group's form is first, and the other forms follow in their usual order in the cycle (i.e. Biceps->Triceps->Shoulders->back to start).
  - All forms are editable (to reflect what I actually did).
- Notes -- a free text box for storing notes about this day's workout.
- In Add mode: "Add" button. In Edit mode: "Save" button.

### Look and feel

Use vanilla SwiftUI components.

## Hard-coded values

Focus cycle order: Biceps, Triceps, Shoulders
Focus cycle epoch: Monday 21st Sep 2026 in device local timezone

Forms per target group -- this also defines form sequencing with no (unskipped) history:
- Biceps: Curls, Hammer curls
- Triceps: Overhead extensions, Skull crushers
- Shoulders: Shoulder presses, Lateral raises

Per-form rep ranges:
- Curls: 6-12
- Hammer curls: 6-12
- Overhead extensions: 8-15
- Skull crushers: 8-15
- Shoulder presses: 6-12
- Lateral raises: 6-20

Weights (what i have at home) in kg: 7, 10, 12, 15

Initial values and recommended values for forms with no entries logged yet: Lowest weight, lowest rep for that form.

## Logic clarification

- (Updated for simplicity) Workout dates are not editable. New dates are always added to today. Only one workout can be added today.
- Displaying a form's max from history: Max should be understood in terms of linear progression. The max is firstly the maximum weight logged, and secondly the max reps logged at that weight.
- Workouts are not deletable.
- Effect of marking a form as skipped:
  - The skipped form should be persisted with all its rep/weight values. If I skipped a form yesterday and view that day's workout from the log today, the workout should still contain the form with "skipped" toggled.
  - If a form was skipped, it should affect the form alternation when adding a new entry today. Today's form should be preselected based on the last un-skipped form logged.
- Repeat on skipped rows: repeat has no effect if a row is skipped, so it should be disabled and ignored.
- Editing an old workout -- effect on subsequent stored entries:
  - Suggestions are only shown when adding today's workout. Today's suggestions should always be based on the most recent data.
  - Other existing entries are not updated.
- Prefill vs recommendation:
  - Prefill = last value; user needs to manually update.
- Allowed reps: rep floors and ceilings are not hard limits; user can go below or above when logging an entry. Min reps value is 1 (for setbacks). (Less would be equivalent to skip.)
- If all 3 forms are marked as skipped, a workout cannot be saved in Add or Edit mode.
- Skipped forms in entry log view: Display as skipped, omit weight/rep.
- Maximum ties: select most recent.
- Date across timezones: choose the simplest implementation.

Bundle ID to be decided when the Xcode project is created.
