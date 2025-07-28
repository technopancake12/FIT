import { exerciseDatabase, Exercise } from './exercises';

export interface CustomExercise {
  exerciseId: string;
  sets: number;
  reps: string; // e.g., "8-12", "AMRAP", "30 seconds"
  weight: string; // e.g., "bodyweight", "50kg", "70%"
  rest: number; // seconds
  notes?: string;
  superset?: string; // ID of superset group
  dropset?: boolean;
  restPause?: boolean;
}

export interface CustomWorkout {
  id: string;
  name: string;
  description?: string;
  targetMuscles: string[];
  estimatedDuration: number; // minutes
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  exercises: CustomExercise[];
  warmup?: CustomExercise[];
  cooldown?: CustomExercise[];
  equipment: string[];
  tags: string[];
  isTemplate: boolean;
  createdBy: string;
  createdAt: Date;
  ratings: number[];
  timesUsed: number;
}

export interface CustomProgram {
  id: string;
  name: string;
  description: string;
  duration: number; // weeks
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  goals: string[];
  schedule: {
    [key: string]: { // day of week
      workoutId: string;
      optional: boolean;
    };
  };
  workouts: CustomWorkout[];
  progressionRules: ProgressionRule[];
  deloadWeeks: number[];
  createdBy: string;
  createdAt: Date;
  isPublic: boolean;
  ratings: number[];
  followers: number;
}

export interface ProgressionRule {
  exerciseIds: string[];
  type: 'linear' | 'percentage' | 'rpe_based';
  increment: number;
  frequency: 'weekly' | 'session' | 'plateau';
  condition?: string; // e.g., "complete all sets", "RPE < 8"
}

export interface WorkoutTemplate {
  id: string;
  name: string;
  category: string;
  description: string;
  exercises: {
    exerciseId: string;
    defaultSets: number;
    defaultReps: string;
    defaultWeight: string;
    defaultRest: number;
  }[];
  estimatedDuration: number;
  difficulty: string;
}

export class CustomWorkoutBuilder {
  private customWorkouts: CustomWorkout[] = [];
  private customPrograms: CustomProgram[] = [];
  private templates: WorkoutTemplate[] = [];

