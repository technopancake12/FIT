"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Separator } from "@/components/ui/separator";
import {
  Search,
  Plus,
  Scan,
  Coffee,
  UtensilsCrossed,
  Cookie,
  Camera,
  Trash2,
  Target,
  TrendingUp
} from "lucide-react";
import { nutritionTracker, Food, MealEntry, DailyNutrition } from "@/lib/nutrition";
import { BarcodeScanner } from "./BarcodeScanner";

export function NutritionTracker() {
  const [dailyNutrition, setDailyNutrition] = useState<DailyNutrition | null>(null);
  const [goals, setGoals] = useState(nutritionTracker.getNutritionGoals());
  const [showFoodSearch, setShowFoodSearch] = useState(false);
  const [showBarcodeScanner, setShowBarcodeScanner] = useState(false);
  const [selectedMealType, setSelectedMealType] = useState<MealEntry['mealType']>('breakfast');

  useEffect(() => {
    const nutrition = nutritionTracker.getDailyNutrition();
    setDailyNutrition(nutrition);
  }, []);

  const refreshNutrition = () => {
    const nutrition = nutritionTracker.getDailyNutrition();
    setDailyNutrition(nutrition);
  };

  const handleAddFood = (food: Food, amount: number, mealType: MealEntry['mealType']) => {
    nutritionTracker.addMealEntry(food.id, amount, mealType);
    refreshNutrition();
    setShowFoodSearch(false);
  };

  const handleBarcodeFound = (food: Food) => {
    // For barcode scanned foods, default to 100g serving
    handleAddFood(food, 100, selectedMealType);
    setShowBarcodeScanner(false);
  };

  const handleDeleteMeal = (mealId: string) => {
    nutritionTracker.deleteMealEntry(mealId);
    refreshNutrition();
  };

  if (!dailyNutrition) return <div>Loading...</div>;

  return (
    <div className="space-y-4">
      {/* Daily Overview */}
      <MacroOverview nutrition={dailyNutrition} goals={goals} />

      {/* Add Food Button */}
      <Card>
        <CardContent className="p-4">
          <div className="flex gap-2">
            <Button
              onClick={() => setShowFoodSearch(true)}
              className="flex-1"
            >
              <Plus className="h-4 w-4 mr-2" />
              Add Food
            </Button>
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => {
                setSelectedMealType('breakfast');
                setShowBarcodeScanner(true);
              }}
            >
              <Scan className="h-4 w-4 mr-2" />
              Scan Barcode
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Meals */}
      <MealSection
        title="Breakfast"
        icon={<Coffee className="h-5 w-5" />}
        mealType="breakfast"
        meals={nutritionTracker.getMealsByType(new Date(), 'breakfast')}
        onDeleteMeal={handleDeleteMeal}
        onAddFood={() => {
          setSelectedMealType('breakfast');
          setShowFoodSearch(true);
        }}
      />

      <MealSection
        title="Lunch"
        icon={<UtensilsCrossed className="h-5 w-5" />}
        mealType="lunch"
        meals={nutritionTracker.getMealsByType(new Date(), 'lunch')}
        onDeleteMeal={handleDeleteMeal}
        onAddFood={() => {
          setSelectedMealType('lunch');
          setShowFoodSearch(true);
        }}
      />

      <MealSection
        title="Dinner"
        icon={<UtensilsCrossed className="h-5 w-5" />}
        mealType="dinner"
        meals={nutritionTracker.getMealsByType(new Date(), 'dinner')}
        onDeleteMeal={handleDeleteMeal}
        onAddFood={() => {
          setSelectedMealType('dinner');
          setShowFoodSearch(true);
        }}
      />

      <MealSection
        title="Snacks"
        icon={<Cookie className="h-5 w-5" />}
        mealType="snack"
        meals={nutritionTracker.getMealsByType(new Date(), 'snack')}
        onDeleteMeal={handleDeleteMeal}
        onAddFood={() => {
          setSelectedMealType('snack');
          setShowFoodSearch(true);
        }}
      />

      {/* Weekly Stats */}
      <WeeklyStats />

      {/* Food Search Dialog */}
      {showFoodSearch && (
        <FoodSearchDialog
          isOpen={showFoodSearch}
          onClose={() => setShowFoodSearch(false)}
          onSelectFood={(food, amount) => handleAddFood(food, amount, selectedMealType)}
          mealType={selectedMealType}
        />
      )}

      {/* Barcode Scanner */}
      <BarcodeScanner
        isOpen={showBarcodeScanner}
        onClose={() => setShowBarcodeScanner(false)}
        onFoodFound={handleBarcodeFound}
        onManualEntry={() => {
          setShowBarcodeScanner(false);
          setShowFoodSearch(true);
        }}
      />
    </div>
  );
}

