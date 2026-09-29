# Implementation plan

## Initial spec and setup

- [x] Define spec for MVP for dogfooding
- [x] Install dev tools
- [x] Add repo on github
- [x] Create blank Xcode project
- [x] Fix app target to only iOS

## Models

- [x] Define (in spec) data models
- [x] Create Models Swift package
- [x] Implement persisted models
- [x] Implement computed model logic and mappings
- [x] Unit-test models
- [x] Integrate Models package in app project

## App Home

- [x] Seed app with dummy data
- [x] Render Home focus status cycle
- [x] Render Home form cards
- [x] Render Home action cards and scaffold destinations

## Workout log

- [x] Render basic Workout Log rows
- [x] Group list by cycle, e.g. "Biceps focus (start date - end date)" - similar to the home screen
- [x] Render remaining data in rows
- [x] Wire up tapping on row -> navigate to WorkoutEntryView

## Workout detail

- [x] Render workout date as title using human-friendly format
- [x] Render basic exercises lists - title and skipped toggle
- [x] Render exercises with edit controls
- [x] Add notes box
- [ ] Add delete and save buttons
- [ ] Implement delete and save functionality
- [ ] Tweak UI
