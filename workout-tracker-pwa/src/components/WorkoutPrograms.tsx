"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Separator } from "@/components/ui/separator";
import {
  Search,
  Star,
  Clock,
  Target,
  Trophy,
  Play,
  Calendar,
  CheckCircle,
  Settings,
  BookOpen,
  Zap
} from "lucide-react";
import { WorkoutProgram, ProgramWorkout, UserProgram, programTracker, workoutPrograms } from "@/lib/workout-programs";
import { exerciseDatabase } from "@/lib/exercises";

export function WorkoutPrograms() {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedDifficulty, setSelectedDifficulty] = useState<string>("all");
  const [selectedGoal, setSelectedGoal] = useState<string>("all");
  const [currentProgram, setCurrentProgram] = useState<UserProgram | null>(null);

  useEffect(() => {
    const program = programTracker.getCurrentProgram();
    setCurrentProgram(program);
  }, []);

  const filteredPrograms = workoutPrograms.filter(program => {
    const searchMatch = searchQuery === "" ||
      program.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      program.description.toLowerCase().includes(searchQuery.toLowerCase());

    const difficultyMatch = selectedDifficulty === "all" ||
      program.difficulty.toLowerCase() === selectedDifficulty.toLowerCase();

    const goalMatch = selectedGoal === "all" ||
      program.goals.some(goal => goal.toLowerCase().includes(selectedGoal.toLowerCase()));

    return searchMatch && difficultyMatch && goalMatch;
  });

  const handleStartProgram = (programId: string) => {
    const userProgram = programTracker.startProgram(programId);
    setCurrentProgram(userProgram);
  };

  return (
    <div className="space-y-4">
      {/* Current Program */}
      {currentProgram && (
        <CurrentProgramCard
          userProgram={currentProgram}
          onWorkoutComplete={() => {
            const updatedProgram = programTracker.getCurrentProgram();
            setCurrentProgram(updatedProgram);
          }}
        />
      )}

      {/* Search and Filters */}
      <Card>
        <CardContent className="p-4 space-y-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search programs..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Select value={selectedDifficulty} onValueChange={setSelectedDifficulty}>
              <SelectTrigger>
                <SelectValue placeholder="Difficulty" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Levels</SelectItem>
                <SelectItem value="beginner">Beginner</SelectItem>
                <SelectItem value="intermediate">Intermediate</SelectItem>
                <SelectItem value="advanced">Advanced</SelectItem>
              </SelectContent>
            </Select>

            <Select value={selectedGoal} onValueChange={setSelectedGoal}>
              <SelectTrigger>
                <SelectValue placeholder="Goal" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Goals</SelectItem>
                <SelectItem value="strength">Build Strength</SelectItem>
                <SelectItem value="muscle">Build Muscle</SelectItem>
                <SelectItem value="fat loss">Fat Loss</SelectItem>
                <SelectItem value="cardio">Improve Cardio</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Programs List */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="font-semibold">Available Programs ({filteredPrograms.length})</h3>
        </div>

        {filteredPrograms.map(program => (
          <ProgramCard
            key={program.id}
            program={program}
            onStart={() => handleStartProgram(program.id)}
            isActive={currentProgram?.programId === program.id}
          />
        ))}
      </div>
    </div>
  );
}

interface CurrentProgramCardProps {
  userProgram: UserProgram;
  onWorkoutComplete: () => void;
}

