"use client";

import { useState, useMemo } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Separator } from "@/components/ui/separator";
import { Search, Filter, Plus, Info } from "lucide-react";
import { exerciseDatabase, Exercise, MUSCLE_GROUPS, EQUIPMENT_TYPES, searchExercises, getExercisesByMuscleGroup, getExercisesByEquipment } from "@/lib/exercises";

interface ExerciseSearchProps {
  onSelectExercise: (exercise: Exercise) => void;
  selectedExercises?: string[];
}

export function ExerciseSearch({ onSelectExercise, selectedExercises = [] }: ExerciseSearchProps) {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedMuscleGroup, setSelectedMuscleGroup] = useState<string>("all");
  const [selectedEquipment, setSelectedEquipment] = useState<string>("all");
  const [selectedDifficulty, setSelectedDifficulty] = useState<string>("all");

  const filteredExercises = useMemo(() => {
    let exercises = exerciseDatabase;

    // Search filter
    if (searchQuery) {
      exercises = searchExercises(searchQuery);
    }

    // Muscle group filter
    if (selectedMuscleGroup !== "all") {
      exercises = exercises.filter(ex =>
        ex.primaryMuscles.includes(selectedMuscleGroup) ||
        ex.secondaryMuscles.includes(selectedMuscleGroup)
      );
    }

    // Equipment filter
    if (selectedEquipment !== "all") {
      exercises = exercises.filter(ex => ex.equipment === selectedEquipment);
    }

    // Difficulty filter
    if (selectedDifficulty !== "all") {
      exercises = exercises.filter(ex => ex.difficulty === selectedDifficulty);
    }

    return exercises;
  }, [searchQuery, selectedMuscleGroup, selectedEquipment, selectedDifficulty]);

  const clearFilters = () => {
    setSearchQuery("");
    setSelectedMuscleGroup("all");
    setSelectedEquipment("all");
    setSelectedDifficulty("all");
  };

  return (
    <div className="space-y-4">
      {/* Search and Filters */}
      <div className="space-y-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search exercises..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>

        <div className="grid grid-cols-2 gap-2">
          <Select value={selectedMuscleGroup} onValueChange={setSelectedMuscleGroup}>
            <SelectTrigger>
              <SelectValue placeholder="Muscle Group" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Muscles</SelectItem>
              {MUSCLE_GROUPS.map(muscle => (
                <SelectItem key={muscle} value={muscle}>{muscle}</SelectItem>
              ))}
            </SelectContent>
          </Select>

          <Select value={selectedEquipment} onValueChange={setSelectedEquipment}>
            <SelectTrigger>
              <SelectValue placeholder="Equipment" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Equipment</SelectItem>
              {EQUIPMENT_TYPES.map(equipment => (
                <SelectItem key={equipment} value={equipment}>{equipment}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="flex gap-2">
          <Select value={selectedDifficulty} onValueChange={setSelectedDifficulty}>
            <SelectTrigger className="flex-1">
              <SelectValue placeholder="Difficulty" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Levels</SelectItem>
              <SelectItem value="Beginner">Beginner</SelectItem>
              <SelectItem value="Intermediate">Intermediate</SelectItem>
              <SelectItem value="Advanced">Advanced</SelectItem>
            </SelectContent>
          </Select>

          <Button variant="outline" onClick={clearFilters}>
            <Filter className="h-4 w-4 mr-2" />
            Clear
          </Button>
        </div>
      </div>

      <Separator />

      {/* Exercise Results */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-sm text-muted-foreground">
            {filteredExercises.length} exercises found
          </span>
        </div>

        <div className="space-y-2 max-h-96 overflow-y-auto">
          {filteredExercises.map((exercise) => (
            <ExerciseCard
              key={exercise.id}
              exercise={exercise}
              onSelect={() => onSelectExercise(exercise)}
              isSelected={selectedExercises.includes(exercise.id)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

interface ExerciseCardProps {
  exercise: Exercise;
  onSelect: () => void;
  isSelected: boolean;
}

function ExerciseCard({ exercise, onSelect, isSelected }: ExerciseCardProps) {
  return (
    <Card className={isSelected ? "border-primary" : ""}>
      <CardContent className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-2">
              <h4 className="font-medium">{exercise.name}</h4>
              <Badge variant={
                exercise.difficulty === 'Beginner' ? 'secondary' :
                exercise.difficulty === 'Intermediate' ? 'default' : 'destructive'
              }>
                {exercise.difficulty}
              </Badge>
            </div>

            <div className="flex flex-wrap gap-1 mb-2">
              {exercise.primaryMuscles.map(muscle => (
                <Badge key={muscle} variant="outline" className="text-xs">
                  {muscle}
                </Badge>
              ))}
            </div>

            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">{exercise.equipment}</span>

              <div className="flex gap-2">
                <Dialog>
                  <DialogTrigger asChild>
                    <Button variant="ghost" size="sm">
                      <Info className="h-4 w-4" />
                    </Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>{exercise.name}</DialogTitle>
                      <DialogDescription>
                        {exercise.equipment} • {exercise.difficulty}
                      </DialogDescription>
                    </DialogHeader>
                    <ExerciseDetails exercise={exercise} />
                  </DialogContent>
                </Dialog>

                <Button
                  size="sm"
                  onClick={onSelect}
                  variant={isSelected ? "secondary" : "default"}
                >
                  {isSelected ? "Added" : <Plus className="h-4 w-4" />}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function ExerciseDetails({ exercise }: { exercise: Exercise }) {
  return (
    <div className="space-y-4">
      <div>
        <h4 className="font-medium mb-2">Target Muscles</h4>
        <div className="flex flex-wrap gap-2">
          <div>
            <span className="text-sm font-medium">Primary: </span>
            {exercise.primaryMuscles.map(muscle => (
              <Badge key={muscle} className="mr-1">{muscle}</Badge>
            ))}
          </div>
          {exercise.secondaryMuscles.length > 0 && (
            <div>
              <span className="text-sm font-medium">Secondary: </span>
              {exercise.secondaryMuscles.map(muscle => (
                <Badge key={muscle} variant="outline" className="mr-1">{muscle}</Badge>
              ))}
            </div>
          )}
        </div>
      </div>

      <div>
        <h4 className="font-medium mb-2">Instructions</h4>
        <ol className="list-decimal list-inside space-y-1 text-sm">
          {exercise.instructions.map((instruction, index) => (
            <li key={index}>{instruction}</li>
          ))}
        </ol>
      </div>

      {exercise.tips.length > 0 && (
        <div>
          <h4 className="font-medium mb-2">Tips</h4>
          <ul className="list-disc list-inside space-y-1 text-sm">
            {exercise.tips.map((tip, index) => (
              <li key={index}>{tip}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
