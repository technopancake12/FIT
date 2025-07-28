export interface WorkoutProgram {
  id: string;
  name: string;
  description: string;
  duration: number; // weeks
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  goals: string[];
  equipment: string[];
  workoutsPerWeek: number;
  weeks: WorkoutWeek[];
  tags: string[];
  estimatedTime: number; // minutes per workout
  author?: string;
  rating?: number;
}

export interface WorkoutWeek {
  weekNumber: number;
  workouts: ProgramWorkout[];
  notes?: string;
}

export interface ProgramWorkout {
  id: string;
  name: string;
  type: 'strength' | 'cardio' | 'flexibility' | 'mixed';
  exercises: ProgramExercise[];
  restBetweenSets: number; // seconds
  estimatedDuration: number; // minutes
  instructions?: string[];
}

export interface ProgramExercise {
  exerciseId: string;
  sets: number;
  reps: string; // e.g., "8-12", "10", "AMRAP"
  weight?: string; // e.g., "65%", "bodyweight", "RPE 8"
  rest: number; // seconds
  notes?: string;
  progression?: ExerciseProgression;
}

export interface ExerciseProgression {
  type: 'linear' | 'percentage' | 'rpe';
  increment: number;
  frequency: 'weekly' | 'session';
  condition?: string;
}

export interface UserProgram {
  programId: string;
  startDate: Date;
  currentWeek: number;
  currentWorkout: number;
  completedWorkouts: string[];
  personalizations: ProgramPersonalization;
}

export interface ProgramPersonalization {
  weightAdjustments: { [exerciseId: string]: number };
  repAdjustments: { [exerciseId: string]: number };
  substitutions: { [exerciseId: string]: string };
  notes: string;
}

