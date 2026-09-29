import Models
import SwiftData
import SwiftUI

struct WorkoutEntryView: View {
  @Query(sort: \Workout.dayKey, order: .reverse) private var workouts: [Workout]

  let workout: Workout?
  @State private var exercises: [ExerciseState]
  @State private var didInitializeAddMode: Bool
  @State private var notes: String

  init(workout: Workout? = nil) {
    self.workout = workout
    let dayKey = workout?.dayKey ?? WorkoutDayKey.today()
    guard let muscleGroups = WorkoutPlan.muscleGroupOrder(on: dayKey) else {
      preconditionFailure("A workout must have a valid day key")
    }
    self._exercises = State(
      initialValue: muscleGroups.map { muscleGroup in
        if let performedSet = workout?.performedSet(for: muscleGroup) {
          return ExerciseState(
            muscleGroup: muscleGroup,
            form: performedSet.form,
            weightKg: performedSet.weightKg,
            reps: performedSet.reps,
            shouldRepeat: performedSet.shouldRepeat,
            isSkipped: false,
            hasInitializedValues: true
          )
        }

        let form = muscleGroup.forms[0]
        return ExerciseState(
          muscleGroup: muscleGroup,
          form: form,
          weightKg: WorkoutPlan.availableWeightsKg[0],
          reps: form.repFloor,
          shouldRepeat: false,
          isSkipped: workout != nil,
          hasInitializedValues: workout == nil
        )
      }
    )
    self._didInitializeAddMode = State(initialValue: workout != nil)
    self._notes = State(initialValue: workout?.notes ?? "")
  }

  var body: some View {
    Form {
      Section("Exercises") {
        ForEach(exercises.indices, id: \.self) { index in
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text(exercises[index].muscleGroup.displayName)
                .font(.headline)
              Spacer()
              Toggle("Skipped", isOn: skippedBinding(at: index))
                .fixedSize()
            }

            if !exercises[index].isSkipped {
              Picker("Form", selection: formBinding(at: index)) {
                ForEach(exercises[index].muscleGroup.forms) { form in
                  Text(form.displayName).tag(form)
                }
              }

              LabeledContent("Weight") {
                HStack(spacing: 12) {
                  Button {
                    adjustWeight(at: index, by: -1)
                  } label: {
                    Image(systemName: "minus")
                  }
                  .buttonStyle(.bordered)
                  .disabled(!canAdjustWeight(at: index, by: -1))
                  .accessibilityLabel("Decrease weight")

                  Text("\(exercises[index].weightKg) kg")
                    .monospacedDigit()
                    .frame(minWidth: 44)

                  Button {
                    adjustWeight(at: index, by: 1)
                  } label: {
                    Image(systemName: "plus")
                  }
                  .buttonStyle(.bordered)
                  .disabled(!canAdjustWeight(at: index, by: 1))
                  .accessibilityLabel("Increase weight")
                }
              }

              Stepper(
                "Reps: \(exercises[index].reps)",
                value: $exercises[index].reps,
                in: 1...Int.max
              )

              Toggle("Repeat", isOn: $exercises[index].shouldRepeat)

              if workout == nil {
                let recommendation = history.recommendation(
                  for: exercises[index].form,
                  on: dayKey
                )
                LabeledContent(
                  "Target",
                  value: "\(recommendation.reps) x \(recommendation.weightKg) kg"
                )
                .foregroundStyle(.secondary)
              }
            }
          }
          .padding(.vertical, 4)
        }
      }

      Section("Notes") {
        TextEditor(text: $notes)
          .frame(minHeight: 120)
          .accessibilityLabel("Notes")
      }
    }
    .navigationTitle(
      workout.map { WorkoutDateDisplay.relative($0.dayKey) } ?? "Log Workout"
    )
    .task {
      guard !didInitializeAddMode else { return }
      for index in exercises.indices {
        let muscleGroup = exercises[index].muscleGroup
        let form = history.nextForm(for: muscleGroup)
        let values = history.prefill(for: form)
        exercises[index].form = form
        exercises[index].weightKg = values.weightKg
        exercises[index].reps = values.reps
      }
      didInitializeAddMode = true
    }
  }

  private var dayKey: String {
    workout?.dayKey ?? WorkoutDayKey.today()
  }

  private var history: WorkoutHistory {
    WorkoutHistory(workouts: workouts)
  }

  private func skippedBinding(at index: Int) -> Binding<Bool> {
    Binding {
      exercises[index].isSkipped
    } set: { isSkipped in
      exercises[index].isSkipped = isSkipped
      guard !isSkipped, !exercises[index].hasInitializedValues else { return }

      let muscleGroup = exercises[index].muscleGroup
      let form = history.nextForm(for: muscleGroup, before: dayKey)
      let values = history.prefill(for: form, before: dayKey)
      exercises[index].form = form
      exercises[index].weightKg = values.weightKg
      exercises[index].reps = values.reps
      exercises[index].shouldRepeat = false
      exercises[index].hasInitializedValues = true
    }
  }

  private func formBinding(at index: Int) -> Binding<ExerciseForm> {
    Binding {
      exercises[index].form
    } set: { form in
      exercises[index].form = form
      guard workout == nil else { return }

      let values = history.prefill(for: form)
      exercises[index].weightKg = values.weightKg
      exercises[index].reps = values.reps
    }
  }

  private func canAdjustWeight(at index: Int, by offset: Int) -> Bool {
    guard let weightIndex = WorkoutPlan.availableWeightsKg.firstIndex(
      of: exercises[index].weightKg
    ) else {
      return false
    }
    return WorkoutPlan.availableWeightsKg.indices.contains(weightIndex + offset)
  }

  private func adjustWeight(at index: Int, by offset: Int) {
    guard let weightIndex = WorkoutPlan.availableWeightsKg.firstIndex(
      of: exercises[index].weightKg
    ) else {
      return
    }
    let nextIndex = weightIndex + offset
    guard WorkoutPlan.availableWeightsKg.indices.contains(nextIndex) else {
      return
    }
    exercises[index].weightKg = WorkoutPlan.availableWeightsKg[nextIndex]
  }
}

private struct ExerciseState {
  let muscleGroup: MuscleGroup
  var form: ExerciseForm
  var weightKg: Int
  var reps: Int
  var shouldRepeat: Bool
  var isSkipped: Bool
  var hasInitializedValues: Bool
}
