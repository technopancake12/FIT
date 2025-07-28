"use client";

import { useState, useEffect } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import { Input } from "@/components/ui/input";
import {
  Dumbbell,
  Apple,
  Users,
  TrendingUp,
  Plus,
  Play,
  Timer,
  Target,
  Heart,
  Zap,
  Calendar,
  Camera,
  Trophy,
  Video,
  ChefHat,
  Wrench,
  Smartphone,
  CheckCircle
} from "lucide-react";
import { ExerciseSearch } from "@/components/ExerciseSearch";
import { WorkoutSession } from "@/components/WorkoutSession";
import { FocusMode } from "@/components/FocusMode";
import { NutritionTracker } from "@/components/NutritionTracker";
import { ProgressCharts } from "@/components/ProgressCharts";
import { WorkoutPrograms } from "@/components/WorkoutPrograms";
import { SocialFeed } from "@/components/SocialFeed";
import { HealthIntegration } from "@/components/HealthIntegration";
import { exerciseDatabase, Exercise } from "@/lib/exercises";
import { Workout, workoutTracker } from "@/lib/workout-tracker";
import { challengeManager } from "@/lib/challenges";
import { videoTutorialManager } from "@/lib/video-tutorials";
import { mealPlanningManager } from "@/lib/meal-planning";
import { customWorkoutBuilder } from "@/lib/custom-workout-builder";

export default function FitTrackerApp() {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [focusModeActive, setFocusModeActive] = useState(false);

  return (
    <div className="min-h-screen bg-background">
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        {/* Header */}
        <div className="sticky top-0 z-50 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
          <div className="flex items-center justify-between p-4">
            <div className="flex items-center gap-2">
              <Dumbbell className="h-6 w-6 text-primary" />
              <h1 className="text-lg font-bold">FitTracker</h1>
            </div>
            <Button variant="ghost" size="icon">
              <Users className="h-5 w-5" />
            </Button>
          </div>
        </div>

        {/* Main Content */}
        <div className="pb-20">
          <TabsContent value="dashboard" className="m-0 p-4 space-y-4">
            <DashboardContent setActiveTab={setActiveTab} />
          </TabsContent>

          <TabsContent value="workout" className="m-0 p-4 space-y-4">
            <WorkoutContent />
          </TabsContent>

          <TabsContent value="nutrition" className="m-0 p-4 space-y-4">
            <NutritionContent />
          </TabsContent>

          <TabsContent value="social" className="m-0 p-4 space-y-4">
            <SocialContent />
          </TabsContent>

          <TabsContent value="progress" className="m-0 p-4 space-y-4">
            <ProgressContent />
          </TabsContent>

          <TabsContent value="health" className="m-0 p-4 space-y-4">
            <HealthContent />
          </TabsContent>

          <TabsContent value="challenges" className="m-0 p-4 space-y-4">
            <ChallengesContent />
          </TabsContent>

          <TabsContent value="videos" className="m-0 p-4 space-y-4">
            <VideoTutorialsContent />
          </TabsContent>

          <TabsContent value="meal-planning" className="m-0 p-4 space-y-4">
            <MealPlanningContent />
          </TabsContent>

          <TabsContent value="custom-builder" className="m-0 p-4 space-y-4">
            <CustomWorkoutBuilderContent />
          </TabsContent>
        </div>

        {/* Bottom Navigation */}
        <div className="fixed bottom-0 left-0 right-0 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-t">
          <TabsList className="grid w-full grid-cols-6 bg-transparent h-16">
            <TabsTrigger value="dashboard" className="flex-col gap-1 h-full">
              <TrendingUp className="h-3 w-3" />
              <span className="text-xs">Home</span>
            </TabsTrigger>
            <TabsTrigger value="workout" className="flex-col gap-1 h-full">
              <Dumbbell className="h-3 w-3" />
              <span className="text-xs">Workout</span>
            </TabsTrigger>
            <TabsTrigger value="nutrition" className="flex-col gap-1 h-full">
              <Apple className="h-3 w-3" />
              <span className="text-xs">Nutrition</span>
            </TabsTrigger>
            <TabsTrigger value="social" className="flex-col gap-1 h-full">
              <Users className="h-3 w-3" />
              <span className="text-xs">Social</span>
            </TabsTrigger>
            <TabsTrigger value="progress" className="flex-col gap-1 h-full">
              <Target className="h-3 w-3" />
              <span className="text-xs">Analytics</span>
            </TabsTrigger>
            <TabsTrigger value="health" className="flex-col gap-1 h-full">
              <Heart className="h-3 w-3" />
              <span className="text-xs">Health</span>
            </TabsTrigger>
          </TabsList>
        </div>
      </Tabs>
    </div>
  );
}