// Pre-built workout programs
export const workoutPrograms: WorkoutProgram[] = [
  {
    id: 'beginner-strength',
    name: 'Beginner Strength Foundation',
    description: 'Perfect for newcomers to strength training. Focuses on basic movement patterns and building a solid foundation.',
    duration: 8,
    difficulty: 'Beginner',
    goals: ['Build strength', 'Learn proper form', 'Establish routine'],
    equipment: ['Barbell', 'Dumbbell', 'Bench'],
    workoutsPerWeek: 3,
    estimatedTime: 45,
    tags: ['strength', 'beginner', 'full-body'],
    rating: 4.8,
    weeks: [
      {
        weekNumber: 1,
        workouts: [
          {
            id: 'week1-workout1',
            name: 'Full Body A',
            type: 'strength',
            restBetweenSets: 90,
            estimatedDuration: 45,
            exercises: [
              {
                exerciseId: 'squat',
                sets: 3,
                reps: '8-10',
                weight: 'bodyweight',
                rest: 90,
                notes: 'Focus on depth and form'
              },
              {
                exerciseId: 'push-up',
                sets: 3,
                reps: '5-8',
                weight: 'bodyweight',
                rest: 60,
                progression: { type: 'linear', increment: 1, frequency: 'weekly' }
              },
              {
                exerciseId: 'bent-over-row',
                sets: 3,
                reps: '8-10',
                weight: 'light',
                rest: 90
              }
            ]
          },
          {
            id: 'week1-workout2',
            name: 'Full Body B',
            type: 'strength',
            restBetweenSets: 90,
            estimatedDuration: 45,
            exercises: [
              {
                exerciseId: 'deadlift',
                sets: 3,
                reps: '5-8',
                weight: 'light',
                rest: 120,
                notes: 'Start very light, focus on hip hinge pattern'
              },
              {
                exerciseId: 'overhead-press',
                sets: 3,
                reps: '6-8',
                weight: 'light',
                rest: 90
              },
              {
                exerciseId: 'lunge',
                sets: 3,
                reps: '8 each leg',
                weight: 'bodyweight',
                rest: 60
              }
            ]
          }
        ]
      }
    ]
  },
  {
    id: 'push-pull-legs',
    name: 'Push/Pull/Legs Split',
    description: 'Classic intermediate program splitting workouts by movement patterns. Great for building muscle and strength.',
    duration: 12,
    difficulty: 'Intermediate',
    goals: ['Build muscle', 'Increase strength', 'Improve body composition'],
    equipment: ['Barbell', 'Dumbbell', 'Pull-up Bar', 'Cable Machine'],
    workoutsPerWeek: 6,
    estimatedTime: 60,
    tags: ['strength', 'muscle-building', 'split'],
    rating: 4.6,
    weeks: [
      {
        weekNumber: 1,
        workouts: [
          {
            id: 'ppl-push',
            name: 'Push Day',
            type: 'strength',
            restBetweenSets: 120,
            estimatedDuration: 60,
            exercises: [
              {
                exerciseId: 'bench-press',
                sets: 4,
                reps: '6-8',
                weight: '75%',
                rest: 120,
                progression: { type: 'linear', increment: 2.5, frequency: 'weekly' }
              },
              {
                exerciseId: 'overhead-press',
                sets: 3,
                reps: '8-10',
                weight: '70%',
                rest: 90
              },
              {
                exerciseId: 'tricep-dip',
                sets: 3,
                reps: '10-12',
                weight: 'bodyweight',
                rest: 60
              },
              {
                exerciseId: 'lateral-raise',
                sets: 3,
                reps: '12-15',
                weight: 'light',
                rest: 45
              }
            ]
          },
          {
            id: 'ppl-pull',
            name: 'Pull Day',
            type: 'strength',
            restBetweenSets: 120,
            estimatedDuration: 60,
            exercises: [
              {
                exerciseId: 'deadlift',
                sets: 4,
                reps: '5-6',
                weight: '80%',
                rest: 180,
                progression: { type: 'linear', increment: 5, frequency: 'weekly' }
              },
              {
                exerciseId: 'pull-up',
                sets: 3,
                reps: '6-10',
                weight: 'bodyweight',
                rest: 90
              },
              {
                exerciseId: 'bent-over-row',
                sets: 3,
                reps: '8-10',
                weight: '75%',
                rest: 90
              },
              {
                exerciseId: 'bicep-curl',
                sets: 3,
                reps: '10-12',
                weight: 'moderate',
                rest: 60
              }
            ]
          },
          {
            id: 'ppl-legs',
            name: 'Legs Day',
            type: 'strength',
            restBetweenSets: 120,
            estimatedDuration: 60,
            exercises: [
              {
                exerciseId: 'squat',
                sets: 4,
                reps: '6-8',
                weight: '75%',
                rest: 150,
                progression: { type: 'linear', increment: 2.5, frequency: 'weekly' }
              },
              {
                exerciseId: 'lunge',
                sets: 3,
                reps: '10 each leg',
                weight: 'moderate',
                rest: 90
              }
            ]
          }
        ]
      }
    ]
  },
  {
    id: 'hiit-cardio',
    name: 'HIIT Cardio Blast',
    description: 'High-intensity interval training program for fat loss and cardiovascular fitness.',
    duration: 6,
    difficulty: 'Intermediate',
    goals: ['Fat loss', 'Improve cardio', 'Time efficient'],
    equipment: ['Bodyweight', 'Timer'],
    workoutsPerWeek: 4,
    estimatedTime: 25,
    tags: ['cardio', 'hiit', 'fat-loss'],
    rating: 4.4,
    weeks: [
      {
        weekNumber: 1,
        workouts: [
          {
            id: 'hiit-workout1',
            name: 'HIIT Circuit A',
            type: 'cardio',
            restBetweenSets: 30,
            estimatedDuration: 25,
            exercises: [
              {
                exerciseId: 'squat',
                sets: 4,
                reps: '20 seconds',
                weight: 'bodyweight',
                rest: 10,
                notes: 'Maximum effort for 20 seconds'
              },
              {
                exerciseId: 'push-up',
                sets: 4,
                reps: '20 seconds',
                weight: 'bodyweight',
                rest: 10
              }
            ]
          }
        ]
      }
    ]
  }
];

export class ProgramTracker {
  private userPrograms: UserProgram[] = [];

