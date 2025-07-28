"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
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
  ResponsiveContainer
} from 'recharts';
import {
  Smartphone,
  Activity,
  Heart,
  Footprints,
  Zap,
  TrendingUp,
  Calendar,
  Plus,
  CheckCircle,
  AlertCircle,
  RefreshCw,
  Apple,
  Phone,
  Loader2,
  Settings,
  BarChart3
} from "lucide-react";
import { healthDataSync, HealthDataPoint, WorkoutSession } from "@/lib/health-integration";

export function HealthIntegration() {
  const [connectedServices, setConnectedServices] = useState({
    appleHealth: false,
    googleFit: false
  });
  const [syncStatus, setSyncStatus] = useState<'idle' | 'syncing' | 'success' | 'error'>('idle');
  const [lastSync, setLastSync] = useState<Date | null>(null);
  const [showManualEntry, setShowManualEntry] = useState(false);

  useEffect(() => {
    const services = healthDataSync.getConnectedServices();
    setConnectedServices(services);
  }, []);

  const handleConnectAppleHealth = async () => {
    setSyncStatus('syncing');
    try {
      const success = await healthDataSync.connectAppleHealth();
      if (success) {
        setConnectedServices(prev => ({ ...prev, appleHealth: true }));
        setLastSync(new Date());
        setSyncStatus('success');
      } else {
        setSyncStatus('error');
      }
    } catch (error) {
      setSyncStatus('error');
      console.error('Apple Health connection failed:', error);
    }
  };

  const handleConnectGoogleFit = async () => {
    setSyncStatus('syncing');
    try {
      const success = await healthDataSync.connectGoogleFit();
      if (success) {
        setConnectedServices(prev => ({ ...prev, googleFit: true }));
        setLastSync(new Date());
        setSyncStatus('success');
      } else {
        setSyncStatus('error');
      }
    } catch (error) {
      setSyncStatus('error');
      console.error('Google Fit connection failed:', error);
    }
  };

  const handleDisconnect = (service: 'appleHealth' | 'googleFit') => {
    if (service === 'appleHealth') {
      healthDataSync.disconnectAppleHealth();
      setConnectedServices(prev => ({ ...prev, appleHealth: false }));
    } else {
      healthDataSync.disconnectGoogleFit();
      setConnectedServices(prev => ({ ...prev, googleFit: false }));
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Health Integration</h2>
          <p className="text-muted-foreground">Connect your health data for comprehensive insights</p>
        </div>
        {lastSync && (
          <div className="text-sm text-muted-foreground">
            Last sync: {lastSync.toLocaleTimeString()}
          </div>
        )}
      </div>

      {/* Connection Status */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <HealthServiceCard
          service="Apple Health"
          icon={<Apple className="h-8 w-8" />}
          connected={connectedServices.appleHealth}
          onConnect={handleConnectAppleHealth}
          onDisconnect={() => handleDisconnect('appleHealth')}
          loading={syncStatus === 'syncing'}
          description="Sync workouts, heart rate, steps, and more from Apple Health"
        />

        <HealthServiceCard
          service="Google Fit"
          icon={<Activity className="h-8 w-8" />}
          connected={connectedServices.googleFit}
          onConnect={handleConnectGoogleFit}
          onDisconnect={() => handleDisconnect('googleFit')}
          loading={syncStatus === 'syncing'}
          description="Connect your Google Fit data for unified tracking"
        />
      </div>

      {/* Quick Stats */}
      <HealthQuickStats />

      {/* Data Charts */}
      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
          <TabsTrigger value="heart">Heart Rate</TabsTrigger>
          <TabsTrigger value="workouts">Workouts</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <HealthOverview />
        </TabsContent>

        <TabsContent value="activity" className="space-y-4">
          <ActivityCharts />
        </TabsContent>

        <TabsContent value="heart" className="space-y-4">
          <HeartRateCharts />
        </TabsContent>

        <TabsContent value="workouts" className="space-y-4">
          <WorkoutSessions />
        </TabsContent>
      </Tabs>

      {/* Manual Entry */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Plus className="h-5 w-5" />
            Manual Data Entry
          </CardTitle>
          <CardDescription>
            Add health data manually when automatic sync isn't available
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={() => setShowManualEntry(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Add Health Data
          </Button>
        </CardContent>
      </Card>

      {/* Manual Entry Dialog */}
      <ManualEntryDialog
        open={showManualEntry}
        onClose={() => setShowManualEntry(false)}
      />
    </div>
  );
}

interface HealthServiceCardProps {
  service: string;
  icon: React.ReactNode;
  connected: boolean;
  onConnect: () => void;
  onDisconnect: () => void;
  loading: boolean;
  description: string;
}

function HealthServiceCard({
  service,
  icon,
  connected,
  onConnect,
  onDisconnect,
  loading,
  description
}: HealthServiceCardProps) {
  return (
    <Card className={connected ? "border-green-200 bg-green-50/30" : ""}>
      <CardContent className="p-6">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className={`p-2 rounded-lg ${connected ? 'bg-green-100 text-green-600' : 'bg-muted text-muted-foreground'}`}>
              {icon}
            </div>
            <div>
              <h3 className="font-semibold">{service}</h3>
              <p className="text-sm text-muted-foreground">{description}</p>
            </div>
          </div>

          <div className="flex flex-col items-end gap-2">
            {connected ? (
              <Badge variant="secondary" className="bg-green-100 text-green-700">
                <CheckCircle className="h-3 w-3 mr-1" />
                Connected
              </Badge>
            ) : (
              <Badge variant="outline">
                Not Connected
              </Badge>
            )}

            {connected ? (
              <Button
                variant="outline"
                size="sm"
                onClick={onDisconnect}
              >
                Disconnect
              </Button>
            ) : (
              <Button
                size="sm"
                onClick={onConnect}
                disabled={loading}
              >
                {loading ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Connecting...
                  </>
                ) : (
                  'Connect'
                )}
              </Button>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function HealthQuickStats() {
  const [stats, setStats] = useState({
    steps: 0,
    calories: 0,
    heartRate: 0,
    workouts: 0
  });

  useEffect(() => {
    // Get today's data
    const stepsData = healthDataSync.getStepsData(1);
    const caloriesData = healthDataSync.getCaloriesData(1);
    const heartRateData = healthDataSync.getHeartRateData(1);
    const workoutData = healthDataSync.getWorkoutSessions(1);

    setStats({
      steps: stepsData.reduce((sum, d) => sum + d.value, 0),
      calories: caloriesData.reduce((sum, d) => sum + d.value, 0),
      heartRate: healthDataSync.getDailyAverages('heart_rate', 1),
      workouts: workoutData.length
    });
  }, []);

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      <Card>
        <CardContent className="p-4 text-center">
          <Footprints className="h-6 w-6 mx-auto mb-2 text-blue-500" />
          <p className="text-2xl font-bold">{stats.steps.toLocaleString()}</p>
          <p className="text-sm text-muted-foreground">Steps Today</p>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-4 text-center">
          <Zap className="h-6 w-6 mx-auto mb-2 text-orange-500" />
          <p className="text-2xl font-bold">{stats.calories}</p>
          <p className="text-sm text-muted-foreground">Calories Burned</p>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-4 text-center">
          <Heart className="h-6 w-6 mx-auto mb-2 text-red-500" />
          <p className="text-2xl font-bold">{stats.heartRate}</p>
          <p className="text-sm text-muted-foreground">Avg Heart Rate</p>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-4 text-center">
          <Activity className="h-6 w-6 mx-auto mb-2 text-green-500" />
          <p className="text-2xl font-bold">{stats.workouts}</p>
          <p className="text-sm text-muted-foreground">Workouts Today</p>
        </CardContent>
      </Card>
    </div>
  );
}

function HealthOverview() {
  const [timeRange, setTimeRange] = useState('7');
  const [data, setData] = useState<any[]>([]);

  useEffect(() => {
    const days = parseInt(timeRange);
    const stepsData = healthDataSync.getStepsData(days);
    const caloriesData = healthDataSync.getCaloriesData(days);

    // Combine data by date
    const combinedData = stepsData.map(step => {
      const dateStr = step.timestamp.toLocaleDateString();
      const caloriesForDate = caloriesData.find(cal =>
        cal.timestamp.toLocaleDateString() === dateStr
      );

      return {
        date: dateStr,
        steps: step.value,
        calories: caloriesForDate?.value || 0
      };
    });

    setData(combinedData);
  }, [timeRange]);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold">Health Overview</h3>
        <Select value={timeRange} onValueChange={setTimeRange}>
          <SelectTrigger className="w-32">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="7">7 Days</SelectItem>
            <SelectItem value="14">14 Days</SelectItem>
            <SelectItem value="30">30 Days</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Daily Steps</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={200}>
              <AreaChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Area
                  type="monotone"
                  dataKey="steps"
                  stroke="#3b82f6"
                  fill="#3b82f6"
                  fillOpacity={0.3}
                />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Calories Burned</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="calories" fill="#f59e0b" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function ActivityCharts() {
  const [stepsData, setStepsData] = useState<any[]>([]);

  useEffect(() => {
    const data = healthDataSync.getStepsData(7);
    const chartData = data.map(d => ({
      date: d.timestamp.toLocaleDateString(),
      steps: d.value,
      goal: 10000 // Daily goal
    }));
    setStepsData(chartData);
  }, []);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Activity Tracking</CardTitle>
        <CardDescription>Your step count vs. daily goal</CardDescription>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={stepsData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="steps" fill="#22c55e" />
            <Line
              type="monotone"
              dataKey="goal"
              stroke="#6b7280"
              strokeDasharray="5 5"
            />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

function HeartRateCharts() {
  const [heartRateData, setHeartRateData] = useState<any[]>([]);

  useEffect(() => {
    const data = healthDataSync.getHeartRateData(7);
    const chartData = data.map(d => ({
      time: d.timestamp.toLocaleTimeString(),
      date: d.timestamp.toLocaleDateString(),
      heartRate: d.value
    }));
    setHeartRateData(chartData);
  }, []);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Heart Rate Trends</CardTitle>
        <CardDescription>Recent heart rate measurements</CardDescription>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={heartRateData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="time" />
            <YAxis domain={[60, 180]} />
            <Tooltip />
            <Line
              type="monotone"
              dataKey="heartRate"
              stroke="#ef4444"
              strokeWidth={2}
              dot={{ fill: '#ef4444' }}
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

function WorkoutSessions() {
  const [workouts, setWorkouts] = useState<WorkoutSession[]>([]);

  useEffect(() => {
    const sessions = healthDataSync.getWorkoutSessions(30);
    setWorkouts(sessions);
  }, []);

  return (
    <div className="space-y-4">
      <h3 className="font-semibold">Recent Workout Sessions</h3>
      {workouts.length > 0 ? (
        <div className="space-y-2">
          {workouts.map(workout => (
            <Card key={workout.id}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{workout.type}</p>
                    <p className="text-sm text-muted-foreground">
                      {workout.startTime.toLocaleDateString()} • {workout.duration} min
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold">{workout.caloriesBurned} cal</p>
                    {workout.averageHeartRate && (
                      <p className="text-sm text-muted-foreground">
                        {workout.averageHeartRate} avg bpm
                      </p>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-8 text-center">
            <Activity className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
            <p className="text-muted-foreground">No workout sessions found</p>
            <p className="text-sm text-muted-foreground">
              Connect your health apps to see workout data here
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

interface ManualEntryDialogProps {
  open: boolean;
  onClose: () => void;
}

function ManualEntryDialog({ open, onClose }: ManualEntryDialogProps) {
  const [dataType, setDataType] = useState<string>('steps');
  const [value, setValue] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);

  const handleSubmit = () => {
    if (!value || !date) return;

    const dataPoint = {
      type: dataType as any,
      value: parseFloat(value),
      unit: getUnitForType(dataType),
      timestamp: new Date(date)
    };

    healthDataSync.addManualData(dataPoint);
    onClose();
    setValue('');
  };

  const getUnitForType = (type: string): string => {
    const units: { [key: string]: string } = {
      steps: 'count',
      heart_rate: 'bpm',
      calories: 'kcal',
      weight: 'kg',
      sleep: 'hours'
    };
    return units[type] || 'unit';
  };

  if (!open) return null;

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add Health Data</DialogTitle>
          <DialogDescription>
            Manually enter health data for tracking
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium">Data Type</label>
            <Select value={dataType} onValueChange={setDataType}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="steps">Steps</SelectItem>
                <SelectItem value="heart_rate">Heart Rate</SelectItem>
                <SelectItem value="calories">Calories Burned</SelectItem>
                <SelectItem value="weight">Weight</SelectItem>
                <SelectItem value="sleep">Sleep Hours</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <label className="text-sm font-medium">Value</label>
            <Input
              type="number"
              value={value}
              onChange={(e) => setValue(e.target.value)}
              placeholder={`Enter ${dataType} value`}
            />
          </div>

          <div>
            <label className="text-sm font-medium">Date</label>
            <Input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>

          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose} className="flex-1">
              Cancel
            </Button>
            <Button onClick={handleSubmit} className="flex-1">
              Add Data
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
