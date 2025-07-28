"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import {
  TrendingUp,
  Calendar,
  Target,
  Activity,
  Zap,
  Dumbbell,
  Apple,
  Award,
  BarChart3
} from "lucide-react";
import { workoutTracker } from "@/lib/workout-tracker";
import { nutritionTracker } from "@/lib/nutrition";
import { exerciseDatabase } from "@/lib/exercises";

export function ProgressCharts() {
  const [timeRange, setTimeRange] = useState<'week' | 'month' | '3months' | 'year'>('month');
  const [selectedExercise, setSelectedExercise] = useState<string>('all');

  return (
    <div className="space-y-4">
      {/* Controls */}
      <Card>
        <CardContent className="p-4">
          <div className="flex gap-4">
            <Select value={timeRange} onValueChange={(value: any) => setTimeRange(value)}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="week">Last Week</SelectItem>
                <SelectItem value="month">Last Month</SelectItem>
                <SelectItem value="3months">3 Months</SelectItem>
                <SelectItem value="year">1 Year</SelectItem>
              </SelectContent>
            </Select>

            <Select value={selectedExercise} onValueChange={setSelectedExercise}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Select Exercise" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Exercises</SelectItem>
                {exerciseDatabase.map(exercise => (
                  <SelectItem key={exercise.id} value={exercise.id}>
                    {exercise.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      <Tabs defaultValue="workout" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="workout">Workout</TabsTrigger>
          <TabsTrigger value="strength">Strength</TabsTrigger>
          <TabsTrigger value="nutrition">Nutrition</TabsTrigger>
          <TabsTrigger value="body">Body Stats</TabsTrigger>
        </TabsList>

        <TabsContent value="workout" className="space-y-4">
          <WorkoutProgressCharts timeRange={timeRange} />
        </TabsContent>

        <TabsContent value="strength" className="space-y-4">
          <StrengthProgressCharts timeRange={timeRange} selectedExercise={selectedExercise} />
        </TabsContent>

        <TabsContent value="nutrition" className="space-y-4">
          <NutritionProgressCharts timeRange={timeRange} />
        </TabsContent>

        <TabsContent value="body" className="space-y-4">
          <BodyStatsCharts timeRange={timeRange} />
        </TabsContent>
      </Tabs>
    </div>
  );
}

function WorkoutProgressCharts({ timeRange }: { timeRange: string }) {
  const [workoutData, setWorkoutData] = useState<any[]>([]);
  const [volumeData, setVolumeData] = useState<any[]>([]);

  useEffect(() => {
    // Generate mock data based on timeRange
    const data = generateWorkoutData(timeRange);
    setWorkoutData(data.workouts);
    setVolumeData(data.volume);
  }, [timeRange]);

  return (
    <>
      {/* Workout Frequency */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Workout Frequency
          </CardTitle>
          <CardDescription>Workouts completed over time</CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={workoutData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Area
                type="monotone"
                dataKey="workouts"
                stroke="#3b82f6"
                fill="#3b82f6"
                fillOpacity={0.3}
              />
            </AreaChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Training Volume */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="h-5 w-5" />
            Training Volume
          </CardTitle>
          <CardDescription>Total weight lifted (sets × reps × weight)</CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={volumeData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line
                type="monotone"
                dataKey="volume"
                stroke="#f59e0b"
                strokeWidth={3}
                dot={{ fill: '#f59e0b' }}
              />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Workout Duration */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Average Workout Duration
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={workoutData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="duration" fill="#10b981" />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </>
  );
}

function StrengthProgressCharts({ timeRange, selectedExercise }: { timeRange: string; selectedExercise: string }) {
  const [strengthData, setStrengthData] = useState<any[]>([]);

  useEffect(() => {
    const data = generateStrengthData(timeRange, selectedExercise);
    setStrengthData(data);
  }, [timeRange, selectedExercise]);

  return (
    <>
      {/* Strength Progress */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Dumbbell className="h-5 w-5" />
            Strength Progress
          </CardTitle>
          <CardDescription>
            {selectedExercise === 'all' ? 'Overall strength gains' : `${exerciseDatabase.find(ex => ex.id === selectedExercise)?.name || 'Exercise'} progress`}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={350}>
            <LineChart data={strengthData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line
                type="monotone"
                dataKey="maxWeight"
                stroke="#dc2626"
                strokeWidth={3}
                name="Max Weight (kg)"
              />
              <Line
                type="monotone"
                dataKey="volume"
                stroke="#7c3aed"
                strokeWidth={2}
                name="Volume"
              />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Personal Records */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Award className="h-5 w-5" />
            Personal Records
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-4">
            {generatePRData().map((pr, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-muted/30 rounded">
                <div>
                  <p className="font-medium">{pr.exercise}</p>
                  <p className="text-sm text-muted-foreground">{pr.date}</p>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-green-600">{pr.weight}kg</p>
                  <Badge variant="secondary">{pr.reps} reps</Badge>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </>
  );
}

function NutritionProgressCharts({ timeRange }: { timeRange: string }) {
  const [nutritionData, setNutritionData] = useState<any[]>([]);
  const [macroDistribution, setMacroDistribution] = useState<any[]>([]);

  useEffect(() => {
    const data = generateNutritionData(timeRange);
    setNutritionData(data.daily);
    setMacroDistribution(data.macros);
  }, [timeRange]);

  const COLORS = ['#ef4444', '#eab308', '#22c55e'];

  return (
    <>
      {/* Calorie Trends */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Apple className="h-5 w-5" />
            Calorie Trends
          </CardTitle>
          <CardDescription>Daily calorie intake vs. goals</CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={nutritionData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line
                type="monotone"
                dataKey="calories"
                stroke="#3b82f6"
                strokeWidth={3}
                name="Calories Consumed"
              />
              <Line
                type="monotone"
                dataKey="goal"
                stroke="#6b7280"
                strokeDasharray="5 5"
                name="Daily Goal"
              />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Macro Distribution */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <BarChart3 className="h-5 w-5" />
            Macro Distribution
          </CardTitle>
          <CardDescription>Average macronutrient breakdown</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={macroDistribution}
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {macroDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>

            <div className="space-y-4">
              {macroDistribution.map((macro, index) => (
                <div key={macro.name} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div
                      className="w-4 h-4 rounded"
                      style={{ backgroundColor: COLORS[index] }}
                    />
                    <span className="font-medium">{macro.name}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-lg font-bold">{macro.value}g</span>
                    <span className="text-sm text-muted-foreground ml-2">
                      ({Math.round((macro.value / macroDistribution.reduce((sum, m) => sum + m.value, 0)) * 100)}%)
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Protein Intake Trend */}
      <Card>
        <CardHeader>
          <CardTitle>Protein Intake Trend</CardTitle>
          <CardDescription>Daily protein consumption</CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={nutritionData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Area
                type="monotone"
                dataKey="protein"
                stroke="#ef4444"
                fill="#ef4444"
                fillOpacity={0.3}
              />
            </AreaChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </>
  );
}

function BodyStatsCharts({ timeRange }: { timeRange: string }) {
  const [bodyData, setBodyData] = useState<any[]>([]);

  useEffect(() => {
    const data = generateBodyStatsData(timeRange);
    setBodyData(data);
  }, [timeRange]);

  return (
    <>
      {/* Weight Trend */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Weight Trend
          </CardTitle>
          <CardDescription>Body weight changes over time</CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={bodyData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Line
                type="monotone"
                dataKey="weight"
                stroke="#8b5cf6"
                strokeWidth={3}
                dot={{ fill: '#8b5cf6' }}
              />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Body Composition */}
      <Card>
        <CardHeader>
          <CardTitle>Body Composition Estimates</CardTitle>
          <CardDescription>Based on measurements and progress photos</CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={bodyData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Area
                type="monotone"
                dataKey="muscle"
                stackId="1"
                stroke="#22c55e"
                fill="#22c55e"
                name="Muscle Mass"
              />
              <Area
                type="monotone"
                dataKey="fat"
                stackId="1"
                stroke="#f59e0b"
                fill="#f59e0b"
                name="Body Fat"
              />
            </AreaChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </>
  );
}

// Helper functions to generate mock data
function generateWorkoutData(timeRange: string) {
  const days = timeRange === 'week' ? 7 : timeRange === 'month' ? 30 : timeRange === '3months' ? 90 : 365;
  const workouts = [];
  const volume = [];

  for (let i = days; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    const dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

    workouts.push({
      date: dateStr,
      workouts: Math.floor(Math.random() * 2), // 0-1 workouts per day
      duration: 45 + Math.floor(Math.random() * 30), // 45-75 minutes
    });

    volume.push({
      date: dateStr,
      volume: 5000 + Math.floor(Math.random() * 3000), // 5000-8000 kg
    });
  }

  return { workouts, volume };
}

function generateStrengthData(timeRange: string, exerciseId: string) {
  const days = timeRange === 'week' ? 7 : timeRange === 'month' ? 30 : 90;
  const data = [];

  let baseWeight = 60;
  let baseVolume = 1000;

  for (let i = days; i >= 0; i -= 3) { // Every 3 days
    const date = new Date();
    date.setDate(date.getDate() - i);
    const dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

    baseWeight += Math.random() * 2; // Gradual increase
    baseVolume += Math.random() * 100;

    data.push({
      date: dateStr,
      maxWeight: Math.round(baseWeight * 10) / 10,
      volume: Math.round(baseVolume),
    });
  }

  return data;
}

function generateNutritionData(timeRange: string) {
  const days = timeRange === 'week' ? 7 : timeRange === 'month' ? 30 : 90;
  const daily = [];

  for (let i = days; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    const dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

    daily.push({
      date: dateStr,
      calories: 1800 + Math.floor(Math.random() * 600),
      protein: 120 + Math.floor(Math.random() * 40),
      carbs: 200 + Math.floor(Math.random() * 100),
      fat: 60 + Math.floor(Math.random() * 30),
      goal: 2200,
    });
  }

  const macros = [
    { name: 'Protein', value: 140 },
    { name: 'Carbs', value: 250 },
    { name: 'Fat', value: 75 },
  ];

  return { daily, macros };
}

function generateBodyStatsData(timeRange: string) {
  const days = timeRange === 'week' ? 7 : timeRange === 'month' ? 30 : 90;
  const data = [];

  let baseWeight = 75;
  let baseMuscle = 35;
  let baseFat = 12;

  for (let i = days; i >= 0; i -= 7) { // Weekly measurements
    const date = new Date();
    date.setDate(date.getDate() - i);
    const dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

    baseWeight += (Math.random() - 0.5) * 0.5; // Slight weight fluctuation
    baseMuscle += Math.random() * 0.1; // Gradual muscle gain
    baseFat -= Math.random() * 0.05; // Gradual fat loss

    data.push({
      date: dateStr,
      weight: Math.round(baseWeight * 10) / 10,
      muscle: Math.round(baseMuscle * 10) / 10,
      fat: Math.round(baseFat * 10) / 10,
    });
  }

  return data;
}

function generatePRData() {
  return [
    { exercise: 'Bench Press', weight: 100, reps: 5, date: '2 days ago' },
    { exercise: 'Squat', weight: 140, reps: 3, date: '1 week ago' },
    { exercise: 'Deadlift', weight: 160, reps: 1, date: '3 days ago' },
    { exercise: 'Pull-up', weight: 15, reps: 8, date: '5 days ago' },
  ];
}
