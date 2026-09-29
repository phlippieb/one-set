import Testing

@testable import Models

@Test("Focus cycles repeat every fourteen days across the epoch")
func focusCycles() {
    let epochCycle = WorkoutPlan.focusCycle(containing: "2026-09-21")
    #expect(epochCycle?.focusedGroup == .biceps)
    #expect(epochCycle?.startDayKey == "2026-09-21")
    #expect(epochCycle?.endDayKey == "2026-10-04")
    #expect(epochCycle?.nextFocusedGroup == .triceps)
    #expect(epochCycle?.nextStartDayKey == "2026-10-05")

    #expect(WorkoutPlan.focusCycle(containing: "2026-10-05")?.focusedGroup == .triceps)
    #expect(WorkoutPlan.focusCycle(containing: "2026-10-19")?.focusedGroup == .shoulders)
    #expect(WorkoutPlan.focusCycle(containing: "2026-11-02")?.focusedGroup == .biceps)
    #expect(WorkoutPlan.focusCycle(containing: "2026-09-20")?.focusedGroup == .shoulders)
    #expect(WorkoutPlan.focusCycle(containing: "2026-09-07")?.focusedGroup == .shoulders)
    #expect(WorkoutPlan.focusCycle(containing: "2026-09-06")?.focusedGroup == .triceps)
    #expect(WorkoutPlan.focusCycle(containing: "invalid") == nil)
}

@Test("Muscle-group presentation order starts with the focused group")
func muscleGroupOrder() {
    #expect(WorkoutPlan.muscleGroupOrder(on: "2026-09-21") == [.biceps, .triceps, .shoulders])
    #expect(WorkoutPlan.muscleGroupOrder(on: "2026-10-05") == [.triceps, .shoulders, .biceps])
    #expect(WorkoutPlan.muscleGroupOrder(on: "2026-10-19") == [.shoulders, .biceps, .triceps])
    #expect(WorkoutPlan.muscleGroupOrder(on: "invalid") == nil)
}