interface MacroOverviewProps {
  nutrition: DailyNutrition;
  goals: {
    calories: number;
    protein: number;
    carbs: number;
    fat: number;
    fiber?: number;
  };
}

function MacroOverview({ nutrition, goals }: MacroOverviewProps) {
  const macroPercentages = nutritionTracker.calculateMacroPercentages(nutrition);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">Today's Nutrition</CardTitle>
        <CardDescription>
          {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Calories */}
        <div>
          <div className="flex justify-between text-sm mb-2">
            <span>Calories</span>
            <span>{nutrition.calories}/{goals.calories}</span>
          </div>
          <Progress value={(nutrition.calories / goals.calories) * 100} className="h-3" />
        </div>

        {/* Macros */}
        <div className="grid grid-cols-3 gap-4 text-center">
          <div>
            <p className="text-2xl font-bold text-red-500">{nutrition.protein}g</p>
            <p className="text-xs text-muted-foreground">Protein ({macroPercentages.protein}%)</p>
            <Progress value={(nutrition.protein / goals.protein) * 100} className="h-1 mt-1" />
          </div>
          <div>
            <p className="text-2xl font-bold text-yellow-500">{nutrition.carbs}g</p>
            <p className="text-xs text-muted-foreground">Carbs ({macroPercentages.carbs}%)</p>
            <Progress value={(nutrition.carbs / goals.carbs) * 100} className="h-1 mt-1" />
          </div>
          <div>
            <p className="text-2xl font-bold text-green-500">{nutrition.fat}g</p>
            <p className="text-xs text-muted-foreground">Fat ({macroPercentages.fat}%)</p>
            <Progress value={(nutrition.fat / goals.fat) * 100} className="h-1 mt-1" />
          </div>
        </div>

        {/* Fiber */}
        <div>
          <div className="flex justify-between text-sm mb-2">
            <span>Fiber</span>
            <span>{nutrition.fiber}g/{goals.fiber || 25}g</span>
          </div>
          <Progress value={(nutrition.fiber / (goals.fiber || 25)) * 100} className="h-2" />
        </div>
      </CardContent>
    </Card>
  );
}

interface MealSectionProps {
  title: string;
  icon: React.ReactNode;
  mealType: MealEntry['mealType'];
  meals: MealEntry[];
  onDeleteMeal: (mealId: string) => void;
  onAddFood: () => void;
}

function MealSection({ title, icon, meals, onDeleteMeal, onAddFood }: MealSectionProps) {
  const calculateMealNutrition = () => {
    let calories = 0;
    let protein = 0;
    let carbs = 0;
    let fat = 0;

    meals.forEach(meal => {
      const food = nutritionTracker.findFood(meal.foodId);
      if (food) {
        const multiplier = meal.amount / 100;
        calories += food.calories * multiplier;
        protein += food.protein * multiplier;
        carbs += food.carbs * multiplier;
        fat += food.fat * multiplier;
      }
    });

    return { calories: Math.round(calories), protein: Math.round(protein), carbs: Math.round(carbs), fat: Math.round(fat) };
  };

  const mealNutrition = calculateMealNutrition();

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {icon}
            <CardTitle className="text-base">{title}</CardTitle>
            {mealNutrition.calories > 0 && (
              <Badge variant="secondary">{mealNutrition.calories} cal</Badge>
            )}
          </div>
          <Button variant="outline" size="sm" onClick={onAddFood}>
            <Plus className="h-4 w-4" />
          </Button>
        </div>
      </CardHeader>

      {meals.length > 0 ? (
        <CardContent className="space-y-2">
          {meals.map(meal => (
            <MealItem
              key={meal.id}
              meal={meal}
              onDelete={() => onDeleteMeal(meal.id)}
            />
          ))}

          {mealNutrition.calories > 0 && (
            <div className="pt-2 border-t">
              <div className="flex justify-between text-sm text-muted-foreground">
                <span>Total: {mealNutrition.calories} cal</span>
                <span>P: {mealNutrition.protein}g C: {mealNutrition.carbs}g F: {mealNutrition.fat}g</span>
              </div>
            </div>
          )}
        </CardContent>
      ) : (
        <CardContent>
          <p className="text-sm text-muted-foreground text-center py-4">
            No foods logged for {title.toLowerCase()}
          </p>
        </CardContent>
      )}
    </Card>
  );
}

interface MealItemProps {
  meal: MealEntry;
  onDelete: () => void;
}

