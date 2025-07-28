"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Progress } from "@/components/ui/progress";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Separator } from "@/components/ui/separator";
import {
  Play,
  Pause,
  CheckCircle,
  Timer,
  TrendingUp,
  AlertCircle,
  RotateCcw,
  Zap,
  Target
} from "lucide-react";
import { WorkoutTimer } from "./WorkoutTimer";
import { exerciseDatabase, Exercise } from "@/lib/exercises";
import { Workout, WorkoutExercise, WorkoutSet, workoutTracker, ProgressionSuggestion } from "@/lib/workout-tracker";

interface WorkoutSessionProps {
  workout: Workout;
  onComplete: () => void;
  onUpdate: () => void;
}

export function WorkoutSession({ workout, onComplete, onUpdate }: WorkoutSessionProps) {
  const [currentExerciseIndex, setCurrentExerciseIndex] = useState(0);
  const [showTimer, setShowTimer] = useState(false);
  const [workoutStartTime] = useState(Date.now());
  const [elapsedTime, setElapsedTime] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setElapsedTime(Date.now() - workoutStartTime);
    }, 1000);

    return () => clearInterval(interval);
  }, [workoutStartTime]);

  const currentExercise = workout.exercises[currentExerciseIndex];
  const completedSets = currentExercise?.sets.filter(set => set.completed).length || 0;
  const totalSets = currentExercise?.sets.length || 0;
  const workoutProgress = (workout.exercises.reduce((sum, ex) => sum + ex.sets.filter(s => s.completed).length, 0) / workout.exercises.reduce((sum, ex) => sum + ex.sets.length, 0)) * 100;

  const handleSetUpdate = (setIndex: number, data: Partial<WorkoutSet>) => {
    workoutTracker.updateSet(currentExerciseIndex, setIndex, data);
    onUpdate();
  };

  const handleCompleteWorkout = () => {
    workoutTracker.completeWorkout();
    onComplete();
  };

  const nextExercise = () => {
    if (currentExerciseIndex < workout.exercises.length - 1) {
      setCurrentExerciseIndex(currentExerciseIndex + 1);
    }
  };

  const previousExercise = () => {
    if (currentExerciseIndex > 0) {
      setCurrentExerciseIndex(currentExerciseIndex - 1);
    }
  };

  const formatTime = (ms: number) => {
    const seconds = Math.floor(ms / 1000);
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getExerciseInfo = (exerciseId: string): Exercise | undefined => {
    return exerciseDatabase.find(ex => ex.id === exerciseId);
  };

  return (
    <div className="space-y-4">
      {/* Workout Header */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-lg">{workout.name}</CardTitle>
              <CardDescription>
                Exercise {currentExerciseIndex + 1} of {workout.exercises.length} • {formatTime(elapsedTime)}
              </CardDescription>
            </div>
            <Button variant="outline" size="sm" onClick={() => setShowTimer(!showTimer)}>
              <Timer className="h-4 w-4 mr-2" />
              Timer
            </Button>
          </div>
          <Progress value={workoutProgress} className="h-2" />
        </CardHeader>
      </Card>

      {/* Timer */}
      {showTimer && (
        <WorkoutTimer
          initialTime={90}
          type="rest"
          onComplete={() => setShowTimer(false)}
        />
      )}

      {/* Current Exercise */}
      {currentExercise && (
        <CurrentExerciseCard
          exercise={currentExercise}
          exerciseInfo={getExerciseInfo(currentExercise.exerciseId)}
          onSetUpdate={handleSetUpdate}
          completedSets={completedSets}
          totalSets={totalSets}
        />
      )}

      {/* Navigation */}
      <div className="flex gap-2">
        <Button
          variant="outline"
          onClick={previousExercise}
          disabled={currentExerciseIndex === 0}
          className="flex-1"
        >
          Previous
        </Button>

        {currentExerciseIndex < workout.exercises.length - 1 ? (
          <Button onClick={nextExercise} className="flex-1">
            Next Exercise
          </Button>
        ) : (
          <Button onClick={handleCompleteWorkout} className="flex-1">
            <CheckCircle className="h-4 w-4 mr-2" />
            Complete Workout
          </Button>
        )}
      </div>

      {/* Exercise Overview */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Workout Overview</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {workout.exercises.map((exercise, index) => {
            const exerciseInfo = getExerciseInfo(exercise.exerciseId);
            const exerciseCompleted = exercise.sets.filter(s => s.completed).length;
            const exerciseTotal = exercise.sets.length;

            return (
              <div
                key={exercise.id}
                className={`flex items-center justify-between p-2 rounded ${
                  index === currentExerciseIndex ? 'bg-primary/10 border border-primary/20' : 'bg-muted/30'
                }`}
              >
                <div>
                  <span className="font-medium">{exerciseInfo?.name || 'Unknown Exercise'}</span>
                  <div className="flex gap-1 mt-1">
                    {exerciseInfo?.primaryMuscles.map(muscle => (
                      <Badge key={muscle} variant="outline" className="text-xs">{muscle}</Badge>
                    ))}
                  </div>
                </div>
                <span className={`text-sm ${exerciseCompleted === exerciseTotal ? 'text-green-600' : 'text-muted-foreground'}`}>
                  {exerciseCompleted}/{exerciseTotal}
                </span>
              </div>
            );
          })}
        </CardContent>
      </Card>
    </div>
  );
}

interface CurrentExerciseCardProps {
  exercise: WorkoutExercise;
  exerciseInfo?: Exercise;
  onSetUpdate: (setIndex: number, data: Partial<WorkoutSet>) => void;
  completedSets: number;
  totalSets: number;
}

function CurrentExerciseCard({ exercise, exerciseInfo, onSetUpdate, completedSets, totalSets }: CurrentExerciseCardProps) {
  const [suggestion, setSuggestion] = useState<ProgressionSuggestion | null>(null);

  useEffect(() => {
    if (exerciseInfo) {
      const progressionSuggestion = workoutTracker.getProgressionSuggestion(
        exercise.exerciseId,
        exercise.targetSets,
        exercise.targetReps,
        exercise.targetWeight
      );
      setSuggestion(progressionSuggestion);
    }
  }, [exercise, exerciseInfo]);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-start justify-between">
          <div>
            <CardTitle className="text-lg">{exerciseInfo?.name || 'Unknown Exercise'}</CardTitle>
            <CardDescription>
              {exerciseInfo?.equipment} • {completedSets}/{totalSets} sets completed
            </CardDescription>
          </div>
          {suggestion && (
            <Dialog>
              <DialogTrigger asChild>
                <Button variant="outline" size="sm">
                  <TrendingUp className="h-4 w-4 mr-2" />
                  Tips
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Progression Suggestion</DialogTitle>
                  <DialogDescription>Based on your workout history</DialogDescription>
                </DialogHeader>
                <div className="space-y-3">
                  <div className="flex items-center gap-2">
                    <Target className="h-5 w-5 text-blue-500" />
                    <span>
                      Try {suggestion.suggestedValue} {suggestion.type}
                      (currently {suggestion.currentValue})
                    </span>
                  </div>
                  <p className="text-sm text-muted-foreground">{suggestion.reason}</p>
                </div>
              </DialogContent>
            </Dialog>
          )}
        </div>

        {exerciseInfo && (
          <div className="flex flex-wrap gap-1">
            {exerciseInfo.primaryMuscles.map(muscle => (
              <Badge key={muscle} variant="default" className="text-xs">{muscle}</Badge>
            ))}
            {exerciseInfo.secondaryMuscles.map(muscle => (
              <Badge key={muscle} variant="outline" className="text-xs">{muscle}</Badge>
            ))}
          </div>
        )}
      </CardHeader>

      <CardContent className="space-y-3">
        {/* Target Info */}
        <div className="grid grid-cols-3 gap-4 p-3 bg-muted/30 rounded">
          <div className="text-center">
            <div className="text-sm text-muted-foreground">Target Sets</div>
            <div className="font-bold">{exercise.targetSets}</div>
          </div>
          <div className="text-center">
            <div className="text-sm text-muted-foreground">Target Reps</div>
            <div className="font-bold">{exercise.targetReps}</div>
          </div>
          <div className="text-center">
            <div className="text-sm text-muted-foreground">Target Weight</div>
            <div className="font-bold">{exercise.targetWeight}kg</div>
          </div>
        </div>

        {/* Sets */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <h4 className="font-medium">Sets</h4>
            <span className="text-sm text-muted-foreground">
              Tap to mark complete
            </span>
          </div>

          {exercise.sets.map((set, index) => (
            <SetRow
              key={set.id}
              set={set}
              setNumber={index + 1}
              onUpdate={(data) => onSetUpdate(index, data)}
            />
          ))}
        </div>

        {/* Exercise Instructions */}
        {exerciseInfo && (
          <Dialog>
            <DialogTrigger asChild>
              <Button variant="outline" className="w-full">
                <AlertCircle className="h-4 w-4 mr-2" />
                View Instructions
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>{exerciseInfo.name}</DialogTitle>
                <DialogDescription>How to perform this exercise correctly</DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div>
                  <h4 className="font-medium mb-2">Instructions</h4>
                  <ol className="list-decimal list-inside space-y-1 text-sm">
                    {exerciseInfo.instructions.map((instruction, index) => (
                      <li key={index}>{instruction}</li>
                    ))}
                  </ol>
                </div>
                {exerciseInfo.tips.length > 0 && (
                  <div>
                    <h4 className="font-medium mb-2">Tips</h4>
                    <ul className="list-disc list-inside space-y-1 text-sm">
                      {exerciseInfo.tips.map((tip, index) => (
                        <li key={index}>{tip}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            </DialogContent>
          </Dialog>
        )}
      </CardContent>
    </Card>
  );
}

interface SetRowProps {
  set: WorkoutSet;
  setNumber: number;
  onUpdate: (data: Partial<WorkoutSet>) => void;
}

function SetRow({ set, setNumber, onUpdate }: SetRowProps) {
  return (
    <div className={`flex items-center gap-3 p-3 rounded border ${
      set.completed ? 'bg-green-50 border-green-200' : 'bg-background'
    }`}>
      <Checkbox
        checked={set.completed}
        onCheckedChange={(checked) => onUpdate({ completed: !!checked })}
      />

      <span className="w-8 text-sm font-medium">#{setNumber}</span>

      <div className="flex gap-2 flex-1">
        <Input
          type="number"
          placeholder="Reps"
          value={set.reps || ''}
          onChange={(e) => onUpdate({ reps: parseInt(e.target.value) || 0 })}
          className="w-20"
        />
        <Input
          type="number"
          placeholder="Weight"
          value={set.weight || ''}
          onChange={(e) => onUpdate({ weight: parseFloat(e.target.value) || 0 })}
          className="w-24"
          step="0.5"
        />
      </div>

      {set.completed && (
        <CheckCircle className="h-5 w-5 text-green-600" />
      )}
    </div>
  );
}