function CurrentProgramCard({ userProgram, onWorkoutComplete }: CurrentProgramCardProps) {
  const program = programTracker.getProgram(userProgram.programId);
  const currentWorkout = programTracker.getCurrentWorkout();
  const progress = programTracker.getProgramProgress(userProgram.programId);

  if (!program) return null;

  return (
    <Card className="border-primary/20 bg-primary/5">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-lg flex items-center gap-2">
              <Trophy className="h-5 w-5 text-primary" />
              Current Program
            </CardTitle>
            <CardDescription>{program.name}</CardDescription>
          </div>
          <Badge variant="secondary">
            Week {userProgram.currentWeek} / {program.duration}
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <div className="flex justify-between text-sm mb-2">
            <span>Progress</span>
            <span>{Math.round(progress)}% Complete</span>
          </div>
          <Progress value={progress} className="h-2" />
        </div>

        {currentWorkout && (
          <div className="p-3 bg-background rounded border">
            <div className="flex items-center justify-between mb-2">
              <h4 className="font-medium">{currentWorkout.name}</h4>
              <Badge>{currentWorkout.estimatedDuration} min</Badge>
            </div>
            <p className="text-sm text-muted-foreground mb-3">
              {currentWorkout.exercises.length} exercises
            </p>

            <Dialog>
              <DialogTrigger asChild>
                <Button className="w-full">
                  <Play className="h-4 w-4 mr-2" />
                  Start Today's Workout
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle>{currentWorkout.name}</DialogTitle>
                  <DialogDescription>
                    {program.name} - Week {userProgram.currentWeek}
                  </DialogDescription>
                </DialogHeader>
                <WorkoutDetails
                  workout={currentWorkout}
                  onComplete={() => {
                    programTracker.completeWorkout(userProgram.programId, currentWorkout.id);
                    onWorkoutComplete();
                  }}
                />
              </DialogContent>
            </Dialog>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

interface ProgramCardProps {
  program: WorkoutProgram;
  onStart: () => void;
  isActive: boolean;
}

function ProgramCard({ program, onStart, isActive }: ProgramCardProps) {
  return (
    <Card className={isActive ? "border-primary/50" : ""}>
      <CardContent className="p-4">
        <div className="space-y-3">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <h3 className="font-medium">{program.name}</h3>
                {program.rating && (
                  <div className="flex items-center gap-1">
                    <Star className="h-3 w-3 fill-yellow-400 text-yellow-400" />
                    <span className="text-xs text-muted-foreground">{program.rating}</span>
                  </div>
                )}
              </div>
              <p className="text-sm text-muted-foreground mb-2">{program.description}</p>

              <div className="flex flex-wrap gap-1 mb-2">
                <Badge variant={
                  program.difficulty === 'Beginner' ? 'secondary' :
                  program.difficulty === 'Intermediate' ? 'default' : 'destructive'
                }>
                  {program.difficulty}
                </Badge>
                {program.tags.slice(0, 2).map(tag => (
                  <Badge key={tag} variant="outline" className="text-xs">{tag}</Badge>
                ))}
              </div>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4 text-center text-sm">
            <div>
              <div className="flex items-center justify-center gap-1 mb-1">
                <Calendar className="h-3 w-3" />
                <span className="font-medium">{program.duration}w</span>
              </div>
              <p className="text-xs text-muted-foreground">Duration</p>
            </div>
            <div>
              <div className="flex items-center justify-center gap-1 mb-1">
                <Zap className="h-3 w-3" />
                <span className="font-medium">{program.workoutsPerWeek}x</span>
              </div>
              <p className="text-xs text-muted-foreground">Per Week</p>
            </div>
            <div>
              <div className="flex items-center justify-center gap-1 mb-1">
                <Clock className="h-3 w-3" />
                <span className="font-medium">{program.estimatedTime}m</span>
              </div>
              <p className="text-xs text-muted-foreground">Per Session</p>
            </div>
          </div>

          <div className="space-y-2">
            <div>
              <p className="text-xs font-medium text-muted-foreground mb-1">Goals:</p>
              <div className="flex flex-wrap gap-1">
                {program.goals.map(goal => (
                  <Badge key={goal} variant="outline" className="text-xs">{goal}</Badge>
                ))}
              </div>
            </div>

            <div>
              <p className="text-xs font-medium text-muted-foreground mb-1">Equipment:</p>
              <div className="flex flex-wrap gap-1">
                {program.equipment.slice(0, 3).map(equipment => (
                  <Badge key={equipment} variant="secondary" className="text-xs">{equipment}</Badge>
                ))}
                {program.equipment.length > 3 && (
                  <Badge variant="secondary" className="text-xs">
                    +{program.equipment.length - 3} more
                  </Badge>
                )}
              </div>
            </div>
          </div>

          <div className="flex gap-2">
            <Dialog>
              <DialogTrigger asChild>
                <Button variant="outline" className="flex-1">
                  <BookOpen className="h-4 w-4 mr-2" />
                  Preview
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle>{program.name}</DialogTitle>
                  <DialogDescription>{program.description}</DialogDescription>
                </DialogHeader>
                <ProgramPreview program={program} />
              </DialogContent>
            </Dialog>

            <Button
              onClick={onStart}
              disabled={isActive}
              className="flex-1"
            >
              {isActive ? (
                <>
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Active
                </>
              ) : (
                <>
                  <Play className="h-4 w-4 mr-2" />
                  Start Program
                </>
              )}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function WorkoutDetails({ workout, onComplete }: { workout: ProgramWorkout; onComplete: () => void }) {
  const [completedExercises, setCompletedExercises] = useState<Set<string>>(new Set());

  const toggleExercise = (exerciseId: string) => {
    const newCompleted = new Set(completedExercises);
    if (newCompleted.has(exerciseId)) {
      newCompleted.delete(exerciseId);
    } else {
      newCompleted.add(exerciseId);
    }
    setCompletedExercises(newCompleted);
  };

  const isWorkoutComplete = completedExercises.size === workout.exercises.length;

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-4 text-center p-3 bg-muted/30 rounded">
        <div>
          <p className="text-sm text-muted-foreground">Estimated Time</p>
          <p className="font-bold">{workout.estimatedDuration} minutes</p>
        </div>
        <div>
          <p className="text-sm text-muted-foreground">Rest Between Sets</p>
          <p className="font-bold">{workout.restBetweenSets}s</p>
        </div>
      </div>

      <div className="space-y-3">
        <h4 className="font-medium">Exercises ({workout.exercises.length})</h4>
        {workout.exercises.map((exercise, index) => {
          const exerciseInfo = exerciseDatabase.find(ex => ex.id === exercise.exerciseId);
          const isCompleted = completedExercises.has(exercise.exerciseId);

          return (
            <div
              key={`${exercise.exerciseId}-${index}`}
              className={`p-3 border rounded cursor-pointer transition-colors ${
                isCompleted ? 'bg-green-50 border-green-200' : 'hover:bg-muted/30'
              }`}
              onClick={() => toggleExercise(exercise.exerciseId)}
            >
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{exerciseInfo?.name || 'Unknown Exercise'}</span>
                    {isCompleted && <CheckCircle className="h-4 w-4 text-green-600" />}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {exercise.sets} sets × {exercise.reps} reps
                    {exercise.weight && ` @ ${exercise.weight}`}
                  </div>
                  {exercise.notes && (
                    <p className="text-xs text-muted-foreground mt-1">{exercise.notes}</p>
                  )}
                </div>
                <div className="text-right text-sm">
                  <p>Rest: {exercise.rest}s</p>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="pt-4 border-t">
        <Button
          onClick={onComplete}
          disabled={!isWorkoutComplete}
          className="w-full"
        >
          {isWorkoutComplete ? (
            <>
              <CheckCircle className="h-4 w-4 mr-2" />
              Complete Workout
            </>
          ) : (
            `Complete All Exercises (${completedExercises.size}/${workout.exercises.length})`
          )}
        </Button>
      </div>
    </div>
  );
}

function ProgramPreview({ program }: { program: WorkoutProgram }) {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <h4 className="font-medium mb-2">Program Details</h4>
          <div className="space-y-1 text-sm">
            <p><span className="font-medium">Duration:</span> {program.duration} weeks</p>
            <p><span className="font-medium">Difficulty:</span> {program.difficulty}</p>
            <p><span className="font-medium">Workouts/Week:</span> {program.workoutsPerWeek}</p>
            <p><span className="font-medium">Time/Session:</span> {program.estimatedTime} minutes</p>
          </div>
        </div>

        <div>
          <h4 className="font-medium mb-2">Goals</h4>
          <div className="flex flex-wrap gap-1">
            {program.goals.map(goal => (
              <Badge key={goal} variant="outline" className="text-xs">{goal}</Badge>
            ))}
          </div>
        </div>
      </div>

      <div>
        <h4 className="font-medium mb-2">Equipment Needed</h4>
        <div className="flex flex-wrap gap-1">
          {program.equipment.map(equipment => (
            <Badge key={equipment} variant="secondary" className="text-xs">{equipment}</Badge>
          ))}
        </div>
      </div>

      <div>
        <h4 className="font-medium mb-2">Sample Week (Week 1)</h4>
        <div className="space-y-2">
          {program.weeks[0]?.workouts.map((workout, index) => (
            <div key={workout.id} className="p-3 bg-muted/30 rounded">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium">Day {index + 1}: {workout.name}</span>
                <Badge variant="outline">{workout.estimatedDuration}min</Badge>
              </div>
              <div className="text-sm text-muted-foreground">
                {workout.exercises.length} exercises • {workout.type}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