function MealItem({ meal, onDelete }: MealItemProps) {
  const food = nutritionTracker.findFood(meal.foodId);

  if (!food) return null;

  const multiplier = meal.amount / 100;
  const calories = Math.round(food.calories * multiplier);
  const protein = Math.round(food.protein * multiplier);
  const carbs = Math.round(food.carbs * multiplier);
  const fat = Math.round(food.fat * multiplier);

  return (
    <div className="flex items-center justify-between p-3 bg-muted/30 rounded">
      <div className="flex-1">
        <div className="flex items-center gap-2">
          <span className="font-medium">{food.name}</span>
          <Badge variant="outline" className="text-xs">{meal.amount}g</Badge>
        </div>
        <div className="text-sm text-muted-foreground">
          {calories} cal • P: {protein}g C: {carbs}g F: {fat}g
        </div>
      </div>
      <Button variant="ghost" size="sm" onClick={onDelete}>
        <Trash2 className="h-4 w-4" />
      </Button>
    </div>
  );
}

function WeeklyStats() {
  const [weeklyStats, setWeeklyStats] = useState({
    avgCalories: 0,
    avgProtein: 0,
    avgCarbs: 0,
    avgFat: 0
  });

  useEffect(() => {
    const stats = nutritionTracker.getWeeklyAverages();
    setWeeklyStats(stats);
  }, []);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <TrendingUp className="h-5 w-5" />
          Weekly Averages
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-4 text-center">
          <div>
            <p className="text-xl font-bold">{weeklyStats.avgCalories}</p>
            <p className="text-xs text-muted-foreground">Avg Calories</p>
          </div>
          <div>
            <p className="text-xl font-bold text-red-500">{weeklyStats.avgProtein}g</p>
            <p className="text-xs text-muted-foreground">Avg Protein</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

interface FoodSearchDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectFood: (food: Food, amount: number) => void;
  mealType: MealEntry['mealType'];
}

function FoodSearchDialog({ isOpen, onClose, onSelectFood, mealType }: FoodSearchDialogProps) {
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<Food[]>([]);
  const [selectedFood, setSelectedFood] = useState<Food | null>(null);
  const [amount, setAmount] = useState(100);

  useEffect(() => {
    if (searchQuery) {
      const results = nutritionTracker.searchFoods(searchQuery);
      setSearchResults(results);
    } else {
      setSearchResults([]);
    }
  }, [searchQuery]);

  const handleAddFood = () => {
    if (selectedFood && amount > 0) {
      onSelectFood(selectedFood, amount);
      setSelectedFood(null);
      setAmount(100);
      setSearchQuery("");
      setSearchResults([]);
    }
  };

  if (!isOpen) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md max-h-[80vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>Add Food to {mealType}</DialogTitle>
          <DialogDescription>
            Search for foods to add to your meal
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 flex-1 overflow-hidden">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search foods..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Food Selection */}
          {selectedFood ? (
            <div className="space-y-4">
              <Card>
                <CardContent className="p-4">
                  <h3 className="font-medium mb-2">{selectedFood.name}</h3>
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>Calories: {selectedFood.calories}/100g</div>
                    <div>Protein: {selectedFood.protein}g</div>
                    <div>Carbs: {selectedFood.carbs}g</div>
                    <div>Fat: {selectedFood.fat}g</div>
                  </div>
                </CardContent>
              </Card>

              <div>
                <label className="text-sm font-medium">Amount (grams)</label>
                <Input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(parseInt(e.target.value) || 0)}
                  min="1"
                  className="mt-1"
                />
              </div>

              {amount > 0 && (
                <Card className="border-green-500/20 bg-green-50/50">
                  <CardContent className="p-3">
                    <div className="text-sm">
                      <div className="font-medium mb-1">Nutrition for {amount}g:</div>
                      <div className="grid grid-cols-2 gap-1">
                        <div>Calories: {Math.round(selectedFood.calories * amount / 100)}</div>
                        <div>Protein: {Math.round(selectedFood.protein * amount / 100)}g</div>
                        <div>Carbs: {Math.round(selectedFood.carbs * amount / 100)}g</div>
                        <div>Fat: {Math.round(selectedFood.fat * amount / 100)}g</div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              )}

              <div className="flex gap-2">
                <Button variant="outline" onClick={() => setSelectedFood(null)} className="flex-1">
                  Back
                </Button>
                <Button onClick={handleAddFood} className="flex-1">
                  Add Food
                </Button>
              </div>
            </div>
          ) : (
            <div className="space-y-2 overflow-y-auto">
              {searchResults.map(food => (
                <Card key={food.id} className="cursor-pointer hover:bg-muted/50" onClick={() => setSelectedFood(food)}>
                  <CardContent className="p-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-medium">{food.name}</p>
                        <p className="text-sm text-muted-foreground">{food.category}</p>
                      </div>
                      <div className="text-right text-sm">
                        <div>{food.calories} cal</div>
                        <div className="text-muted-foreground">per 100g</div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}

              {searchQuery && searchResults.length === 0 && (
                <div className="text-center py-8 text-muted-foreground">
                  <p>No foods found</p>
                  <Button variant="outline" className="mt-2">
                    <Camera className="h-4 w-4 mr-2" />
                    Create Custom Food
                  </Button>
                </div>
              )}
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
