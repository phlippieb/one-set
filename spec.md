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
SwiftUI
SwiftData
iCloud sync

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
  - Last logged reps+weight+date
  - Max logged reps+weight+date
- Secondary button to view full workout log
- Primary button to log a new workout; text changes depending on whether already logged today ("Log new"/"Log another"; button style changes to secondary)
  - Logging again is supported so that back-logging is possible. No validation is required to prevent duplicate logs per date.

Note: Cycles are strictly date-based, regardless of skipped days. They run exactly every 2 days. The cycles are hardcoded: Bicep focus started on Monday Sep 21; the order is Biceps -> Triceps -> Shoulders.

#### Logged workouts

Simple list view; each row shows
- Date
- Forms logged with reps+weight
- Notes

Tapping a row navigates to the Add/Edit workout entry view.

#### Add/Edit workout entry

A form view with two modes: add or edit.

Editable fields:
- Date
  - Defaults to today in add mode; displays stored date in edit mode
  - Can be changed to any date with a calendar picker
- A form item per target group
  - Each form row has:
    - The form name (e.g. Bicep Curls)
      - In add mode, the forms are automatically pre-selected based on the plan. Auto-selection is based on the previous one that was logged, not the date.
      - The form can be changed to another one from the target group by tapping on the form name, which brings up a selection picker.
    - Weight
      - Hardcoded to kg
      - +/- buttons, increment by 0.5kg
      - In Add mode, pre-fill with the last recorded weight
    - Reps
      - +/- buttons, increment by 1
      - In Add mode, pre-fill with the last recorded reps
    - "Skipped" toggle
        - When toggled, this form is not logged as part of the workout, so its weight/reps do not show up as the last one
    - "Repeat" toggle, for when a form felt too hard to progress next time
    - In Add mode: hint/footer text recommending today's target based on previous entries for this form.
      - If previous entry for this form has "repeat" toggled, the recommended target is the same as the previous entry
      - Else if the previous entry for this form's reps are at this form's ceiling, the recommended target bumps weight to the next hardcoded value and drops reps to this form's floor
      - Else, the recommended target keeps weight the same and increments reps by one
  - The forms are sequenced according to the current phase in the focus cycle. The focus group's form is first, and the other forms follow in their usual order in the cycle.
  - All forms are editable (to reflect what I actually did).
- In Add mode: "Add" button. In Edit mode: "Save" button.

### Look and feel

Use vanilla SwiftUI components.
