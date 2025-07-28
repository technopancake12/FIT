export interface Food {
  id: string;
  name: string;
  brand?: string;
  barcode?: string;
  calories: number; // per 100g
  protein: number; // per 100g
  carbs: number; // per 100g
  fat: number; // per 100g
  fiber?: number; // per 100g
  sugar?: number; // per 100g
  sodium?: number; // per 100g (mg)
  category: string;
  servingSize?: number; // in grams
  servingUnit?: string;
  isVerified?: boolean;
}

export interface MealEntry {
  id: string;
  foodId: string;
  amount: number; // in grams
  mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  date: Date;
  notes?: string;
}

export interface DailyNutrition {
  date: Date;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number;
  meals: MealEntry[];
}

export interface NutritionGoals {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber?: number;
}

// Common foods database
export const foodDatabase: Food[] = [
  // Proteins
  {
    id: 'chicken-breast',
    name: 'Chicken Breast',
    calories: 165,
    protein: 31,
    carbs: 0,
    fat: 3.6,
    fiber: 0,
    category: 'Protein',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'salmon',
    name: 'Salmon',
    calories: 208,
    protein: 25,
    carbs: 0,
    fat: 12,
    fiber: 0,
    category: 'Protein',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'eggs',
    name: 'Eggs',
    calories: 155,
    protein: 13,
    carbs: 1.1,
    fat: 11,
    fiber: 0,
    category: 'Protein',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'ground-beef',
    name: 'Ground Beef (85% lean)',
    calories: 250,
    protein: 25,
    carbs: 0,
    fat: 17,
    fiber: 0,
    category: 'Protein',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },

  // Carbohydrates
  {
    id: 'brown-rice',
    name: 'Brown Rice',
    calories: 112,
    protein: 2.6,
    carbs: 22,
    fat: 0.9,
    fiber: 1.8,
    category: 'Carbohydrates',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'sweet-potato',
    name: 'Sweet Potato',
    calories: 86,
    protein: 1.6,
    carbs: 20,
    fat: 0.1,
    fiber: 3,
    category: 'Carbohydrates',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'oats',
    name: 'Oats',
    calories: 389,
    protein: 16.9,
    carbs: 66,
    fat: 6.9,
    fiber: 10.6,
    category: 'Carbohydrates',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'banana',
    name: 'Banana',
    calories: 89,
    protein: 1.1,
    carbs: 23,
    fat: 0.3,
    fiber: 2.6,
    sugar: 12,
    category: 'Fruits',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },

  // Vegetables
  {
    id: 'broccoli',
    name: 'Broccoli',
    calories: 34,
    protein: 2.8,
    carbs: 7,
    fat: 0.4,
    fiber: 2.6,
    category: 'Vegetables',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'spinach',
    name: 'Spinach',
    calories: 23,
    protein: 2.9,
    carbs: 3.6,
    fat: 0.4,
    fiber: 2.2,
    category: 'Vegetables',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },

  // Fats
  {
    id: 'avocado',
    name: 'Avocado',
    calories: 160,
    protein: 2,
    carbs: 9,
    fat: 15,
    fiber: 7,
    category: 'Fats',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'almonds',
    name: 'Almonds',
    calories: 579,
    protein: 21,
    carbs: 22,
    fat: 50,
    fiber: 12,
    category: 'Nuts & Seeds',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'olive-oil',
    name: 'Olive Oil',
    calories: 884,
    protein: 0,
    carbs: 0,
    fat: 100,
    fiber: 0,
    category: 'Fats',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },

  // Dairy
  {
    id: 'greek-yogurt',
    name: 'Greek Yogurt (Plain)',
    calories: 59,
    protein: 10,
    carbs: 3.6,
    fat: 0.4,
    fiber: 0,
    category: 'Dairy',
    servingSize: 100,
    servingUnit: 'g',
    isVerified: true
  },
  {
    id: 'milk',
    name: 'Milk (2%)',
    calories: 50,
    protein: 3.3,
    carbs: 4.8,
    fat: 2,
    fiber: 0,
    category: 'Dairy',
    servingSize: 100,
    servingUnit: 'ml',
    isVerified: true
  }
];

export class NutritionTracker {
  private meals: MealEntry[] = [];
  private goals: NutritionGoals = {
    calories: 2200,
    protein: 150,
    carbs: 275,
    fat: 73,
    fiber: 25
  };

