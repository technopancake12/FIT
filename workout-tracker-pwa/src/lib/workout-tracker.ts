export interface WorkoutSet {
  id: string;
  reps: number;
  weight: number;
  restTime?: number;
  completed: boolean;
  rpe?: number; // Rate of Perceived Exertion (1-10)
}

export interface WorkoutExercise {
  id: string;
  exerciseId: string;
  sets: WorkoutSet[];
  notes?: string;
  targetSets: number;
  targetReps: number;
  targetWeight: number;
}

export interface Workout {
  id: string;
  name: string;
  date: Date;
  exercises: WorkoutExercise[];
  duration?: number;
  completed: boolean;
  notes?: string;
}

export interface ExerciseHistory {
  exerciseId: string;
  workouts: {
    date: Date;
    sets: WorkoutSet[];
    volume: number;
    maxWeight: number;
  }[];
}

export interface ProgressionSuggestion {
  type: 'weight' | 'reps' | 'sets';
  currentValue: number;
  suggestedValue: number;
  reason: string;
}

export class WorkoutTracker {
  private workouts: Workout[] = [];
  private currentWorkout: Workout | null = null;

  constructor() {
    this.loadFromStorage();
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('workouts');
      if (stored) {
        this.workouts = JSON.parse(stored);
      }
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('workouts', JSON.stringify(this.workouts));
    }
  }

  startWorkout(name: string, exercises: { exerciseId: string; targetSets: number; targetReps: number; targetWeight: number }[]): Workout {
    const workout: Workout = {
      id: `workout_${Date.now()}`,
      name,
      date: new Date(),
      exercises: exercises.map((ex, index) => ({
        id: `exercise_${index}`,
        exerciseId: ex.exerciseId,
        sets: Array.from({ length: ex.targetSets }, (_, i) => ({
          id: `set_${i}`,
          reps: 0,
          weight: ex.targetWeight,
          completed: false
        })),
        targetSets: ex.targetSets,
        targetReps: ex.targetReps,
        targetWeight: ex.targetWeight
      })),
      completed: false
    };

    this.currentWorkout = workout;
    return workout;
  }

  updateSet(exerciseIndex: number, setIndex: number, data: Partial<WorkoutSet>): void {
    if (!this.currentWorkout) return;

    const exercise = this.currentWorkout.exercises[exerciseIndex];
    if (!exercise || !exercise.sets[setIndex]) return;

    exercise.sets[setIndex] = { ...exercise.sets[setIndex], ...data };
    this.saveToStorage();
  }

  completeWorkout(): void {
    if (!this.currentWorkout) return;

    this.currentWorkout.completed = true;
    this.currentWorkout.duration = Date.now() - this.currentWorkout.date.getTime();
    this.workouts.push(this.currentWorkout);
    this.currentWorkout = null;
    this.saveToStorage();
  }

  getExerciseHistory(exerciseId: string): ExerciseHistory {
    const workoutHistory = this.workouts
      .filter(workout => workout.completed)
      .map(workout => {
        const exercise = workout.exercises.find(ex => ex.exerciseId === exerciseId);
        if (!exercise) return null;

        const completedSets = exercise.sets.filter(set => set.completed);
        const volume = completedSets.reduce((sum, set) => sum + (set.reps * set.weight), 0);
        const maxWeight = Math.max(...completedSets.map(set => set.weight));

        return {
          date: workout.date,
          sets: completedSets,
          volume,
          maxWeight
        };
      })
      .filter((item): item is NonNullable<typeof item> => item !== null);

    return {
      exerciseId,
      workouts: workoutHistory
    };
  }

  getProgressionSuggestion(exerciseId: string, currentSets: number, currentReps: number, currentWeight: number): ProgressionSuggestion {
    const history = this.getExerciseHistory(exerciseId);

    if (history.workouts.length < 3) {
      return {
        type: 'weight',
        currentValue: currentWeight,
        suggestedValue: currentWeight + 2.5,
        reason: 'Progressive overload - increase weight gradually'
      };
    }

    const lastThreeWorkouts = history.workouts.slice(-3);
    const averageReps = lastThreeWorkouts.reduce((sum, w) =>
      sum + w.sets.reduce((setSum, set) => setSum + set.reps, 0) / w.sets.length, 0
    ) / lastThreeWorkouts.length;

    // If consistently hitting upper rep range, suggest weight increase
    if (averageReps >= currentReps + 2) {
      return {
        type: 'weight',
        currentValue: currentWeight,
        suggestedValue: currentWeight + 5,
        reason: 'Consistently exceeding target reps - time to increase weight'
      };
    }

    // If struggling with current weight, suggest rep increase
    if (averageReps < currentReps - 2) {
      return {
        type: 'reps',
        currentValue: currentReps,
        suggestedValue: Math.max(currentReps - 1, 5),
        reason: 'Focus on form and building strength at current weight'
      };
    }

    // Standard progression
    return {
      type: 'weight',
      currentValue: currentWeight,
      suggestedValue: currentWeight + 2.5,
      reason: 'Standard progressive overload'
    };
  }

  getAlternativeExercises(exerciseId: string, targetMuscles: string[], currentWeight: number, currentReps: number): WorkoutExercise[] {
    // This would integrate with the exercise database to suggest alternatives
    // For now, returning mock data
    return [
      {
        id: 'alt_1',
        exerciseId: 'push-up',
        sets: Array.from({ length: 3 }, (_, i) => ({
          id: `set_${i}`,
          reps: currentReps + 2,
          weight: 0,
          completed: false
        })),
        targetSets: 3,
        targetReps: currentReps + 2,
        targetWeight: 0
      }
    ];
  }

  getCurrentWorkout(): Workout | null {
    return this.currentWorkout;
  }

  getWorkoutHistory(): Workout[] {
    return this.workouts.filter(w => w.completed);
  }

  getWorkoutStats() {
    const completedWorkouts = this.getWorkoutHistory();
    const totalWorkouts = completedWorkouts.length;
    const totalVolume = completedWorkouts.reduce((sum, workout) => {
      return sum + workout.exercises.reduce((exSum, exercise) => {
        return exSum + exercise.sets.reduce((setSum, set) => {
          return setSum + (set.completed ? set.reps * set.weight : 0);
        }, 0);
      }, 0);
    }, 0);

    const thisWeek = completedWorkouts.filter(w => {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      return new Date(w.date) > weekAgo;
    }).length;

    const streak = this.calculateWorkoutStreak();

    return {
      totalWorkouts,
      totalVolume,
      workoutsThisWeek: thisWeek,
      currentStreak: streak
    };
  }

  private calculateWorkoutStreak(): number {
    const sortedWorkouts = this.getWorkoutHistory().sort((a, b) =>
      new Date(b.date).getTime() - new Date(a.date).getTime()
    );

    if (sortedWorkouts.length === 0) return 0;

    let streak = 0;
    let currentDate = new Date();

    for (const workout of sortedWorkouts) {
      const workoutDate = new Date(workout.date);
      const daysDiff = Math.floor((currentDate.getTime() - workoutDate.getTime()) / (1000 * 60 * 60 * 24));

      if (daysDiff <= 1) {
        streak++;
        currentDate = workoutDate;
      } else if (daysDiff <= 2 && streak === 0) {
        // Allow 1 day gap for the first workout
        streak++;
        currentDate = workoutDate;
      } else {
        break;
      }
    }

    return streak;
  }
}

export const workoutTracker = new WorkoutTracker();
