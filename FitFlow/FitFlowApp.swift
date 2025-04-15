import SwiftUI
import SwiftData

@main
struct FitFlowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            User.self,
            WorkoutSession.self,
            ExerciseEntry.self,
            ExerciseSet.self,
            FavoriteWorkoutTitle.self,
            FavoriteExercise.self,
            Routine.self,
            RoutineExercise.self
        ])
    }
}