  constructor() {
    this.loadFromStorage();
    this.initializeTemplates();
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const workouts = localStorage.getItem('custom_workouts');
      const programs = localStorage.getItem('custom_programs');

      if (workouts) {
        this.customWorkouts = JSON.parse(workouts).map((w: any) => ({
          ...w,
          createdAt: new Date(w.createdAt)
        }));
      }

      if (programs) {
        this.customPrograms = JSON.parse(programs).map((p: any) => ({
          ...p,
          createdAt: new Date(p.createdAt)
        }));
      }
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('custom_workouts', JSON.stringify(this.customWorkouts));
      localStorage.setItem('custom_programs', JSON.stringify(this.customPrograms));
    }
  }

  private initializeTemplates(): void {
    this.templates = [
      {
        id: 'template_upper_body',
        name: 'Upper Body Strength',
        category: 'Strength',
        description: 'Complete upper body workout targeting all major muscle groups',
        exercises: [
          { exerciseId: 'bench-press', defaultSets: 4, defaultReps: '6-8', defaultWeight: '75%', defaultRest: 120 },
          { exerciseId: 'bent-over-row', defaultSets: 4, defaultReps: '6-8', defaultWeight: '75%', defaultRest: 120 },
          { exerciseId: 'overhead-press', defaultSets: 3, defaultReps: '8-10', defaultWeight: '70%', defaultRest: 90 },
          { exerciseId: 'pull-up', defaultSets: 3, defaultReps: '6-10', defaultWeight: 'bodyweight', defaultRest: 90 },
          { exerciseId: 'bicep-curl', defaultSets: 3, defaultReps: '10-12', defaultWeight: 'moderate', defaultRest: 60 },
          { exerciseId: 'tricep-dip', defaultSets: 3, defaultReps: '8-12', defaultWeight: 'bodyweight', defaultRest: 60 }
        ],
        estimatedDuration: 60,
        difficulty: 'Intermediate'
      },
      {
        id: 'template_hiit_cardio',
        name: 'HIIT Cardio Blast',
        category: 'Cardio',
        description: 'High-intensity interval training for maximum calorie burn',
        exercises: [
          { exerciseId: 'squat', defaultSets: 4, defaultReps: '30 seconds', defaultWeight: 'bodyweight', defaultRest: 15 },
          { exerciseId: 'push-up', defaultSets: 4, defaultReps: '30 seconds', defaultWeight: 'bodyweight', defaultRest: 15 },
          { exerciseId: 'lunge', defaultSets: 4, defaultReps: '30 seconds', defaultWeight: 'bodyweight', defaultRest: 15 }
        ],
        estimatedDuration: 20,
        difficulty: 'Intermediate'
      },
      {
        id: 'template_core_strength',
        name: 'Core & Stability',
        category: 'Core',
        description: 'Comprehensive core workout for strength and stability',
        exercises: [
          { exerciseId: 'squat', defaultSets: 3, defaultReps: '30 seconds', defaultWeight: 'bodyweight', defaultRest: 30 },
          { exerciseId: 'lunge', defaultSets: 3, defaultReps: '20 each side', defaultWeight: 'bodyweight', defaultRest: 45 }
        ],
        estimatedDuration: 25,
        difficulty: 'Beginner'
      }
    ];
  }

  // Workout creation
  createWorkout(workout: Omit<CustomWorkout, 'id' | 'createdAt' | 'ratings' | 'timesUsed'>): CustomWorkout {
    const newWorkout: CustomWorkout = {
      ...workout,
      id: `custom_workout_${Date.now()}`,
      createdAt: new Date(),
      ratings: [],
      timesUsed: 0
    };

    this.customWorkouts.push(newWorkout);
    this.saveToStorage();
    return newWorkout;
  }

  createWorkoutFromTemplate(templateId: string, customizations?: Partial<CustomWorkout>): CustomWorkout {
    const template = this.templates.find(t => t.id === templateId);
    if (!template) throw new Error('Template not found');

    const workout: CustomWorkout = {
      id: `custom_workout_${Date.now()}`,
      name: customizations?.name || template.name,
      description: customizations?.description || template.description,
      targetMuscles: this.calculateTargetMuscles(template.exercises.map(e => e.exerciseId)),
      estimatedDuration: template.estimatedDuration,
      difficulty: (customizations?.difficulty || template.difficulty) as any,
      exercises: template.exercises.map(e => ({
        exerciseId: e.exerciseId,
        sets: e.defaultSets,
        reps: e.defaultReps,
        weight: e.defaultWeight,
        rest: e.defaultRest
      })),
      equipment: this.calculateRequiredEquipment(template.exercises.map(e => e.exerciseId)),
      tags: customizations?.tags || [template.category.toLowerCase()],
      isTemplate: false,
      createdBy: 'user',
      createdAt: new Date(),
      ratings: [],
      timesUsed: 0
    };

    this.customWorkouts.push(workout);
    this.saveToStorage();
    return workout;
  }

  // Program creation
  createProgram(program: Omit<CustomProgram, 'id' | 'createdAt' | 'ratings' | 'followers'>): CustomProgram {
    const newProgram: CustomProgram = {
      ...program,
      id: `custom_program_${Date.now()}`,
      createdAt: new Date(),
      ratings: [],
      followers: 0
    };

    this.customPrograms.push(newProgram);
    this.saveToStorage();
    return newProgram;
  }

  // Exercise suggestions
  suggestExercises(targetMuscles: string[], equipment: string[], difficulty: string): Exercise[] {
    return exerciseDatabase.filter(exercise => {
      const muscleMatch = targetMuscles.some(muscle =>
        exercise.primaryMuscles.includes(muscle) ||
        exercise.secondaryMuscles.includes(muscle)
      );

      const equipmentMatch = equipment.includes(exercise.equipment) || exercise.equipment === 'Bodyweight';
      const difficultyMatch = exercise.difficulty === difficulty || difficulty === 'Any';

      return muscleMatch && equipmentMatch && difficultyMatch;
    });
  }

  // Workout optimization
  optimizeWorkout(workout: CustomWorkout): {
    suggestions: string[];
    estimatedDuration: number;
    muscleBalance: { [muscle: string]: number };
  } {
    const suggestions: string[] = [];
    let estimatedDuration = 0;
    const muscleBalance: { [muscle: string]: number } = {};

    // Calculate estimated duration
    workout.exercises.forEach(exercise => {
      const restTime = exercise.rest * (exercise.sets - 1) / 60; // convert to minutes
      const workTime = exercise.sets * 1; // assume 1 minute per set
      estimatedDuration += workTime + restTime;
    });

    // Calculate muscle balance
    workout.exercises.forEach(exercise => {
      const exerciseInfo = exerciseDatabase.find(e => e.id === exercise.exerciseId);
      if (exerciseInfo) {
        exerciseInfo.primaryMuscles.forEach(muscle => {
          muscleBalance[muscle] = (muscleBalance[muscle] || 0) + exercise.sets * 2;
        });
        exerciseInfo.secondaryMuscles.forEach(muscle => {
          muscleBalance[muscle] = (muscleBalance[muscle] || 0) + exercise.sets;
        });
      }
    });

    // Generate suggestions
    if (estimatedDuration > 90) {
      suggestions.push('Consider reducing rest times or number of exercises for a shorter workout');
    }

    if (estimatedDuration < 20) {
      suggestions.push('Consider adding more exercises for a more comprehensive workout');
    }

    const muscleGroups = Object.keys(muscleBalance);
    if (muscleGroups.length < 2) {
      suggestions.push('Consider adding exercises for other muscle groups for better balance');
    }

    // Check for muscle imbalances
    const pushMuscles = ['Chest', 'Shoulders', 'Triceps'];
    const pullMuscles = ['Back', 'Biceps'];

    const pushVolume = pushMuscles.reduce((sum, muscle) => sum + (muscleBalance[muscle] || 0), 0);
    const pullVolume = pullMuscles.reduce((sum, muscle) => sum + (muscleBalance[muscle] || 0), 0);

    if (pushVolume > pullVolume * 1.5) {
      suggestions.push('Consider adding more pulling exercises to balance push/pull ratio');
    } else if (pullVolume > pushVolume * 1.5) {
      suggestions.push('Consider adding more pushing exercises to balance push/pull ratio');
    }

    return {
      suggestions,
      estimatedDuration: Math.round(estimatedDuration),
      muscleBalance
    };
  }

  // Progression planning
  createProgressionPlan(workoutId: string, weeks: number): {
    week: number;
    modifications: { exerciseId: string; change: string }[];
  }[] {
    const workout = this.customWorkouts.find(w => w.id === workoutId);
    if (!workout) return [];

    const progressionPlan = [];

    for (let week = 1; week <= weeks; week++) {
      const modifications: { exerciseId: string; change: string }[] = [];

      workout.exercises.forEach(exercise => {
        if (week % 2 === 0) { // Every second week
          const exerciseInfo = exerciseDatabase.find(e => e.id === exercise.exerciseId);
          if (exerciseInfo) {
            if (exercise.weight !== 'bodyweight') {
              modifications.push({
                exerciseId: exercise.exerciseId,
                change: 'Increase weight by 2.5-5kg'
              });
            } else {
              modifications.push({
                exerciseId: exercise.exerciseId,
                change: 'Increase reps by 1-2'
              });
            }
          }
        }
      });

      if (modifications.length > 0) {
        progressionPlan.push({ week, modifications });
      }
    }

    return progressionPlan;
  }

  // Helper methods
  private calculateTargetMuscles(exerciseIds: string[]): string[] {
    const muscles = new Set<string>();

    exerciseIds.forEach(id => {
      const exercise = exerciseDatabase.find(e => e.id === id);
      if (exercise) {
        exercise.primaryMuscles.forEach(muscle => muscles.add(muscle));
      }
    });

    return Array.from(muscles);
  }

  private calculateRequiredEquipment(exerciseIds: string[]): string[] {
    const equipment = new Set<string>();

    exerciseIds.forEach(id => {
      const exercise = exerciseDatabase.find(e => e.id === id);
      if (exercise && exercise.equipment !== 'Bodyweight') {
        equipment.add(exercise.equipment);
      }
    });

    return Array.from(equipment);
  }

  // Getters
  getCustomWorkouts(): CustomWorkout[] {
    return this.customWorkouts.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  getCustomPrograms(): CustomProgram[] {
    return this.customPrograms.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  getTemplates(): WorkoutTemplate[] {
    return this.templates;
  }

  getWorkout(id: string): CustomWorkout | undefined {
    return this.customWorkouts.find(w => w.id === id);
  }

  getProgram(id: string): CustomProgram | undefined {
    return this.customPrograms.find(p => p.id === id);
  }

  // Updates
  updateWorkout(id: string, updates: Partial<CustomWorkout>): boolean {
    const index = this.customWorkouts.findIndex(w => w.id === id);
    if (index === -1) return false;

    this.customWorkouts[index] = { ...this.customWorkouts[index], ...updates };
    this.saveToStorage();
    return true;
  }

  deleteWorkout(id: string): boolean {
    const index = this.customWorkouts.findIndex(w => w.id === id);
    if (index === -1) return false;

    this.customWorkouts.splice(index, 1);
    this.saveToStorage();
    return true;
  }

  rateWorkout(id: string, rating: number): boolean {
    const workout = this.customWorkouts.find(w => w.id === id);
    if (!workout) return false;

    workout.ratings.push(rating);
    this.saveToStorage();
    return true;
  }

  incrementWorkoutUsage(id: string): void {
    const workout = this.customWorkouts.find(w => w.id === id);
    if (workout) {
      workout.timesUsed++;
      this.saveToStorage();
    }
  }

  // Search and filter
  searchWorkouts(query: string): CustomWorkout[] {
    const lowerQuery = query.toLowerCase();
    return this.customWorkouts.filter(workout =>
      workout.name.toLowerCase().includes(lowerQuery) ||
      workout.description?.toLowerCase().includes(lowerQuery) ||
      workout.tags.some(tag => tag.toLowerCase().includes(lowerQuery)) ||
      workout.targetMuscles.some(muscle => muscle.toLowerCase().includes(lowerQuery))
    );
  }

  filterWorkouts(filters: {
    difficulty?: string[];
    duration?: { min: number; max: number };
    equipment?: string[];
    muscles?: string[];
  }): CustomWorkout[] {
    return this.customWorkouts.filter(workout => {
      if (filters.difficulty && !filters.difficulty.includes(workout.difficulty)) {
        return false;
      }

      if (filters.duration) {
        if (workout.estimatedDuration < filters.duration.min ||
            workout.estimatedDuration > filters.duration.max) {
          return false;
        }
      }

      if (filters.equipment && filters.equipment.length > 0) {
        const hasRequiredEquipment = workout.equipment.every(eq =>
          filters.equipment!.includes(eq) || eq === 'Bodyweight'
        );
        if (!hasRequiredEquipment) return false;
      }

      if (filters.muscles && filters.muscles.length > 0) {
        const hasTargetMuscle = workout.targetMuscles.some(muscle =>
          filters.muscles!.includes(muscle)
        );
        if (!hasTargetMuscle) return false;
      }

      return true;
    });
  }
}

export const customWorkoutBuilder = new CustomWorkoutBuilder();
