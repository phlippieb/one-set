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
      ForEach(exercises.indices, id: \.self) { index in
        Section {
          WorkoutExerciseRow(
            exercise: $exercises[index],
            history: history,
            dayKey: dayKey,
            isAddMode: workout == nil,
            isFocused: index == exercises.startIndex
          )
        } header: {
          if index == exercises.startIndex {
            Text("Exercises")
          }
        }
      }

      Section("Notes") {
        TextEditor(text: $notes)
          .frame(minHeight: 120)
          .accessibilityLabel("Notes")
      }

    }
    .navigationTitle(
      workout.map { WorkoutDateDisplay.relative($0.dayKey) } ?? "Today"
    )
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
      ToolbarItemGroup(placement: .confirmationAction) {
        if workout != nil {
          Menu {
            Button(role: .destructive) {
              isShowingDeleteConfirmation = true
            } label: {
              Label("Delete Workout", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis")
          }
          .accessibilityLabel("More actions")
        }

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
  private static let fieldRowMinHeight: CGFloat = 32

  @Binding var exercise: ExerciseState
  let history: WorkoutHistory
  let dayKey: String
  let isAddMode: Bool
  let isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(exercise.muscleGroup.displayName)
          .font(.headline)
        if isFocused {
          Text("Focus")
            .font(.caption2.bold())
            .foregroundStyle(.tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.tint.opacity(0.12), in: Capsule())
        }
        Spacer()
        CircleToggle(title: "Skipped", isOn: skippedBinding)
          .fixedSize()
      }
      .frame(minHeight: Self.fieldRowMinHeight)
      Spacer(minLength: 12)

      if exercise.isSkipped {
        Text(
          isAddMode
            ? "No set will be recorded for this muscle group."
            : "No set is recorded for this muscle group."
        )
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(minHeight: Self.fieldRowMinHeight)
      } else {
        Picker("Exercise", selection: formBinding) {
          ForEach(exercise.muscleGroup.forms) { form in
            Text(form.displayName).tag(form)
          }
        }
        .frame(minHeight: Self.fieldRowMinHeight)

        if isAddMode && isFocused {
          let recommendation = history.recommendation(for: exercise.form, on: dayKey)
          LabeledContent("Target") {
            Text("\(recommendation.reps) x \(recommendation.weightKg) kg")
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
          .frame(minHeight: Self.fieldRowMinHeight)
        }

        LabeledContent("Weight") {
          HStack(spacing: 8) {
            Text("\(exercise.weightKg) kg")
              .monospacedDigit()
              .frame(minWidth: 44, alignment: .trailing)

            Stepper(
              "Weight",
              value: weightIndexBinding,
              in: weightIndexBounds
            )
            .labelsHidden()
          }
        }
        .frame(minHeight: Self.fieldRowMinHeight)

        LabeledContent("Reps") {
          HStack(spacing: 8) {
            Text("\(exercise.reps)")
              .monospacedDigit()
              .frame(minWidth: 44, alignment: .trailing)

            Stepper(
              "Reps",
              value: $exercise.reps,
              in: 1...Int.max
            )
            .labelsHidden()
          }
        }
        .frame(minHeight: Self.fieldRowMinHeight)

        if shouldShowProgressControl {
          LabeledContent("Progress on next workout") {
            CircleToggle(
              title: exercise.shouldRepeat ? "No" : "Yes",
              isOn: shouldProgressBinding
            )
          }
          .frame(minHeight: Self.fieldRowMinHeight)

          if exercise.shouldRepeat {
            Text("Recommend the same weight and reps next time.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
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

  private var weightIndexBinding: Binding<Int> {
    Binding {
      guard let index = WorkoutPlan.availableWeightsKg.firstIndex(
        of: exercise.weightKg
      ) else {
        preconditionFailure("Exercise weight must be available in the workout plan")
      }
      return index
    } set: { index in
      guard WorkoutPlan.availableWeightsKg.indices.contains(index) else { return }
      exercise.weightKg = WorkoutPlan.availableWeightsKg[index]
    }
  }

  private var weightIndexBounds: ClosedRange<Int> {
    WorkoutPlan.availableWeightsKg.startIndex
      ... WorkoutPlan.availableWeightsKg.index(
        before: WorkoutPlan.availableWeightsKg.endIndex
      )
  }

  private var shouldProgressBinding: Binding<Bool> {
    Binding {
      !exercise.shouldRepeat
    } set: { shouldProgress in
      exercise.shouldRepeat = !shouldProgress
    }
  }

  private var shouldShowProgressControl: Bool {
    guard isFocused else { return false }
    guard !isAddMode,
          let latestPerformance = history.lastPerformance(for: exercise.form),
          let latestWorkout = latestPerformance.workout
            else {
      return true
    }
    return latestWorkout.dayKey <= dayKey
  }
}

private struct CircleToggle: View {
  let title: String
  @Binding var isOn: Bool

  var body: some View {
    Button {
      isOn.toggle()
    } label: {
      HStack(spacing: 8) {
        Text(title)
          .foregroundStyle(.primary)
        Image(systemName: isOn ? "circle.fill" : "circle")
          .font(.title3)
          .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityValue(isOn ? "On" : "Off")
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
