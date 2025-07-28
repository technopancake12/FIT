export interface Recipe {
  id: string;
  name: string;
  description: string;
  category: 'breakfast' | 'lunch' | 'dinner' | 'snack' | 'dessert' | 'smoothie';
  cuisine: string;
  difficulty: 'Easy' | 'Medium' | 'Hard';
  prepTime: number; // minutes
  cookTime: number; // minutes
  totalTime: number; // minutes
  servings: number;

  // Nutrition per serving
  nutrition: {
    calories: number;
    protein: number;
    carbs: number;
    fat: number;
    fiber: number;
    sugar: number;
    sodium: number;
  };

  // Recipe details
  ingredients: Ingredient[];
  instructions: string[];
  equipment: string[];

  // Media
  imageUrl?: string;
  videoUrl?: string;

  // Metadata
  tags: string[];
  dietaryTags: DietaryTag[];
  author: string;
  rating: number;
  ratings: number[];
  reviews: Review[];
  createdAt: Date;

  // Customization
  variations: RecipeVariation[];
  tips: string[];
  notes?: string;
}

export interface Ingredient {
  id: string;
  name: string;
  amount: number;
  unit: string;
  notes?: string;
  optional?: boolean;
  substitutes?: string[];
}

export interface RecipeVariation {
  id: string;
  name: string;
  description: string;
  ingredientChanges: {
    ingredientId: string;
    newAmount?: number;
    substitute?: string;
  }[];
  nutritionChanges: Partial<Recipe['nutrition']>;
}

export interface Review {
  id: string;
  userId: string;
  username: string;
  rating: number;
  comment: string;
  createdAt: Date;
  helpful: number;
  photos?: string[];
}

export type DietaryTag =
  | 'vegetarian'
  | 'vegan'
  | 'gluten-free'
  | 'dairy-free'
  | 'low-carb'
  | 'keto'
  | 'paleo'
  | 'high-protein'
  | 'low-sodium'
  | 'sugar-free';

export interface MealPlan {
  id: string;
  name: string;
  description: string;
  duration: number; // days
  startDate: Date;
  endDate: Date;

  // Goals
  nutritionGoals: {
    calories: number;
    protein: number;
    carbs: number;
    fat: number;
    fiber: number;
  };

  // Constraints
  dietaryRestrictions: DietaryTag[];
  excludedIngredients: string[];
  preferredCuisines: string[];
  cookingTime: 'quick' | 'moderate' | 'any'; // max cooking time preference

  // Plan structure
  meals: {
    [day: number]: {
      breakfast?: string; // recipe ID
      lunch?: string;
      dinner?: string;
      snacks: string[];
    };
  };

  // Shopping
  shoppingList: ShoppingListItem[];
  estimatedCost: number;

  // Metadata
  createdBy: string;
  createdAt: Date;
  isTemplate: boolean;
  followers: number;
  tags: string[];
}

export interface ShoppingListItem {
  ingredientName: string;
  totalAmount: number;
  unit: string;
  category: 'produce' | 'meat' | 'dairy' | 'pantry' | 'frozen' | 'other';
  estimated_cost: number;
  purchased: boolean;
  notes?: string;
}

export interface NutritionTarget {
  goal: 'weight_loss' | 'muscle_gain' | 'maintenance' | 'performance';
  activityLevel: 'sedentary' | 'light' | 'moderate' | 'very_active' | 'extremely_active';
  bodyWeight: number; // kg
  bodyFat?: number; // percentage
  age: number;
  gender: 'male' | 'female';
  height: number; // cm
}

export interface MealPlanTemplate {
  id: string;
  name: string;
  description: string;
  goal: string;
  duration: number;
  difficulty: string;
  features: string[];
  sampleDay: {
    breakfast: string;
    lunch: string;
    dinner: string;
    snacks: string[];
  };
  estimatedCost: number;
  rating: number;
}

export class MealPlanningManager {
  private recipes: Recipe[] = [];
  private mealPlans: MealPlan[] = [];
  private templates: MealPlanTemplate[] = [];
  private currentUserId: string = 'user_1';

