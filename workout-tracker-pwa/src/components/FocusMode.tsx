"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import {
  Shield,
  Timer,
  Play,
  Pause,
  X,
  Bell,
  Phone,
  MessageSquare,
  Volume2,
  VolumeX,
  Eye,
  EyeOff
} from "lucide-react";

interface FocusModeProps {
  isActive: boolean;
  onToggle: (active: boolean) => void;
  workoutDuration?: number;
  onWorkoutComplete?: () => void;
}

export function FocusMode({ isActive, onToggle, workoutDuration = 3600, onWorkoutComplete }: FocusModeProps) {
  const [settings, setSettings] = useState({
    blockNotifications: true,
    hideNonEssential: true,
    silentMode: true,
    preventScreenOff: true,
    workoutTimer: true
  });

  const [timeRemaining, setTimeRemaining] = useState(workoutDuration);
  const [isPaused, setIsPaused] = useState(false);

  useEffect(() => {
    if (isActive && !isPaused && timeRemaining > 0) {
      const interval = setInterval(() => {
        setTimeRemaining(prev => {
          if (prev <= 1) {
            onWorkoutComplete?.();
            onToggle(false);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);

      return () => clearInterval(interval);
    }
  }, [isActive, isPaused, timeRemaining, onWorkoutComplete, onToggle]);

  useEffect(() => {
    if (isActive) {
      // Prevent screen from turning off
      if (settings.preventScreenOff && 'wakeLock' in navigator) {
        navigator.wakeLock.request('screen').catch(() => {
          console.log('Wake lock not supported');
        });
      }

      // Request notification permission for when focus mode ends
      if (settings.blockNotifications && 'Notification' in window) {
        Notification.requestPermission();
      }

      // Apply focus mode styles
      document.body.classList.add('focus-mode');

      return () => {
        document.body.classList.remove('focus-mode');
      };
    }
  }, [isActive, settings]);

  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
      return `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getProgressPercentage = () => {
    return ((workoutDuration - timeRemaining) / workoutDuration) * 100;
  };

  const handleEndFocus = () => {
    onToggle(false);
    setTimeRemaining(workoutDuration);
    setIsPaused(false);

    // Show completion notification
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification('Focus session complete!', {
        body: 'Great job staying focused on your workout! 💪',
        icon: '/icon-192x192.png'
      });
    }
  };

  if (isActive) {
    return (
      <div className="fixed inset-0 z-50 bg-background">
        {/* Focus Mode Header */}
        <div className="sticky top-0 bg-background/95 backdrop-blur border-b">
          <div className="flex items-center justify-between p-4">
            <div className="flex items-center gap-2">
              <Shield className="h-6 w-6 text-green-500" />
              <div>
                <h1 className="font-bold text-lg">Focus Mode</h1>
                <p className="text-sm text-muted-foreground">Distraction-free workout</p>
              </div>
            </div>

            <Button variant="outline" size="sm" onClick={handleEndFocus}>
              <X className="h-4 w-4 mr-2" />
              Exit Focus
            </Button>
          </div>
        </div>

        {/* Focus Mode Content */}
        <div className="p-4 space-y-6">
          {/* Timer Card */}
          <Card className="border-green-500/20 bg-green-50/50">
            <CardHeader className="text-center">
              <CardTitle className="text-3xl font-bold text-green-700">
                {formatTime(timeRemaining)}
              </CardTitle>
              <CardDescription>Time remaining in focus session</CardDescription>
            </CardHeader>
            <CardContent>
              <Progress value={getProgressPercentage()} className="h-3 mb-4" />
              <div className="flex gap-2 justify-center">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setIsPaused(!isPaused)}
                >
                  {isPaused ? <Play className="h-4 w-4" /> : <Pause className="h-4 w-4" />}
                  {isPaused ? 'Resume' : 'Pause'}
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Active Restrictions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Active Restrictions</CardTitle>
              <CardDescription>Features blocked during focus mode</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {settings.blockNotifications && (
                <div className="flex items-center gap-3 p-3 bg-muted/30 rounded">
                  <Bell className="h-5 w-5 text-orange-500" />
                  <div>
                    <p className="font-medium">Notifications Blocked</p>
                    <p className="text-sm text-muted-foreground">Only workout alerts allowed</p>
                  </div>
                  <Badge variant="secondary">Active</Badge>
                </div>
              )}

              {settings.hideNonEssential && (
                <div className="flex items-center gap-3 p-3 bg-muted/30 rounded">
                  <EyeOff className="h-5 w-5 text-blue-500" />
                  <div>
                    <p className="font-medium">Simplified Interface</p>
                    <p className="text-sm text-muted-foreground">Non-essential elements hidden</p>
                  </div>
                  <Badge variant="secondary">Active</Badge>
                </div>
              )}

              {settings.silentMode && (
                <div className="flex items-center gap-3 p-3 bg-muted/30 rounded">
                  <VolumeX className="h-5 w-5 text-purple-500" />
                  <div>
                    <p className="font-medium">Silent Mode</p>
                    <p className="text-sm text-muted-foreground">Only workout sounds enabled</p>
                  </div>
                  <Badge variant="secondary">Active</Badge>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Quick Stats (Simplified) */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Session Progress</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4 text-center">
                <div>
                  <p className="text-2xl font-bold text-green-600">
                    {Math.floor((workoutDuration - timeRemaining) / 60)}m
                  </p>
                  <p className="text-sm text-muted-foreground">Time Elapsed</p>
                </div>
                <div>
                  <p className="text-2xl font-bold text-blue-600">
                    {Math.round(getProgressPercentage())}%
                  </p>
                  <p className="text-sm text-muted-foreground">Session Complete</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Motivational Message */}
          <Card className="border-primary/20 bg-primary/5">
            <CardContent className="p-6 text-center">
              <h3 className="font-bold text-lg mb-2">Stay Focused! 💪</h3>
              <p className="text-muted-foreground">
                You're in the zone. Keep pushing towards your fitness goals!
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm">
          <Shield className="h-4 w-4 mr-2" />
          Focus Mode
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Enter Focus Mode</DialogTitle>
          <DialogDescription>
            Block distractions and stay focused on your workout
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Focus Settings */}
          <div className="space-y-3">
            <h4 className="font-medium">Focus Settings</h4>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Bell className="h-4 w-4" />
                <span className="text-sm">Block notifications</span>
              </div>
              <Switch
                checked={settings.blockNotifications}
                onCheckedChange={(checked) =>
                  setSettings(prev => ({ ...prev, blockNotifications: checked }))
                }
              />
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Eye className="h-4 w-4" />
                <span className="text-sm">Hide non-essential UI</span>
              </div>
              <Switch
                checked={settings.hideNonEssential}
                onCheckedChange={(checked) =>
                  setSettings(prev => ({ ...prev, hideNonEssential: checked }))
                }
              />
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Volume2 className="h-4 w-4" />
                <span className="text-sm">Silent mode</span>
              </div>
              <Switch
                checked={settings.silentMode}
                onCheckedChange={(checked) =>
                  setSettings(prev => ({ ...prev, silentMode: checked }))
                }
              />
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Timer className="h-4 w-4" />
                <span className="text-sm">Keep screen on</span>
              </div>
              <Switch
                checked={settings.preventScreenOff}
                onCheckedChange={(checked) =>
                  setSettings(prev => ({ ...prev, preventScreenOff: checked }))
                }
              />
            </div>
          </div>

          <div className="pt-4 border-t">
            <Button
              onClick={() => onToggle(true)}
              className="w-full"
            >
              <Shield className="h-4 w-4 mr-2" />
              Start Focus Session ({Math.floor(workoutDuration / 60)} minutes)
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
