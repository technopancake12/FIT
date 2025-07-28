export interface Exercise {
  id: string;
  name: string;
  category: string;
  primaryMuscles: string[];
  secondaryMuscles: string[];
  equipment: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  instructions: string[];
  tips: string[];
  alternatives: string[];
}

export const MUSCLE_GROUPS = [
  'Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Forearms',
  'Abs', 'Obliques', 'Quadriceps', 'Hamstrings', 'Glutes', 'Calves'
];

export const EQUIPMENT_TYPES = [
  'Bodyweight', 'Barbell', 'Dumbbell', 'Resistance Band', 'Cable Machine',
  'Pull-up Bar', 'Bench', 'Smith Machine', 'Kettlebell', 'Medicine Ball'
];

export const exerciseDatabase: Exercise[] = [
  // Chest Exercises
  {
    id: 'push-up',
    name: 'Push-up',
    category: 'Chest',
    primaryMuscles: ['Chest'],
    secondaryMuscles: ['Triceps', 'Shoulders'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    instructions: [
      'Start in a plank position with hands shoulder-width apart',
      'Lower your body until chest nearly touches the floor',
      'Push back up to starting position',
      'Keep core tight throughout the movement'
    ],
    tips: [
      'Keep your body in a straight line',
      'Don\'t let your hips sag or pike up',
      'Control the descent for better muscle activation'
    ],
    alternatives: ['incline-push-up', 'knee-push-up', 'bench-press']
  },
  {
    id: 'bench-press',
    name: 'Bench Press',
    category: 'Chest',
    primaryMuscles: ['Chest'],
    secondaryMuscles: ['Triceps', 'Shoulders'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Lie on bench with eyes under the bar',
      'Grip bar slightly wider than shoulder width',
      'Lower bar to chest with control',
      'Press bar back up to starting position'
    ],
    tips: [
      'Keep feet flat on the floor',
      'Maintain natural arch in lower back',
      'Touch the bar to your chest lightly'
    ],
    alternatives: ['dumbbell-bench-press', 'push-up', 'incline-bench-press']
  },
  {
    id: 'dumbbell-bench-press',
    name: 'Dumbbell Bench Press',
    category: 'Chest',
    primaryMuscles: ['Chest'],
    secondaryMuscles: ['Triceps', 'Shoulders'],
    equipment: 'Dumbbell',
    difficulty: 'Intermediate',
    instructions: [
      'Lie on bench holding dumbbells at chest level',
      'Press dumbbells up and slightly inward',
      'Lower dumbbells with control to chest level',
      'Repeat for desired reps'
    ],
    tips: [
      'Allow for greater range of motion than barbell',
      'Keep wrists straight',
      'Control the weight on the way down'
    ],
    alternatives: ['bench-press', 'incline-dumbbell-press', 'push-up']
  },

  // Back Exercises
  {
    id: 'pull-up',
    name: 'Pull-up',
    category: 'Back',
    primaryMuscles: ['Back'],
    secondaryMuscles: ['Biceps', 'Shoulders'],
    equipment: 'Pull-up Bar',
    difficulty: 'Intermediate',
    instructions: [
      'Hang from bar with palms facing away',
      'Pull yourself up until chin clears the bar',
      'Lower yourself with control',
      'Repeat for desired reps'
    ],
    tips: [
      'Start from a dead hang',
      'Engage your core',
      'Don\'t swing or use momentum'
    ],
    alternatives: ['lat-pulldown', 'assisted-pull-up', 'bent-over-row']
  },
  {
    id: 'bent-over-row',
    name: 'Bent-over Row',
    category: 'Back',
    primaryMuscles: ['Back'],
    secondaryMuscles: ['Biceps', 'Shoulders'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Stand with feet hip-width apart holding barbell',
      'Hinge at hips, keeping back straight',
      'Pull bar to lower chest/upper abdomen',
      'Lower bar with control'
    ],
    tips: [
      'Keep core engaged',
      'Don\'t round your back',
      'Squeeze shoulder blades together at the top'
    ],
    alternatives: ['dumbbell-row', 'seated-cable-row', 't-bar-row']
  },
  {
    id: 'lat-pulldown',
    name: 'Lat Pulldown',
    category: 'Back',
    primaryMuscles: ['Back'],
    secondaryMuscles: ['Biceps', 'Shoulders'],
    equipment: 'Cable Machine',
    difficulty: 'Beginner',
    instructions: [
      'Sit at lat pulldown machine with wide grip',
      'Pull bar down to upper chest',
      'Squeeze shoulder blades together',
      'Slowly return to starting position'
    ],
    tips: [
      'Don\'t lean back too much',
      'Focus on pulling with your back, not arms',
      'Control the weight on the way up'
    ],
    alternatives: ['pull-up', 'assisted-pull-up', 'cable-row']
  },

  // Shoulder Exercises
  {
    id: 'overhead-press',
    name: 'Overhead Press',
    category: 'Shoulders',
    primaryMuscles: ['Shoulders'],
    secondaryMuscles: ['Triceps', 'Abs'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Stand with feet shoulder-width apart',
      'Hold barbell at shoulder height',
      'Press bar overhead until arms are fully extended',
      'Lower bar back to shoulder height'
    ],
    tips: [
      'Keep core tight',
      'Don\'t arch your back excessively',
      'Press the bar in a straight line'
    ],
    alternatives: ['dumbbell-shoulder-press', 'seated-shoulder-press', 'pike-push-up']
  },
  {
    id: 'lateral-raise',
    name: 'Lateral Raise',
    category: 'Shoulders',
    primaryMuscles: ['Shoulders'],
    secondaryMuscles: [],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Stand with dumbbells at your sides',
      'Raise arms out to the sides until parallel to floor',
      'Lower dumbbells with control',
      'Keep slight bend in elbows throughout'
    ],
    tips: [
      'Don\'t swing the weights',
      'Lead with your pinkies',
      'Stop at shoulder height'
    ],
    alternatives: ['cable-lateral-raise', 'resistance-band-lateral-raise']
  },

  // Leg Exercises
  {
    id: 'squat',
    name: 'Squat',
    category: 'Legs',
    primaryMuscles: ['Quadriceps', 'Glutes'],
    secondaryMuscles: ['Hamstrings', 'Abs'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    instructions: [
      'Stand with feet shoulder-width apart',
      'Lower yourself as if sitting in a chair',
      'Keep knees in line with toes',
      'Push through heels to return to standing'
    ],
    tips: [
      'Keep chest up and core engaged',
      'Don\'t let knees cave inward',
      'Go as low as mobility allows'
    ],
    alternatives: ['goblet-squat', 'front-squat', 'leg-press']
  },
  {
    id: 'deadlift',
    name: 'Deadlift',
    category: 'Legs',
    primaryMuscles: ['Hamstrings', 'Glutes', 'Back'],
    secondaryMuscles: ['Quadriceps', 'Abs'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Stand with feet hip-width apart, bar over mid-foot',
      'Hinge at hips and knees to grip the bar',
      'Keep back straight, chest up',
      'Drive through heels to lift the bar up your legs'
    ],
    tips: [
      'Keep the bar close to your body',
      'Don\'t round your back',
      'Fully extend hips and knees at the top'
    ],
    alternatives: ['romanian-deadlift', 'sumo-deadlift', 'trap-bar-deadlift']
  },
  {
    id: 'lunge',
    name: 'Lunge',
    category: 'Legs',
    primaryMuscles: ['Quadriceps', 'Glutes'],
    secondaryMuscles: ['Hamstrings', 'Abs'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    instructions: [
      'Step forward with one leg',
      'Lower until both knees are at 90 degrees',
      'Push back to starting position',
      'Repeat with other leg'
    ],
    tips: [
      'Keep most weight on front leg',
      'Don\'t let front knee go past toe',
      'Keep torso upright'
    ],
    alternatives: ['reverse-lunge', 'walking-lunge', 'bulgarian-split-squat']
  },

  // Arms Exercises
  {
    id: 'bicep-curl',
    name: 'Bicep Curl',
    category: 'Arms',
    primaryMuscles: ['Biceps'],
    secondaryMuscles: ['Forearms'],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Stand with dumbbells at your sides',
      'Keep elbows at your sides',
      'Curl weights up to shoulder level',
      'Lower with control'
    ],
    tips: [
      'Don\'t swing the weights',
      'Keep elbows stationary',
      'Control the negative portion'
    ],
    alternatives: ['hammer-curl', 'cable-curl', 'barbell-curl']
  },
  {
    id: 'tricep-dip',
    name: 'Tricep Dip',
    category: 'Arms',
    primaryMuscles: ['Triceps'],
    secondaryMuscles: ['Shoulders', 'Chest'],
    equipment: 'Bench',
    difficulty: 'Intermediate',
    instructions: [
      'Sit on edge of bench, hands beside hips',
      'Slide off bench, supporting weight with arms',
      'Lower yourself until elbows are at 90 degrees',
      'Push back up to starting position'
    ],
    tips: [
      'Keep elbows close to body',
      'Don\'t go too low if it hurts shoulders',
      'Keep legs straight for more difficulty'
    ],
    alternatives: ['close-grip-push-up', 'overhead-tricep-extension']
  }
];

export function getExercisesByMuscleGroup(muscleGroup: string): Exercise[] {
  return exerciseDatabase.filter(exercise =>
    exercise.primaryMuscles.includes(muscleGroup) ||
    exercise.secondaryMuscles.includes(muscleGroup)
  );
}

export function getExercisesByEquipment(equipment: string): Exercise[] {
  return exerciseDatabase.filter(exercise => exercise.equipment === equipment);
}

export function getAlternativeExercises(exerciseId: string): Exercise[] {
  const exercise = exerciseDatabase.find(ex => ex.id === exerciseId);
  if (!exercise) return [];

  return exercise.alternatives.map(altId =>
    exerciseDatabase.find(ex => ex.id === altId)
  ).filter(Boolean) as Exercise[];
}

export function searchExercises(query: string): Exercise[] {
  const lowerQuery = query.toLowerCase();
  return exerciseDatabase.filter(exercise =>
    exercise.name.toLowerCase().includes(lowerQuery) ||
    exercise.primaryMuscles.some(muscle => muscle.toLowerCase().includes(lowerQuery)) ||
    exercise.equipment.toLowerCase().includes(lowerQuery)
  );
}