  constructor() {
    this.loadFromStorage();
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('user_programs');
      if (stored) {
        this.userPrograms = JSON.parse(stored);
      }
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('user_programs', JSON.stringify(this.userPrograms));
    }
  }

  startProgram(programId: string): UserProgram {
    const userProgram: UserProgram = {
      programId,
      startDate: new Date(),
      currentWeek: 1,
      currentWorkout: 0,
      completedWorkouts: [],
      personalizations: {
        weightAdjustments: {},
        repAdjustments: {},
        substitutions: {},
        notes: ''
      }
    };

    this.userPrograms.push(userProgram);
    this.saveToStorage();
    return userProgram;
  }

  getCurrentProgram(): UserProgram | null {
    return this.userPrograms.find(program =>
      program.completedWorkouts.length < this.getTotalWorkouts(program.programId)
    ) || null;
  }

  completeWorkout(programId: string, workoutId: string): void {
    const userProgram = this.userPrograms.find(p => p.programId === programId);
    if (!userProgram) return;

    userProgram.completedWorkouts.push(workoutId);

    // Advance to next workout
    const program = this.getProgram(programId);
    if (program) {
      const currentWeekWorkouts = program.weeks[userProgram.currentWeek - 1]?.workouts || [];
      if (userProgram.currentWorkout >= currentWeekWorkouts.length - 1) {
        // Move to next week
        userProgram.currentWeek++;
        userProgram.currentWorkout = 0;
      } else {
        userProgram.currentWorkout++;
      }
    }

    this.saveToStorage();
  }

  getProgram(programId: string): WorkoutProgram | undefined {
    return workoutPrograms.find(p => p.id === programId);
  }

  getCurrentWorkout(): ProgramWorkout | null {
    const userProgram = this.getCurrentProgram();
    if (!userProgram) return null;

    const program = this.getProgram(userProgram.programId);
    if (!program) return null;

    const currentWeek = program.weeks[userProgram.currentWeek - 1];
    if (!currentWeek) return null;

    return currentWeek.workouts[userProgram.currentWorkout] || null;
  }

  getProgramProgress(programId: string): number {
    const userProgram = this.userPrograms.find(p => p.programId === programId);
    if (!userProgram) return 0;

    const totalWorkouts = this.getTotalWorkouts(programId);
    return (userProgram.completedWorkouts.length / totalWorkouts) * 100;
  }

  private getTotalWorkouts(programId: string): number {
    const program = this.getProgram(programId);
    if (!program) return 0;

    return program.weeks.reduce((total, week) => total + week.workouts.length, 0);
  }

  personalizeExercise(programId: string, exerciseId: string, adjustments: Partial<ProgramPersonalization>): void {
    const userProgram = this.userPrograms.find(p => p.programId === programId);
    if (!userProgram) return;

    if (adjustments.weightAdjustments) {
      userProgram.personalizations.weightAdjustments = {
        ...userProgram.personalizations.weightAdjustments,
        ...adjustments.weightAdjustments
      };
    }

    if (adjustments.repAdjustments) {
      userProgram.personalizations.repAdjustments = {
        ...userProgram.personalizations.repAdjustments,
        ...adjustments.repAdjustments
      };
    }

    if (adjustments.substitutions) {
      userProgram.personalizations.substitutions = {
        ...userProgram.personalizations.substitutions,
        ...adjustments.substitutions
      };
    }

    this.saveToStorage();
  }

  getRecommendedPrograms(userLevel: string, goals: string[], equipment: string[]): WorkoutProgram[] {
    return workoutPrograms.filter(program => {
      const levelMatch = program.difficulty.toLowerCase() === userLevel.toLowerCase();
      const goalMatch = goals.some(goal =>
        program.goals.some(programGoal =>
          programGoal.toLowerCase().includes(goal.toLowerCase())
        )
      );
      const equipmentMatch = program.equipment.every(item =>
        equipment.includes(item) || item === 'Bodyweight'
      );

      return levelMatch && (goalMatch || goals.length === 0) && equipmentMatch;
    });
  }

  searchPrograms(query: string): WorkoutProgram[] {
    const lowerQuery = query.toLowerCase();
    return workoutPrograms.filter(program =>
      program.name.toLowerCase().includes(lowerQuery) ||
      program.description.toLowerCase().includes(lowerQuery) ||
      program.tags.some(tag => tag.toLowerCase().includes(lowerQuery))
    );
  }
}

export const programTracker = new ProgramTracker();
