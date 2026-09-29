import Models
import SwiftData
import SwiftUI

struct WorkoutEntryView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Workout.dayKey, order: .reverse) private var workouts: [Workout]

  let workout: Workout?
  @State private var exercises: [ExerciseState]
  @State private var didInitializeAddMode: Bool
  @State private var errorMessage: String?
  @State private var isShowingDeleteConfirmation = false
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
          WorkoutExerciseRow(
            exercise: $exercises[index],
            history: history,
            dayKey: dayKey,
            isAddMode: workout == nil
          )
        }
      }

      Section("Notes") {
        TextEditor(text: $notes)
          .frame(minHeight: 120)
          .accessibilityLabel("Notes")
      }

      if workout != nil {
        Section {
          Button("Delete", role: .destructive) {
            isShowingDeleteConfirmation = true
          }
        }
      }
    }
    .navigationTitle(
      workout.map { WorkoutDateDisplay.relative($0.dayKey) } ?? "Log Workout"
    )
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(workout == nil ? "Add" : "Save", action: saveWorkout)
          .disabled(!didInitializeAddMode || exercises.allSatisfy(\.isSkipped))
      }
    }
    .confirmationDialog(
      "Delete Workout?",
      isPresented: $isShowingDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete Workout", role: .destructive, action: deleteWorkout)
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This cannot be undone.")
    }
    .alert("Unable to Complete Action", isPresented: isShowingError) {
      Button("OK") {
        errorMessage = nil
      }
    } message: {
      Text(errorMessage ?? "Please try again.")
    }
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

  private var isShowingError: Binding<Bool> {
    Binding {
      errorMessage != nil
    } set: { isShowing in
      if !isShowing {
        errorMessage = nil
      }
    }
  }

  private func saveWorkout() {
    do {
      let performedSets = try exercises.compactMap { exercise -> PerformedSetInput? in
        guard !exercise.isSkipped else { return nil }
        return try PerformedSetInput(
          form: exercise.form,
          weightKg: exercise.weightKg,
          reps: exercise.reps,
          shouldRepeat: exercise.shouldRepeat
        )
      }

      if let workout {
        try workout.update(
          notes: notes,
          performedSets: performedSets,
          in: modelContext
        )
      } else {
        modelContext.insert(
          try Workout(notes: notes, performedSets: performedSets)
        )
      }
      try modelContext.save()
      dismiss()
    } catch {
      modelContext.rollback()
      errorMessage = error.localizedDescription
    }
  }

  private func deleteWorkout() {
    guard let workout else { return }
    modelContext.delete(workout)
    do {
      try modelContext.save()
      dismiss()
    } catch {
      modelContext.rollback()
      errorMessage = error.localizedDescription
    }
  }

}

private struct WorkoutExerciseRow: View {
  @Binding var exercise: ExerciseState
  let history: WorkoutHistory
  let dayKey: String
  let isAddMode: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(exercise.muscleGroup.displayName)
          .font(.headline)
        Spacer()
        Toggle("Skipped", isOn: skippedBinding)
          .fixedSize()
      }

      if !exercise.isSkipped {
        Picker("Form", selection: formBinding) {
          ForEach(exercise.muscleGroup.forms) { form in
            Text(form.displayName).tag(form)
          }
        }

        LabeledContent("Weight") {
          HStack(spacing: 12) {
            Button {
              adjustWeight(by: -1)
            } label: {
              Image(systemName: "minus")
            }
            .buttonStyle(.bordered)
            .disabled(!canAdjustWeight(by: -1))
            .accessibilityLabel("Decrease weight")

            Text("\(exercise.weightKg) kg")
              .monospacedDigit()
              .frame(minWidth: 44)

            Button {
              adjustWeight(by: 1)
            } label: {
              Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .disabled(!canAdjustWeight(by: 1))
            .accessibilityLabel("Increase weight")
          }
        }

        Stepper(
          "Reps: \(exercise.reps)",
          value: $exercise.reps,
          in: 1...Int.max
        )

        Toggle("Repeat", isOn: $exercise.shouldRepeat)

        if isAddMode {
          let recommendation = history.recommendation(for: exercise.form, on: dayKey)
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

  private var skippedBinding: Binding<Bool> {
    Binding {
      exercise.isSkipped
    } set: { isSkipped in
      exercise.isSkipped = isSkipped
      guard !isSkipped, !exercise.hasInitializedValues else { return }

      let muscleGroup = exercise.muscleGroup
      let form = history.nextForm(for: muscleGroup, before: dayKey)
      let values = history.prefill(for: form, before: dayKey)
      exercise.form = form
      exercise.weightKg = values.weightKg
      exercise.reps = values.reps
      exercise.shouldRepeat = false
      exercise.hasInitializedValues = true
    }
  }

  private var formBinding: Binding<ExerciseForm> {
    Binding {
      exercise.form
    } set: { form in
      exercise.form = form
      guard isAddMode else { return }

      let values = history.prefill(for: form)
      exercise.weightKg = values.weightKg
      exercise.reps = values.reps
    }
  }

  private func canAdjustWeight(by offset: Int) -> Bool {
    guard let weightIndex = WorkoutPlan.availableWeightsKg.firstIndex(
      of: exercise.weightKg
    ) else {
      return false
    }
    return WorkoutPlan.availableWeightsKg.indices.contains(weightIndex + offset)
  }

  private func adjustWeight(by offset: Int) {
    guard let weightIndex = WorkoutPlan.availableWeightsKg.firstIndex(
      of: exercise.weightKg
    ) else {
      return
    }
    let nextIndex = weightIndex + offset
    guard WorkoutPlan.availableWeightsKg.indices.contains(nextIndex) else {
      return
    }
    exercise.weightKg = WorkoutPlan.availableWeightsKg[nextIndex]
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