  constructor() {
    this.loadFromStorage();
    this.initializeData();
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const recipes = localStorage.getItem('recipes');
      const mealPlans = localStorage.getItem('meal_plans');

      if (recipes) {
        this.recipes = JSON.parse(recipes).map((r: any) => ({
          ...r,
          createdAt: new Date(r.createdAt),
          reviews: r.reviews?.map((rev: any) => ({
            ...rev,
            createdAt: new Date(rev.createdAt)
          })) || []
        }));
      }

      if (mealPlans) {
        this.mealPlans = JSON.parse(mealPlans).map((mp: any) => ({
          ...mp,
          startDate: new Date(mp.startDate),
          endDate: new Date(mp.endDate),
          createdAt: new Date(mp.createdAt)
        }));
      }
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('recipes', JSON.stringify(this.recipes));
      localStorage.setItem('meal_plans', JSON.stringify(this.mealPlans));
    }
  }

  private initializeData(): void {
    if (this.recipes.length === 0) {
      // Initialize sample recipes
      this.recipes = [
        {
          id: 'recipe_1',
          name: 'High-Protein Overnight Oats',
          description: 'Perfect post-workout breakfast packed with protein and complex carbs',
          category: 'breakfast',
          cuisine: 'American',
          difficulty: 'Easy',
          prepTime: 5,
          cookTime: 0,
          totalTime: 5,
          servings: 1,
          nutrition: {
            calories: 420,
            protein: 25,
            carbs: 45,
            fat: 12,
            fiber: 8,
            sugar: 15,
            sodium: 150
          },
          ingredients: [
            { id: 'ing_1', name: 'Rolled oats', amount: 0.5, unit: 'cup' },
            { id: 'ing_2', name: 'Greek yogurt', amount: 0.5, unit: 'cup' },
            { id: 'ing_3', name: 'Protein powder', amount: 1, unit: 'scoop' },
            { id: 'ing_4', name: 'Almond milk', amount: 0.5, unit: 'cup' },
            { id: 'ing_5', name: 'Chia seeds', amount: 1, unit: 'tbsp' },
            { id: 'ing_6', name: 'Banana', amount: 0.5, unit: 'medium' },
            { id: 'ing_7', name: 'Honey', amount: 1, unit: 'tsp', optional: true }
          ],
          instructions: [
            'In a jar or container, mix oats, protein powder, and chia seeds',
            'Add Greek yogurt and almond milk, stir well',
            'Slice banana and add to mixture',
            'Add honey if desired for extra sweetness',
            'Stir everything together until well combined',
            'Cover and refrigerate overnight',
            'Enjoy cold in the morning or let sit at room temperature for 10 minutes'
          ],
          equipment: ['Jar or container', 'Measuring cups', 'Spoon'],
          imageUrl: 'https://sample-images.com/overnight-oats.jpg',
          tags: ['high-protein', 'make-ahead', 'post-workout', 'breakfast'],
          dietaryTags: ['vegetarian', 'gluten-free'],
          author: 'FitTracker Nutrition Team',
          rating: 4.8,
          ratings: [5, 5, 4, 5, 5, 4, 5],
          reviews: [
            {
              id: 'review_1',
              userId: 'user_2',
              username: 'mikefitness',
              rating: 5,
              comment: 'Perfect post-workout meal! Keeps me full for hours.',
              createdAt: new Date('2024-01-20'),
              helpful: 3
            }
          ],
          createdAt: new Date('2024-01-15'),
          variations: [
            {
              id: 'var_1',
              name: 'Chocolate Peanut Butter',
              description: 'Add cocoa powder and peanut butter for a treat',
              ingredientChanges: [
                { ingredientId: 'ing_7', substitute: '1 tbsp peanut butter + 1 tsp cocoa powder' }
              ],
              nutritionChanges: { calories: 480, fat: 18 }
            }
          ],
          tips: [
            'Use frozen berries for a thicker consistency',
            'Add nuts for extra crunch and healthy fats',
            'Make multiple jars for the week'
          ]
        },
        {
          id: 'recipe_2',
          name: 'Lean Chicken Power Bowl',
          description: 'Balanced lunch bowl with lean protein, complex carbs, and healthy fats',
          category: 'lunch',
          cuisine: 'Mediterranean',
          difficulty: 'Medium',
          prepTime: 15,
          cookTime: 20,
          totalTime: 35,
          servings: 2,
          nutrition: {
            calories: 520,
            protein: 40,
            carbs: 35,
            fat: 22,
            fiber: 8,
            sugar: 6,
            sodium: 380
          },
          ingredients: [
            { id: 'ing_8', name: 'Chicken breast', amount: 300, unit: 'g' },
            { id: 'ing_9', name: 'Quinoa', amount: 1, unit: 'cup' },
            { id: 'ing_10', name: 'Cherry tomatoes', amount: 200, unit: 'g' },
            { id: 'ing_11', name: 'Cucumber', amount: 1, unit: 'medium' },
            { id: 'ing_12', name: 'Avocado', amount: 1, unit: 'medium' },
            { id: 'ing_13', name: 'Olive oil', amount: 2, unit: 'tbsp' },
            { id: 'ing_14', name: 'Lemon juice', amount: 2, unit: 'tbsp' },
            { id: 'ing_15', name: 'Mixed greens', amount: 2, unit: 'cups' }
          ],
          instructions: [
            'Cook quinoa according to package instructions',
            'Season chicken breast with salt, pepper, and herbs',
            'Heat 1 tbsp olive oil in a pan over medium-high heat',
            'Cook chicken for 6-7 minutes per side until done',
            'Let chicken rest for 5 minutes, then slice',
            'Dice cucumber and halve cherry tomatoes',
            'Slice avocado',
            'Make dressing with remaining olive oil and lemon juice',
            'Arrange quinoa, greens, and vegetables in bowls',
            'Top with sliced chicken and drizzle with dressing'
          ],
          equipment: ['Large pan', 'Saucepan', 'Knife', 'Cutting board'],
          imageUrl: 'https://sample-images.com/chicken-bowl.jpg',
          tags: ['high-protein', 'balanced', 'meal-prep', 'mediterranean'],
          dietaryTags: ['gluten-free', 'dairy-free'],
          author: 'Chef Maria Rodriguez',
          rating: 4.7,
          ratings: [5, 4, 5, 5, 4, 5],
          reviews: [],
          createdAt: new Date('2024-01-18'),
          variations: [
            {
              id: 'var_2',
              name: 'Salmon Version',
              description: 'Replace chicken with salmon for omega-3s',
              ingredientChanges: [
                { ingredientId: 'ing_8', substitute: '300g salmon fillet' }
              ],
              nutritionChanges: { fat: 28, calories: 560 }
            }
          ],
          tips: [
            'Prep ingredients ahead for quick assembly',
            'Double the quinoa and use leftovers',
            'Add feta cheese for extra flavor'
          ]
        },
        {
          id: 'recipe_3',
          name: 'Post-Workout Protein Smoothie',
          description: 'Quick and delicious smoothie to refuel after training',
          category: 'smoothie',
          cuisine: 'American',
          difficulty: 'Easy',
          prepTime: 3,
          cookTime: 0,
          totalTime: 3,
          servings: 1,
          nutrition: {
            calories: 285,
            protein: 28,
            carbs: 32,
            fat: 6,
            fiber: 5,
            sugar: 24,
            sodium: 120
          },
          ingredients: [
            { id: 'ing_16', name: 'Protein powder', amount: 1, unit: 'scoop' },
            { id: 'ing_17', name: 'Banana', amount: 1, unit: 'medium' },
            { id: 'ing_18', name: 'Spinach', amount: 1, unit: 'cup' },
            { id: 'ing_19', name: 'Almond milk', amount: 1, unit: 'cup' },
            { id: 'ing_20', name: 'Frozen berries', amount: 0.5, unit: 'cup' },
            { id: 'ing_21', name: 'Almond butter', amount: 1, unit: 'tbsp' }
          ],
          instructions: [
            'Add all ingredients to blender',
            'Blend on high for 60-90 seconds until smooth',
            'Add ice if thicker consistency desired',
            'Pour into glass and enjoy immediately'
          ],
          equipment: ['Blender', 'Measuring cups'],
          imageUrl: 'https://sample-images.com/protein-smoothie.jpg',
          tags: ['post-workout', 'quick', 'high-protein', 'smoothie'],
          dietaryTags: ['vegetarian', 'dairy-free', 'gluten-free'],
          author: 'FitTracker Nutrition Team',
          rating: 4.9,
          ratings: [5, 5, 5, 4, 5, 5, 5],
          reviews: [],
          createdAt: new Date('2024-01-22'),
          variations: [
            {
              id: 'var_3',
              name: 'Chocolate Version',
              description: 'Add cocoa powder for chocolate flavor',
              ingredientChanges: [
                { ingredientId: 'ing_21', substitute: '1 tbsp cocoa powder + 1 tsp honey' }
              ],
              nutritionChanges: { calories: 270, fat: 4 }
            }
          ],
          tips: [
            'Freeze bananas for thicker texture',
            'Add more liquid if too thick',
            'Use fresh spinach for best taste'
          ]
        }
      ];

      // Initialize meal plan templates
      this.templates = [
        {
          id: 'template_1',
          name: 'Muscle Building Plan',
          description: 'High-protein meal plan designed for muscle growth and recovery',
          goal: 'Muscle Gain',
          duration: 7,
          difficulty: 'Medium',
          features: ['High protein', 'Balanced macros', 'Post-workout meals'],
          sampleDay: {
            breakfast: 'High-Protein Overnight Oats',
            lunch: 'Lean Chicken Power Bowl',
            dinner: 'Grilled Salmon with Sweet Potato',
            snacks: ['Post-Workout Protein Smoothie', 'Greek Yogurt with Berries']
          },
          estimatedCost: 85,
          rating: 4.7
        },
        {
          id: 'template_2',
          name: 'Weight Loss Plan',
          description: 'Calorie-controlled plan with satisfying, nutrient-dense meals',
          goal: 'Weight Loss',
          duration: 14,
          difficulty: 'Easy',
          features: ['Calorie controlled', 'High fiber', 'Filling meals'],
          sampleDay: {
            breakfast: 'Veggie Egg White Scramble',
            lunch: 'Quinoa Salad with Grilled Chicken',
            dinner: 'Baked Fish with Roasted Vegetables',
            snacks: ['Apple with Almond Butter', 'Cucumber Slices']
          },
          estimatedCost: 65,
          rating: 4.5
        }
      ];

      this.saveToStorage();
    }
  }

  // Recipe management
  getRecipes(): Recipe[] {
    return this.recipes.sort((a, b) => b.rating - a.rating);
  }

  getRecipe(id: string): Recipe | undefined {
    return this.recipes.find(r => r.id === id);
  }

  getRecipesByCategory(category: Recipe['category']): Recipe[] {
    return this.recipes.filter(r => r.category === category);
  }

  searchRecipes(query: string): Recipe[] {
    const lowerQuery = query.toLowerCase();
    return this.recipes.filter(recipe =>
      recipe.name.toLowerCase().includes(lowerQuery) ||
      recipe.description.toLowerCase().includes(lowerQuery) ||
      recipe.tags.some(tag => tag.toLowerCase().includes(lowerQuery)) ||
      recipe.ingredients.some(ing => ing.name.toLowerCase().includes(lowerQuery))
    );
  }

  filterRecipes(filters: {
    category?: Recipe['category'][];
    dietary?: DietaryTag[];
    difficulty?: Recipe['difficulty'][];
    cookTime?: { max: number };
    cuisine?: string[];
    calories?: { min?: number; max?: number };
    protein?: { min?: number };
  }): Recipe[] {
    return this.recipes.filter(recipe => {
      if (filters.category && !filters.category.includes(recipe.category)) return false;

      if (filters.dietary && filters.dietary.length > 0) {
        const hasAllDietaryTags = filters.dietary.every(tag =>
          recipe.dietaryTags.includes(tag)
        );
        if (!hasAllDietaryTags) return false;
      }

      if (filters.difficulty && !filters.difficulty.includes(recipe.difficulty)) return false;

      if (filters.cookTime && recipe.totalTime > filters.cookTime.max) return false;

      if (filters.cuisine && !filters.cuisine.includes(recipe.cuisine)) return false;

      if (filters.calories) {
        if (filters.calories.min && recipe.nutrition.calories < filters.calories.min) return false;
        if (filters.calories.max && recipe.nutrition.calories > filters.calories.max) return false;
      }

      if (filters.protein?.min && recipe.nutrition.protein < filters.protein.min) return false;

      return true;
    });
  }

  // Meal plan generation
  generateMealPlan(
    duration: number,
    nutritionTarget: NutritionTarget,
    preferences: {
      dietaryRestrictions: DietaryTag[];
      excludedIngredients: string[];
      preferredCuisines: string[];
      cookingTime: 'quick' | 'moderate' | 'any';
    }
  ): MealPlan {
    // Calculate nutrition goals based on target
    const nutritionGoals = this.calculateNutritionGoals(nutritionTarget);

    // Filter recipes based on preferences
    const availableRecipes = this.filterRecipes({
      dietary: preferences.dietaryRestrictions,
      cookTime: preferences.cookingTime === 'quick' ? { max: 30 } :
                preferences.cookingTime === 'moderate' ? { max: 60 } : undefined,
      cuisine: preferences.preferredCuisines.length > 0 ? preferences.preferredCuisines : undefined
    });

    // Generate meals for each day
    const meals: MealPlan['meals'] = {};

    for (let day = 1; day <= duration; day++) {
      meals[day] = {
        breakfast: this.selectRecipe(availableRecipes, 'breakfast')?.id,
        lunch: this.selectRecipe(availableRecipes, 'lunch')?.id,
        dinner: this.selectRecipe(availableRecipes, 'dinner')?.id,
        snacks: [
          this.selectRecipe(availableRecipes, 'snack')?.id,
          this.selectRecipe(availableRecipes, 'smoothie')?.id
        ].filter(Boolean) as string[]
      };
    }

    // Generate shopping list
    const shoppingList = this.generateShoppingList(meals, duration);

    const mealPlan: MealPlan = {
      id: `meal_plan_${Date.now()}`,
      name: `${duration}-Day ${nutritionTarget.goal} Plan`,
      description: `Personalized meal plan for ${nutritionTarget.goal.replace('_', ' ')}`,
      duration,
      startDate: new Date(),
      endDate: new Date(Date.now() + duration * 24 * 60 * 60 * 1000),
      nutritionGoals,
      dietaryRestrictions: preferences.dietaryRestrictions,
      excludedIngredients: preferences.excludedIngredients,
      preferredCuisines: preferences.preferredCuisines,
      cookingTime: preferences.cookingTime,
      meals,
      shoppingList,
      estimatedCost: this.calculateEstimatedCost(shoppingList),
      createdBy: this.currentUserId,
      createdAt: new Date(),
      isTemplate: false,
      followers: 0,
      tags: [nutritionTarget.goal, ...preferences.dietaryRestrictions]
    };

    this.mealPlans.push(mealPlan);
    this.saveToStorage();
    return mealPlan;
  }

  private calculateNutritionGoals(target: NutritionTarget): MealPlan['nutritionGoals'] {
    // Simplified BMR calculation (Mifflin-St Jeor Equation)
    let bmr: number;
    if (target.gender === 'male') {
      bmr = (10 * target.bodyWeight) + (6.25 * target.height) - (5 * target.age) + 5;
    } else {
      bmr = (10 * target.bodyWeight) + (6.25 * target.height) - (5 * target.age) - 161;
    }

    // Activity multipliers
    const activityMultipliers = {
      sedentary: 1.2,
      light: 1.375,
      moderate: 1.55,
      very_active: 1.725,
      extremely_active: 1.9
    };

    const tdee = bmr * activityMultipliers[target.activityLevel];

    // Adjust calories based on goal
    let calories: number;
    switch (target.goal) {
      case 'weight_loss':
        calories = tdee - 500; // 1 lb per week deficit
        break;
      case 'muscle_gain':
        calories = tdee + 300; // Moderate surplus
        break;
      case 'performance':
        calories = tdee + 200;
        break;
      default:
        calories = tdee;
    }

    // Calculate macros
    let proteinRatio: number;
    let fatRatio: number;
    let carbRatio: number;

    switch (target.goal) {
      case 'muscle_gain':
        proteinRatio = 0.30;
        fatRatio = 0.25;
        carbRatio = 0.45;
        break;
      case 'weight_loss':
        proteinRatio = 0.35;
        fatRatio = 0.30;
        carbRatio = 0.35;
        break;
      default:
        proteinRatio = 0.25;
        fatRatio = 0.25;
        carbRatio = 0.50;
    }

    return {
      calories: Math.round(calories),
      protein: Math.round((calories * proteinRatio) / 4), // 4 cal per gram
      carbs: Math.round((calories * carbRatio) / 4),
      fat: Math.round((calories * fatRatio) / 9), // 9 cal per gram
      fiber: Math.round(calories / 100) // 1g per 100 calories
    };
  }

  private selectRecipe(recipes: Recipe[], category: Recipe['category']): Recipe | undefined {
    const categoryRecipes = recipes.filter(r => r.category === category);
    if (categoryRecipes.length === 0) return undefined;

    // Simple random selection (could be improved with variety algorithms)
    return categoryRecipes[Math.floor(Math.random() * categoryRecipes.length)];
  }

  private generateShoppingList(meals: MealPlan['meals'], duration: number): ShoppingListItem[] {
    const ingredientMap = new Map<string, { amount: number; unit: string; category: string }>();

    // Collect all ingredients
    Object.values(meals).forEach(dayMeals => {
      [dayMeals.breakfast, dayMeals.lunch, dayMeals.dinner, ...dayMeals.snacks]
        .filter(Boolean)
        .forEach(recipeId => {
          const recipe = this.getRecipe(recipeId as string);
          if (recipe) {
            recipe.ingredients.forEach(ingredient => {
              const key = ingredient.name.toLowerCase();
              const existing = ingredientMap.get(key);

              if (existing) {
                // Combine amounts (assuming same unit for simplicity)
                existing.amount += ingredient.amount;
              } else {
                ingredientMap.set(key, {
                  amount: ingredient.amount,
                  unit: ingredient.unit,
                  category: this.categorizeIngredient(ingredient.name)
                });
              }
            });
          }
        });
    });

    // Convert to shopping list items
    return Array.from(ingredientMap.entries()).map(([name, details]) => ({
      ingredientName: name,
      totalAmount: Math.round(details.amount * 100) / 100,
      unit: details.unit,
      category: details.category as ShoppingListItem['category'],
      estimated_cost: this.estimateIngredientCost(name, details.amount),
      purchased: false
    }));
  }

  private categorizeIngredient(name: string): string {
    const categories = {
      produce: ['banana', 'apple', 'spinach', 'broccoli', 'cucumber', 'tomato', 'avocado', 'berries'],
      meat: ['chicken', 'salmon', 'beef', 'fish', 'turkey'],
      dairy: ['milk', 'yogurt', 'cheese', 'eggs'],
      pantry: ['oats', 'quinoa', 'rice', 'oil', 'honey', 'protein powder', 'nuts', 'seeds'],
      frozen: ['frozen berries', 'frozen vegetables']
    };

    const lowerName = name.toLowerCase();

    for (const [category, items] of Object.entries(categories)) {
      if (items.some(item => lowerName.includes(item))) {
        return category;
      }
    }

    return 'other';
  }

  private estimateIngredientCost(name: string, amount: number): number {
    // Simplified cost estimation
    const baseCosts: { [key: string]: number } = {
      'chicken': 8, 'salmon': 12, 'beef': 10,
      'banana': 2, 'apple': 3, 'spinach': 4,
      'oats': 3, 'quinoa': 6, 'rice': 2,
      'milk': 3, 'yogurt': 5, 'eggs': 4
    };

    const lowerName = name.toLowerCase();
    const baseCost = Object.entries(baseCosts).find(([key]) =>
      lowerName.includes(key)
    )?.[1] || 3;

    return Math.round(baseCost * (amount / 100) * 100) / 100;
  }

  private calculateEstimatedCost(shoppingList: ShoppingListItem[]): number {
    return Math.round(shoppingList.reduce((sum, item) => sum + item.estimated_cost, 0));
  }

  // Meal plan management
  getMealPlans(): MealPlan[] {
    return this.mealPlans.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  getUserMealPlans(): MealPlan[] {
    return this.mealPlans.filter(mp => mp.createdBy === this.currentUserId);
  }

  getMealPlan(id: string): MealPlan | undefined {
    return this.mealPlans.find(mp => mp.id === id);
  }

  getTemplates(): MealPlanTemplate[] {
    return this.templates.sort((a, b) => b.rating - a.rating);
  }

  // Shopping list management
  toggleShoppingListItem(mealPlanId: string, ingredientName: string): boolean {
    const mealPlan = this.getMealPlan(mealPlanId);
    if (!mealPlan) return false;

    const item = mealPlan.shoppingList.find(item => item.ingredientName === ingredientName);
    if (item) {
      item.purchased = !item.purchased;
      this.saveToStorage();
      return item.purchased;
    }

    return false;
  }

  addShoppingListNote(mealPlanId: string, ingredientName: string, note: string): boolean {
    const mealPlan = this.getMealPlan(mealPlanId);
    if (!mealPlan) return false;

    const item = mealPlan.shoppingList.find(item => item.ingredientName === ingredientName);
    if (item) {
      item.notes = note;
      this.saveToStorage();
      return true;
    }

    return false;
  }

  // Recipe reviews and ratings
  addRecipeReview(recipeId: string, rating: number, comment: string): boolean {
    const recipe = this.getRecipe(recipeId);
    if (!recipe) return false;

    const review: Review = {
      id: `review_${Date.now()}`,
      userId: this.currentUserId,
      username: 'you',
      rating,
      comment,
      createdAt: new Date(),
      helpful: 0
    };

    recipe.reviews.push(review);
    recipe.ratings.push(rating);
    recipe.rating = recipe.ratings.reduce((sum, r) => sum + r, 0) / recipe.ratings.length;

    this.saveToStorage();
    return true;
  }

  // Nutrition analysis
  analyzeMealPlan(mealPlanId: string): {
    dailyAverages: MealPlan['nutritionGoals'];
    weeklyTotals: MealPlan['nutritionGoals'];
    goalComparison: { [key: string]: number }; // percentage of goal met
    recommendations: string[];
  } {
    const mealPlan = this.getMealPlan(mealPlanId);
    if (!mealPlan) {
      throw new Error('Meal plan not found');
    }

    let totalNutrition = { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0 };
    let daysWithMeals = 0;

    // Calculate totals
    Object.values(mealPlan.meals).forEach(dayMeals => {
      let dayNutrition = { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0 };

      [dayMeals.breakfast, dayMeals.lunch, dayMeals.dinner, ...dayMeals.snacks]
        .filter(Boolean)
        .forEach(recipeId => {
          const recipe = this.getRecipe(recipeId as string);
          if (recipe) {
            dayNutrition.calories += recipe.nutrition.calories;
            dayNutrition.protein += recipe.nutrition.protein;
            dayNutrition.carbs += recipe.nutrition.carbs;
            dayNutrition.fat += recipe.nutrition.fat;
            dayNutrition.fiber += recipe.nutrition.fiber;
          }
        });

      if (dayNutrition.calories > 0) {
        totalNutrition.calories += dayNutrition.calories;
        totalNutrition.protein += dayNutrition.protein;
        totalNutrition.carbs += dayNutrition.carbs;
        totalNutrition.fat += dayNutrition.fat;
        totalNutrition.fiber += dayNutrition.fiber;
        daysWithMeals++;
      }
    });

    const dailyAverages = {
      calories: Math.round(totalNutrition.calories / daysWithMeals),
      protein: Math.round(totalNutrition.protein / daysWithMeals),
      carbs: Math.round(totalNutrition.carbs / daysWithMeals),
      fat: Math.round(totalNutrition.fat / daysWithMeals),
      fiber: Math.round(totalNutrition.fiber / daysWithMeals)
    };

    const goalComparison = {
      calories: Math.round((dailyAverages.calories / mealPlan.nutritionGoals.calories) * 100),
      protein: Math.round((dailyAverages.protein / mealPlan.nutritionGoals.protein) * 100),
      carbs: Math.round((dailyAverages.carbs / mealPlan.nutritionGoals.carbs) * 100),
      fat: Math.round((dailyAverages.fat / mealPlan.nutritionGoals.fat) * 100),
      fiber: Math.round((dailyAverages.fiber / mealPlan.nutritionGoals.fiber) * 100)
    };

    // Generate recommendations
    const recommendations: string[] = [];

    if (goalComparison.protein < 85) {
      recommendations.push('Consider adding more protein-rich foods to meet your protein goals');
    }

    if (goalComparison.fiber < 80) {
      recommendations.push('Add more fruits, vegetables, and whole grains for better fiber intake');
    }

    if (goalComparison.calories < 85) {
      recommendations.push('You may need more calories to support your fitness goals');
    } else if (goalComparison.calories > 110) {
      recommendations.push('Consider reducing portion sizes to stay within calorie goals');
    }

    return {
      dailyAverages,
      weeklyTotals: totalNutrition,
      goalComparison,
      recommendations
    };
  }
}

export const mealPlanningManager = new MealPlanningManager();