  constructor() {
    this.loadFromStorage();
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const storedMeals = localStorage.getItem('nutrition_meals');
      const storedGoals = localStorage.getItem('nutrition_goals');

      if (storedMeals) {
        this.meals = JSON.parse(storedMeals);
      }

      if (storedGoals) {
        this.goals = JSON.parse(storedGoals);
      }
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('nutrition_meals', JSON.stringify(this.meals));
      localStorage.setItem('nutrition_goals', JSON.stringify(this.goals));
    }
  }

  addMealEntry(foodId: string, amount: number, mealType: MealEntry['mealType'], notes?: string): MealEntry {
    const meal: MealEntry = {
      id: `meal_${Date.now()}`,
      foodId,
      amount,
      mealType,
      date: new Date(),
      notes
    };

    this.meals.push(meal);
    this.saveToStorage();
    return meal;
  }

  updateMealEntry(mealId: string, updates: Partial<MealEntry>): void {
    const mealIndex = this.meals.findIndex(meal => meal.id === mealId);
    if (mealIndex !== -1) {
      this.meals[mealIndex] = { ...this.meals[mealIndex], ...updates };
      this.saveToStorage();
    }
  }

  deleteMealEntry(mealId: string): void {
    this.meals = this.meals.filter(meal => meal.id !== mealId);
    this.saveToStorage();
  }

  getDailyNutrition(date: Date = new Date()): DailyNutrition {
    const dateStr = date.toDateString();
    const dailyMeals = this.meals.filter(meal =>
      new Date(meal.date).toDateString() === dateStr
    );

    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;
    let totalFiber = 0;

    dailyMeals.forEach(meal => {
      const food = this.findFood(meal.foodId);
      if (food) {
        const multiplier = meal.amount / 100; // Convert to per-serving
        totalCalories += food.calories * multiplier;
        totalProtein += food.protein * multiplier;
        totalCarbs += food.carbs * multiplier;
        totalFat += food.fat * multiplier;
        totalFiber += (food.fiber || 0) * multiplier;
      }
    });

    return {
      date,
      calories: Math.round(totalCalories),
      protein: Math.round(totalProtein),
      carbs: Math.round(totalCarbs),
      fat: Math.round(totalFat),
      fiber: Math.round(totalFiber),
      meals: dailyMeals
    };
  }

  getMealsByType(date: Date, mealType: MealEntry['mealType']): MealEntry[] {
    const dateStr = date.toDateString();
    return this.meals.filter(meal =>
      new Date(meal.date).toDateString() === dateStr && meal.mealType === mealType
    );
  }

  setNutritionGoals(goals: Partial<NutritionGoals>): void {
    this.goals = { ...this.goals, ...goals };
    this.saveToStorage();
  }

  getNutritionGoals(): NutritionGoals {
    return this.goals;
  }

  findFood(foodId: string): Food | undefined {
    return foodDatabase.find(food => food.id === foodId);
  }

  searchFoods(query: string): Food[] {
    const lowerQuery = query.toLowerCase();
    return foodDatabase.filter(food =>
      food.name.toLowerCase().includes(lowerQuery) ||
      food.brand?.toLowerCase().includes(lowerQuery) ||
      food.category.toLowerCase().includes(lowerQuery)
    );
  }

  scanBarcode(barcode: string): Food | undefined {
    return foodDatabase.find(food => food.barcode === barcode);
  }

  addFoodToDatabase(food: Food): void {
    // This would normally add to a persistent database
    // For demo, we'll just add to the runtime array
    (foodDatabase as any).push(food);
  }

  calculateMacroPercentages(nutrition: DailyNutrition): { protein: number; carbs: number; fat: number } {
    const totalCalories = nutrition.calories || 1; // Avoid division by zero

    return {
      protein: Math.round((nutrition.protein * 4 / totalCalories) * 100),
      carbs: Math.round((nutrition.carbs * 4 / totalCalories) * 100),
      fat: Math.round((nutrition.fat * 9 / totalCalories) * 100)
    };
  }

  getWeeklyAverages(): {
    avgCalories: number;
    avgProtein: number;
    avgCarbs: number;
    avgFat: number;
  } {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    const weeklyData = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date(weekAgo);
      date.setDate(date.getDate() + i);
      weeklyData.push(this.getDailyNutrition(date));
    }

    const totals = weeklyData.reduce((acc, day) => ({
      calories: acc.calories + day.calories,
      protein: acc.protein + day.protein,
      carbs: acc.carbs + day.carbs,
      fat: acc.fat + day.fat
    }), { calories: 0, protein: 0, carbs: 0, fat: 0 });

    return {
      avgCalories: Math.round(totals.calories / 7),
      avgProtein: Math.round(totals.protein / 7),
      avgCarbs: Math.round(totals.carbs / 7),
      avgFat: Math.round(totals.fat / 7)
    };
  }
}

export const nutritionTracker = new NutritionTracker();