function DashboardContent({ setActiveTab }: { setActiveTab: (tab: string) => void }) {
  const [focusModeActive, setFocusModeActive] = useState(false);

  return (
    <>
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold">Good morning! 💪</h2>
          <FocusMode
            isActive={focusModeActive}
            onToggle={setFocusModeActive}
            workoutDuration={3600}
          />
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 gap-4">
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center gap-2">
                <Zap className="h-5 w-5 text-orange-500" />
                <div>
                  <p className="text-sm text-muted-foreground">Streak</p>
                  <p className="text-2xl font-bold">7 days</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center gap-2">
                <Calendar className="h-5 w-5 text-blue-500" />
                <div>
                  <p className="text-sm text-muted-foreground">This Week</p>
                  <p className="text-2xl font-bold">4 workouts</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Today's Goals */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Today's Goals</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <div className="flex justify-between text-sm mb-2">
                <span>Calories Burned</span>
                <span>450/600</span>
              </div>
              <Progress value={75} />
            </div>
            <div>
              <div className="flex justify-between text-sm mb-2">
                <span>Protein Intake</span>
                <span>120g/150g</span>
              </div>
              <Progress value={80} />
            </div>
          </CardContent>
        </Card>

        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-4">
          <Button className="h-20 flex-col gap-2" onClick={() => setActiveTab("workout")}>
            <Play className="h-6 w-6" />
            Start Workout
          </Button>
          <Button variant="outline" className="h-20 flex-col gap-2" onClick={() => setActiveTab("nutrition")}>
            <Plus className="h-6 w-6" />
            Log Meal
          </Button>
        </div>

        {/* Advanced Features Quick Access */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Explore Features</CardTitle>
            <CardDescription>Access all advanced functionality</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              <AdvancedFeatureCard
                title="Challenges"
                description="Join fitness challenges"
                icon={<Trophy className="h-5 w-5" />}
                onClick={() => setActiveTab("challenges")}
              />
              <AdvancedFeatureCard
                title="Video Tutorials"
                description="Exercise form guides"
                icon={<Video className="h-5 w-5" />}
                onClick={() => setActiveTab("videos")}
              />
              <AdvancedFeatureCard
                title="Meal Planning"
                description="Plan your nutrition"
                icon={<ChefHat className="h-5 w-5" />}
                onClick={() => setActiveTab("meal-planning")}
              />
              <AdvancedFeatureCard
                title="Custom Builder"
                description="Create custom workouts"
                icon={<Wrench className="h-5 w-5" />}
                onClick={() => setActiveTab("custom-builder")}
              />
            </div>
          </CardContent>
        </Card>
      </div>
    </>
  );
}

function AdvancedFeatureCard({ title, description, icon, onClick }: {
  title: string;
  description: string;
  icon: React.ReactNode;
  onClick: () => void;
}) {
  return (
    <Card className="cursor-pointer hover:bg-muted/50 transition-colors" onClick={onClick}>
      <CardContent className="p-3">
        <div className="flex items-center gap-2 mb-1">
          {icon}
          <h4 className="font-medium text-sm">{title}</h4>
        </div>
        <p className="text-xs text-muted-foreground">{description}</p>
      </CardContent>
    </Card>
  );
}

function WorkoutContent() {
  const [currentWorkout, setCurrentWorkout] = useState<Workout | null>(null);
  const [showExerciseSearch, setShowExerciseSearch] = useState(false);
  const [selectedExercises, setSelectedExercises] = useState<Exercise[]>([]);
  const [workoutName, setWorkoutName] = useState("");

  useEffect(() => {
    const workout = workoutTracker.getCurrentWorkout();
    setCurrentWorkout(workout);
  }, []);

  const handleSelectExercise = (exercise: Exercise) => {
    if (!selectedExercises.find(ex => ex.id === exercise.id)) {
      setSelectedExercises([...selectedExercises, exercise]);
    }
  };

  const handleStartWorkout = () => {
    if (selectedExercises.length === 0) return;

    const exercises = selectedExercises.map(exercise => ({
      exerciseId: exercise.id,
      targetSets: 3,
      targetReps: 10,
      targetWeight: exercise.equipment === 'Bodyweight' ? 0 : 20
    }));

    const workout = workoutTracker.startWorkout(workoutName || 'Quick Workout', exercises);
    setCurrentWorkout(workout);
    setShowExerciseSearch(false);
    setSelectedExercises([]);
    setWorkoutName("");
  };

  const handleCompleteWorkout = () => {
    setCurrentWorkout(null);
  };

  const handleUpdateWorkout = () => {
    setCurrentWorkout(workoutTracker.getCurrentWorkout());
  };

  if (currentWorkout) {
    return (
      <WorkoutSession
        workout={currentWorkout}
        onComplete={handleCompleteWorkout}
        onUpdate={handleUpdateWorkout}
      />
    );
  }

  if (showExerciseSearch) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold">Create Workout</h2>
          <Button variant="outline" onClick={() => setShowExerciseSearch(false)}>
            Cancel
          </Button>
        </div>

        <Card>
          <CardContent className="p-4">
            <Input
              placeholder="Workout name (optional)"
              value={workoutName}
              onChange={(e) => setWorkoutName(e.target.value)}
              className="mb-4"
            />
            {selectedExercises.length > 0 && (
              <div className="space-y-2 mb-4">
                <h4 className="font-medium">Selected Exercises ({selectedExercises.length})</h4>
                {selectedExercises.map(exercise => (
                  <div key={exercise.id} className="flex items-center justify-between p-2 bg-muted rounded">
                    <span className="font-medium">{exercise.name}</span>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setSelectedExercises(selectedExercises.filter(ex => ex.id !== exercise.id))}
                    >
                      Remove
                    </Button>
                  </div>
                ))}
                <Button onClick={handleStartWorkout} className="w-full">
                  <Play className="h-4 w-4 mr-2" />
                  Start Workout
                </Button>
              </div>
            )}
          </CardContent>
        </Card>

        <ExerciseSearch
          onSelectExercise={handleSelectExercise}
          selectedExercises={selectedExercises.map(ex => ex.id)}
        />
      </div>
    );
  }

  return (
    <Tabs defaultValue="quick" className="w-full">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold">Workouts</h2>
        <Button size="sm" onClick={() => setShowExerciseSearch(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Custom Workout
        </Button>
      </div>

      <TabsList className="grid w-full grid-cols-2">
        <TabsTrigger value="quick">Quick Start</TabsTrigger>
        <TabsTrigger value="programs">Programs</TabsTrigger>
      </TabsList>

      <TabsContent value="quick" className="space-y-4">
        <WorkoutStats />

        <div className="space-y-3">
          <h3 className="font-semibold">Quick Start Templates</h3>
          <div className="space-y-2">
            <QuickWorkoutCard
              title="Push Day"
              description="Chest, Shoulders, Triceps"
              exercises={["bench-press", "overhead-press", "tricep-dip"]}
              onStart={(exercises) => {
                const workout = workoutTracker.startWorkout('Push Day', exercises);
                setCurrentWorkout(workout);
              }}
            />
            <QuickWorkoutCard
              title="Pull Day"
              description="Back, Biceps"
              exercises={["pull-up", "bent-over-row", "bicep-curl"]}
              onStart={(exercises) => {
                const workout = workoutTracker.startWorkout('Pull Day', exercises);
                setCurrentWorkout(workout);
              }}
            />
            <QuickWorkoutCard
              title="Leg Day"
              description="Quadriceps, Hamstrings, Glutes"
              exercises={["squat", "deadlift", "lunge"]}
              onStart={(exercises) => {
                const workout = workoutTracker.startWorkout('Leg Day', exercises);
                setCurrentWorkout(workout);
              }}
            />
          </div>
        </div>
      </TabsContent>

      <TabsContent value="programs" className="space-y-4">
        <WorkoutPrograms />
      </TabsContent>
    </Tabs>
  );
}

function NutritionContent() {
  return <NutritionTracker />;
}

function SocialContent() {
  return <SocialFeed />;
}

function ProgressContent() {
  return (
    <>
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">Progress Analytics</h2>
      </div>

      <ProgressCharts />
    </>
  );
}

function HealthContent() {
  return <HealthIntegration />;
}

function ChallengesContent() {
  const [challenges, setChallenges] = useState<unknown[]>([]);
  const [userChallenges, setUserChallenges] = useState<unknown[]>([]);
  const [userStats, setUserStats] = useState<Record<string, unknown>>({});

  useEffect(() => {
    setChallenges(challengeManager.getActiveChallenges());
    setUserChallenges(challengeManager.getUserChallenges());
    setUserStats(challengeManager.getUserStats());
  }, []);

  const handleJoinChallenge = (challengeId: string) => {
    const success = challengeManager.joinChallenge(challengeId);
    if (success) {
      setChallenges(challengeManager.getActiveChallenges());
      setUserChallenges(challengeManager.getUserChallenges());
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Challenges</h2>
          <p className="text-muted-foreground">Join fitness challenges and compete with others</p>
        </div>
      </div>

      {/* User Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4 text-center">
            <Trophy className="h-6 w-6 mx-auto mb-2 text-yellow-500" />
            <p className="text-2xl font-bold">{(userStats as any).challengesCompleted || 0}</p>
            <p className="text-sm text-muted-foreground">Completed</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Target className="h-6 w-6 mx-auto mb-2 text-green-500" />
            <p className="text-2xl font-bold">{(userStats as any).challengesJoined || 0}</p>
            <p className="text-sm text-muted-foreground">Joined</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Zap className="h-6 w-6 mx-auto mb-2 text-blue-500" />
            <p className="text-2xl font-bold">{(userStats as any).totalPoints || 0}</p>
            <p className="text-sm text-muted-foreground">Points</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Users className="h-6 w-6 mx-auto mb-2 text-purple-500" />
            <p className="text-2xl font-bold">{userStats.teamsJoined || 0}</p>
            <p className="text-sm text-muted-foreground">Teams</p>
          </CardContent>
        </Card>
      </div>

      {/* My Challenges */}
      {userChallenges.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>My Active Challenges</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {userChallenges.slice(0, 3).map((challenge: any) => (
              <div key={challenge.id} className="flex items-center justify-between p-3 bg-muted/30 rounded">
                <div>
                  <h4 className="font-medium">{challenge.title}</h4>
                  <p className="text-sm text-muted-foreground">{challenge.description}</p>
                </div>
                <Badge>{challenge.status}</Badge>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Active Challenges */}
      <Card>
        <CardHeader>
          <CardTitle>Available Challenges</CardTitle>
          <CardDescription>Join new challenges to test your limits</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {challenges.slice(0, 5).map((challenge: any) => (
            <div key={challenge.id} className="border rounded-lg p-4">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="font-semibold">{challenge.title}</h3>
                  <p className="text-sm text-muted-foreground">{challenge.description}</p>
                </div>
                <Badge variant={challenge.difficulty === 'Easy' ? 'secondary' : challenge.difficulty === 'Medium' ? 'default' : 'destructive'}>
                  {challenge.difficulty}
                </Badge>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex gap-2">
                  <Badge variant="outline">{challenge.category}</Badge>
                  <Badge variant="outline">{challenge.duration} days</Badge>
                  <Badge variant="outline">{challenge.participants?.length || 0} participants</Badge>
                </div>
                <Button size="sm" onClick={() => handleJoinChallenge(challenge.id)}>
                  Join Challenge
                </Button>
              </div>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}

function VideoTutorialsContent() {
  const [featuredVideos, setFeaturedVideos] = useState<unknown[]>([]);
  const [recentVideos, setRecentVideos] = useState<unknown[]>([]);
  const [userStats, setUserStats] = useState<Record<string, unknown>>({});

  useEffect(() => {
    setFeaturedVideos(videoTutorialManager.getFeaturedVideos());
    setRecentVideos(videoTutorialManager.getRecentVideos());
    setUserStats(videoTutorialManager.getUserStats());
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Video Tutorials</h2>
          <p className="text-muted-foreground">Learn proper exercise form and techniques</p>
        </div>
      </div>

      {/* User Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4 text-center">
            <Video className="h-6 w-6 mx-auto mb-2 text-blue-500" />
            <p className="text-2xl font-bold">{userStats.videosWatched || 0}</p>
            <p className="text-sm text-muted-foreground">Videos Watched</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Timer className="h-6 w-6 mx-auto mb-2 text-green-500" />
            <p className="text-2xl font-bold">{userStats.totalWatchTime || 0}m</p>
            <p className="text-sm text-muted-foreground">Watch Time</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <CheckCircle className="h-6 w-6 mx-auto mb-2 text-yellow-500" />
            <p className="text-2xl font-bold">{userStats.videosCompleted || 0}</p>
            <p className="text-sm text-muted-foreground">Completed</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <Heart className="h-6 w-6 mx-auto mb-2 text-red-500" />
            <p className="text-2xl font-bold">{userStats.bookmarkedVideos || 0}</p>
            <p className="text-sm text-muted-foreground">Bookmarked</p>
          </CardContent>
        </Card>
      </div>

      {/* Featured Videos */}
      <Card>
        <CardHeader>
          <CardTitle>Featured Tutorials</CardTitle>
          <CardDescription>Most helpful exercise tutorials</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            {featuredVideos.slice(0, 3).map((video: any) => (
              <div key={video.id} className="flex items-start gap-4 p-3 border rounded-lg">
                <div className="w-16 h-12 bg-muted rounded flex items-center justify-center">
                  <Play className="h-6 w-6" />
                </div>
                <div className="flex-1">
                  <h4 className="font-medium">{video.title}</h4>
                  <p className="text-sm text-muted-foreground">{video.description}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <Badge variant="outline">{video.difficulty}</Badge>
                    <Badge variant="outline">{Math.floor(video.duration / 60)}:{(video.duration % 60).toString().padStart(2, '0')}</Badge>
                    <span className="text-sm text-muted-foreground">★ {video.rating}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Recent Videos */}
      <Card>
        <CardHeader>
          <CardTitle>Recently Added</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {recentVideos.slice(0, 4).map((video: any) => (
              <div key={video.id} className="flex items-center justify-between p-3 bg-muted/30 rounded">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-8 bg-background rounded flex items-center justify-center">
                    <Play className="h-4 w-4" />
                  </div>
                  <div>
                    <h4 className="font-medium text-sm">{video.title}</h4>
                    <p className="text-xs text-muted-foreground">{video.instructor.name}</p>
                  </div>
                </div>
                <Badge variant="outline">{Math.floor(video.duration / 60)}m</Badge>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function MealPlanningContent() {
  const [recipes, setRecipes] = useState<unknown[]>([]);
  const [mealPlans, setMealPlans] = useState<unknown[]>([]);
  const [templates, setTemplates] = useState<unknown[]>([]);

  useEffect(() => {
    setRecipes(mealPlanningManager.getRecipes());
    setMealPlans(mealPlanningManager.getUserMealPlans());
    setTemplates(mealPlanningManager.getTemplates());
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Meal Planning</h2>
          <p className="text-muted-foreground">Plan your nutrition with recipes and meal plans</p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Create Meal Plan
        </Button>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-2 gap-4">
        <Card className="cursor-pointer hover:bg-muted/50">
          <CardContent className="p-4 text-center">
            <ChefHat className="h-8 w-8 mx-auto mb-2 text-primary" />
            <h3 className="font-medium">Browse Recipes</h3>
            <p className="text-sm text-muted-foreground">Discover healthy recipes</p>
          </CardContent>
        </Card>
        <Card className="cursor-pointer hover:bg-muted/50">
          <CardContent className="p-4 text-center">
            <Calendar className="h-8 w-8 mx-auto mb-2 text-primary" />
            <h3 className="font-medium">Meal Plan Templates</h3>
            <p className="text-sm text-muted-foreground">Ready-made plans</p>
          </CardContent>
        </Card>
      </div>

      {/* My Meal Plans */}
      {mealPlans.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>My Meal Plans</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {mealPlans.slice(0, 3).map((plan: any) => (
                <div key={plan.id} className="flex items-center justify-between p-3 border rounded">
                  <div>
                    <h4 className="font-medium">{plan.name}</h4>
                    <p className="text-sm text-muted-foreground">{plan.duration} days • ${plan.estimatedCost}</p>
                  </div>
                  <Badge variant="outline">Active</Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recipe Categories */}
      <Card>
        <CardHeader>
          <CardTitle>Popular Recipes</CardTitle>
          <CardDescription>Healthy recipes for your fitness goals</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            {recipes.slice(0, 4).map((recipe: any) => (
              <div key={recipe.id} className="flex items-start gap-4 p-3 border rounded-lg">
                <div className="w-16 h-16 bg-muted rounded-lg flex items-center justify-center">
                  <ChefHat className="h-8 w-8" />
                </div>
                <div className="flex-1">
                  <h4 className="font-medium">{recipe.name}</h4>
                  <p className="text-sm text-muted-foreground">{recipe.description}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <Badge variant="outline">{recipe.category}</Badge>
                    <Badge variant="outline">{recipe.totalTime}min</Badge>
                    <Badge variant="outline">{recipe.nutrition.calories} cal</Badge>
                    <span className="text-sm text-muted-foreground">★ {recipe.rating}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Meal Plan Templates */}
      <Card>
        <CardHeader>
          <CardTitle>Meal Plan Templates</CardTitle>
          <CardDescription>Pre-built plans for different goals</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            {templates.map((template: any) => (
              <div key={template.id} className="border rounded-lg p-4">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h3 className="font-semibold">{template.name}</h3>
                    <p className="text-sm text-muted-foreground">{template.description}</p>
                  </div>
                  <Badge variant="outline">{template.goal}</Badge>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex gap-2">
                    <Badge variant="outline">{template.duration} days</Badge>
                    <Badge variant="outline">${template.estimatedCost}</Badge>
                    <span className="text-sm text-muted-foreground">★ {template.rating}</span>
                  </div>
                  <Button size="sm">
                    Use Template
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function CustomWorkoutBuilderContent() {
  const [customWorkouts, setCustomWorkouts] = useState<unknown[]>([]);
  const [templates, setTemplates] = useState<unknown[]>([]);

  useEffect(() => {
    setCustomWorkouts(customWorkoutBuilder.getCustomWorkouts());
    setTemplates(customWorkoutBuilder.getTemplates());
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Custom Workout Builder</h2>
          <p className="text-muted-foreground">Create personalized workout routines</p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Create Workout
        </Button>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-2 gap-4">
        <Card className="cursor-pointer hover:bg-muted/50">
          <CardContent className="p-4 text-center">
            <Wrench className="h-8 w-8 mx-auto mb-2 text-primary" />
            <h3 className="font-medium">Build from Scratch</h3>
            <p className="text-sm text-muted-foreground">Create custom workout</p>
          </CardContent>
        </Card>
        <Card className="cursor-pointer hover:bg-muted/50">
          <CardContent className="p-4 text-center">
            <Dumbbell className="h-8 w-8 mx-auto mb-2 text-primary" />
            <h3 className="font-medium">Use Template</h3>
            <p className="text-sm text-muted-foreground">Start with a template</p>
          </CardContent>
        </Card>
      </div>

      {/* My Custom Workouts */}
      {customWorkouts.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>My Custom Workouts</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {customWorkouts.slice(0, 3).map((workout: any) => (
                <div key={workout.id} className="flex items-center justify-between p-3 border rounded">
                  <div>
                    <h4 className="font-medium">{workout.name}</h4>
                    <p className="text-sm text-muted-foreground">
                      {workout.exercises.length} exercises • {workout.estimatedDuration}min • {workout.difficulty}
                    </p>
                  </div>
                  <Button size="sm" variant="outline">
                    Edit
                  </Button>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Workout Templates */}
      <Card>
        <CardHeader>
          <CardTitle>Workout Templates</CardTitle>
          <CardDescription>Pre-built workouts you can customize</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            {templates.map((template: any) => (
              <div key={template.id} className="border rounded-lg p-4">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h3 className="font-semibold">{template.name}</h3>
                    <p className="text-sm text-muted-foreground">{template.description}</p>
                  </div>
                  <Badge variant="outline">{template.difficulty}</Badge>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex gap-2">
                    <Badge variant="outline">{template.category}</Badge>
                    <Badge variant="outline">{template.estimatedDuration}min</Badge>
                    <Badge variant="outline">{template.exercises.length} exercises</Badge>
                  </div>
                  <Button size="sm">
                    Customize
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function WorkoutStats() {
  const [stats, setStats] = useState({
    totalWorkouts: 0,
    workoutsThisWeek: 0,
    currentStreak: 0,
    totalVolume: 0
  });

  useEffect(() => {
    const workoutStats = workoutTracker.getWorkoutStats();
    setStats(workoutStats);
  }, []);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Your Progress</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-4 text-center">
          <div>
            <p className="text-2xl font-bold text-blue-500">{stats.workoutsThisWeek}</p>
            <p className="text-xs text-muted-foreground">This Week</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-orange-500">{stats.currentStreak}</p>
            <p className="text-xs text-muted-foreground">Day Streak</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

interface QuickWorkoutCardProps {
  title: string;
  description: string;
  exercises: string[];
  onStart: (exercises: { exerciseId: string; targetSets: number; targetReps: number; targetWeight: number }[]) => void;
}

function QuickWorkoutCard({ title, description, exercises, onStart }: QuickWorkoutCardProps) {
  const handleStart = () => {
    const workoutExercises = exercises.map(exerciseId => {
      const exercise = exerciseDatabase.find(ex => ex.id === exerciseId);
      return {
        exerciseId,
        targetSets: 3,
        targetReps: exercise?.equipment === 'Bodyweight' ? 12 : 8,
        targetWeight: exercise?.equipment === 'Bodyweight' ? 0 : 20
      };
    });

    onStart(workoutExercises);
  };

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="font-medium">{title}</p>
            <p className="text-sm text-muted-foreground">{description}</p>
            <div className="flex gap-1 mt-1">
              {exercises.slice(0, 2).map(exerciseId => {
                const exercise = exerciseDatabase.find(ex => ex.id === exerciseId);
                return exercise ? (
                  <Badge key={exerciseId} variant="outline" className="text-xs">
                    {exercise.name}
                  </Badge>
                ) : null;
              })}
              {exercises.length > 2 && (
                <Badge variant="outline" className="text-xs">
                  +{exercises.length - 2} more
                </Badge>
              )}
            </div>
          </div>
          <Button onClick={handleStart}>
            <Play className="h-4 w-4 mr-2" />
            Start
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
