"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Play, Pause, RotateCcw, Timer } from "lucide-react";

interface WorkoutTimerProps {
  initialTime?: number;
  onComplete?: () => void;
  type?: 'rest' | 'workout';
}

export function WorkoutTimer({ initialTime = 60, onComplete, type = 'rest' }: WorkoutTimerProps) {
  const [time, setTime] = useState(initialTime);
  const [isRunning, setIsRunning] = useState(false);
  const [isCompleted, setIsCompleted] = useState(false);

  useEffect(() => {
    let interval: NodeJS.Timeout;

    if (isRunning && time > 0) {
      interval = setInterval(() => {
        setTime((prevTime) => {
          if (prevTime <= 1) {
            setIsRunning(false);
            setIsCompleted(true);
            onComplete?.();
            return 0;
          }
          return prevTime - 1;
        });
      }, 1000);
    }

    return () => clearInterval(interval);
  }, [isRunning, time, onComplete]);

  const handleStart = () => {
    setIsRunning(true);
    setIsCompleted(false);
  };

  const handlePause = () => {
    setIsRunning(false);
  };

  const handleReset = () => {
    setIsRunning(false);
    setIsCompleted(false);
    setTime(initialTime);
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getProgressPercentage = () => {
    return ((initialTime - time) / initialTime) * 100;
  };

  return (
    <Card className={`${isCompleted ? 'border-green-500' : ''} ${type === 'workout' ? 'border-blue-500' : ''}`}>
      <CardContent className="p-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Timer className={`h-5 w-5 ${type === 'workout' ? 'text-blue-500' : 'text-orange-500'}`} />
            <span className="font-medium">
              {type === 'rest' ? 'Rest Timer' : 'Workout Timer'}
            </span>
          </div>
          {isCompleted && (
            <span className="text-green-500 font-medium">Complete!</span>
          )}
        </div>

        <div className="text-center mb-4">
          <div className={`text-3xl font-bold ${isCompleted ? 'text-green-500' : ''}`}>
            {formatTime(time)}
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
            <div
              className={`h-2 rounded-full transition-all duration-1000 ${
                type === 'workout' ? 'bg-blue-500' : 'bg-orange-500'
              }`}
              style={{ width: `${getProgressPercentage()}%` }}
            ></div>
          </div>
        </div>

        <div className="flex gap-2">
          {!isRunning ? (
            <Button onClick={handleStart} className="flex-1">
              <Play className="h-4 w-4 mr-2" />
              Start
            </Button>
          ) : (
            <Button onClick={handlePause} variant="outline" className="flex-1">
              <Pause className="h-4 w-4 mr-2" />
              Pause
            </Button>
          )}
          <Button onClick={handleReset} variant="outline" size="icon">
            <RotateCcw className="h-4 w-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
