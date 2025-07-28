export interface HealthDataPoint {
  id: string;
  type: 'heart_rate' | 'steps' | 'calories' | 'weight' | 'body_fat' | 'workout' | 'sleep';
  value: number;
  unit: string;
  timestamp: Date;
  source: 'apple_health' | 'google_fit' | 'manual';
  metadata?: Record<string, any>;
}

export interface WorkoutSession {
  id: string;
  type: string;
  startTime: Date;
  endTime: Date;
  duration: number; // minutes
  caloriesBurned: number;
  averageHeartRate?: number;
  maxHeartRate?: number;
  distance?: number; // meters
  source: 'apple_health' | 'google_fit' | 'fittracker';
}

export interface HealthMetrics {
  steps: HealthDataPoint[];
  heartRate: HealthDataPoint[];
  calories: HealthDataPoint[];
  weight: HealthDataPoint[];
  workouts: WorkoutSession[];
  sleep: HealthDataPoint[];
}

export class HealthDataSync {
  private healthData: HealthMetrics = {
    steps: [],
    heartRate: [],
    calories: [],
    weight: [],
    workouts: [],
    sleep: []
  };

  private isAppleHealthAvailable = false;
  private isGoogleFitAvailable = false;

  constructor() {
    this.checkAvailability();
    this.loadFromStorage();
  }

  private checkAvailability(): void {
    // Check if running on iOS and HealthKit is available
    this.isAppleHealthAvailable = this.isIOS() && 'webkit' in window;

    // Check if Google Fit API is available
    this.isGoogleFitAvailable = typeof window !== 'undefined' && 'gapi' in window;
  }

  private isIOS(): boolean {
    return /iPad|iPhone|iPod/.test(navigator.userAgent);
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('health_data');
      if (stored) {
        const parsed = JSON.parse(stored);
        // Convert date strings back to Date objects
        this.healthData = {
          ...parsed,
          workouts: parsed.workouts?.map((w: any) => ({
            ...w,
            startTime: new Date(w.startTime),
            endTime: new Date(w.endTime)
          })) || [],
          steps: parsed.steps?.map((s: any) => ({ ...s, timestamp: new Date(s.timestamp) })) || [],
          heartRate: parsed.heartRate?.map((h: any) => ({ ...h, timestamp: new Date(h.timestamp) })) || [],
          calories: parsed.calories?.map((c: any) => ({ ...c, timestamp: new Date(c.timestamp) })) || [],
          weight: parsed.weight?.map((w: any) => ({ ...w, timestamp: new Date(w.timestamp) })) || [],
          sleep: parsed.sleep?.map((s: any) => ({ ...s, timestamp: new Date(s.timestamp) })) || []
        };
      }
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('health_data', JSON.stringify(this.healthData));
    }
  }

  // Apple Health Integration
  async connectAppleHealth(): Promise<boolean> {
    if (!this.isAppleHealthAvailable) {
      throw new Error('Apple Health not available on this device');
    }

    try {
      // Request permissions for HealthKit data
      const permissions = {
        read: [
          'HKQuantityTypeIdentifierStepCount',
          'HKQuantityTypeIdentifierHeartRate',
          'HKQuantityTypeIdentifierActiveEnergyBurned',
          'HKQuantityTypeIdentifierBodyMass',
          'HKWorkoutTypeIdentifier',
          'HKCategoryTypeIdentifierSleepAnalysis'
        ],
        write: [
          'HKWorkoutTypeIdentifier',
          'HKQuantityTypeIdentifierActiveEnergyBurned'
        ]
      };

      // Mock Apple Health integration (in real app, use HealthKit plugin)
      await this.mockAppleHealthRequest(permissions);

      // Start syncing data
      await this.syncAppleHealthData();

      return true;
    } catch (error) {
      console.error('Apple Health connection failed:', error);
      return false;
    }
  }

  private async mockAppleHealthRequest(permissions: any): Promise<void> {
    // Simulate permission request
    return new Promise((resolve, reject) => {
      if (confirm('Allow FitTracker to access your Health data?')) {
        resolve();
      } else {
        reject(new Error('User denied permission'));
      }
    });
  }

  private async syncAppleHealthData(): Promise<void> {
    // Mock Apple Health data sync
    const now = new Date();
    const last7Days = Array.from({ length: 7 }, (_, i) => {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      return date;
    });

    // Generate mock data for last 7 days
    last7Days.forEach(date => {
      // Steps
      this.healthData.steps.push({
        id: `steps_${date.getTime()}`,
        type: 'steps',
        value: 7000 + Math.floor(Math.random() * 5000),
        unit: 'count',
        timestamp: date,
        source: 'apple_health'
      });

      // Heart Rate (multiple readings per day)
      for (let i = 0; i < 5; i++) {
        const hrTime = new Date(date);
        hrTime.setHours(8 + i * 3);
        this.healthData.heartRate.push({
          id: `hr_${hrTime.getTime()}`,
          type: 'heart_rate',
          value: 65 + Math.floor(Math.random() * 40),
          unit: 'bpm',
          timestamp: hrTime,
          source: 'apple_health'
        });
      }

      // Calories
      this.healthData.calories.push({
        id: `calories_${date.getTime()}`,
        type: 'calories',
        value: 400 + Math.floor(Math.random() * 600),
        unit: 'kcal',
        timestamp: date,
        source: 'apple_health'
      });

      // Weight (every few days)
      if (Math.random() > 0.6) {
        this.healthData.weight.push({
          id: `weight_${date.getTime()}`,
          type: 'weight',
          value: 70 + Math.floor(Math.random() * 20),
          unit: 'kg',
          timestamp: date,
          source: 'apple_health'
        });
      }
    });

    this.saveToStorage();
  }

  // Google Fit Integration
  async connectGoogleFit(): Promise<boolean> {
    if (!this.isGoogleFitAvailable) {
      throw new Error('Google Fit not available');
    }

    try {
      // Initialize Google API
      await this.initializeGoogleAPI();

      // Request authorization
      const authResponse = await this.requestGoogleFitAuth();

      if (authResponse) {
        await this.syncGoogleFitData();
        return true;
      }

      return false;
    } catch (error) {
      console.error('Google Fit connection failed:', error);
      return false;
    }
  }

  private async initializeGoogleAPI(): Promise<void> {
    // Mock Google API initialization
    return new Promise((resolve) => {
      setTimeout(() => {
        console.log('Google API initialized');
        resolve();
      }, 1000);
    });
  }

  private async requestGoogleFitAuth(): Promise<boolean> {
    // Mock Google Fit authorization
    return new Promise((resolve) => {
      if (confirm('Allow FitTracker to access your Google Fit data?')) {
        resolve(true);
      } else {
        resolve(false);
      }
    });
  }

  private async syncGoogleFitData(): Promise<void> {
    // Mock Google Fit data sync
    const now = new Date();
    const last7Days = Array.from({ length: 7 }, (_, i) => {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      return date;
    });

    // Generate mock Google Fit data
    last7Days.forEach(date => {
      // Steps
      this.healthData.steps.push({
        id: `gfit_steps_${date.getTime()}`,
        type: 'steps',
        value: 6500 + Math.floor(Math.random() * 6000),
        unit: 'count',
        timestamp: date,
        source: 'google_fit'
      });

      // Calories
      this.healthData.calories.push({
        id: `gfit_calories_${date.getTime()}`,
        type: 'calories',
        value: 350 + Math.floor(Math.random() * 700),
        unit: 'kcal',
        timestamp: date,
        source: 'google_fit'
      });

      // Workout sessions
      if (Math.random() > 0.5) {
        const workoutStart = new Date(date);
        workoutStart.setHours(9, 0, 0, 0);
        const workoutEnd = new Date(workoutStart);
        workoutEnd.setMinutes(workoutEnd.getMinutes() + 45);

        this.healthData.workouts.push({
          id: `gfit_workout_${date.getTime()}`,
          type: 'Strength Training',
          startTime: workoutStart,
          endTime: workoutEnd,
          duration: 45,
          caloriesBurned: 300 + Math.floor(Math.random() * 200),
          averageHeartRate: 120 + Math.floor(Math.random() * 40),
          source: 'google_fit'
        });
      }
    });

    this.saveToStorage();
  }

  // Manual data entry
  addManualData(dataPoint: Omit<HealthDataPoint, 'id' | 'source'>): void {
    const newDataPoint: HealthDataPoint = {
      ...dataPoint,
      id: `manual_${Date.now()}`,
      source: 'manual'
    };

    switch (dataPoint.type) {
      case 'steps':
        this.healthData.steps.push(newDataPoint);
        break;
      case 'heart_rate':
        this.healthData.heartRate.push(newDataPoint);
        break;
      case 'calories':
        this.healthData.calories.push(newDataPoint);
        break;
      case 'weight':
        this.healthData.weight.push(newDataPoint);
        break;
      case 'sleep':
        this.healthData.sleep.push(newDataPoint);
        break;
    }

    this.saveToStorage();
  }

  // Sync workout from FitTracker to health platforms
  async syncWorkoutToHealth(workout: {
    type: string;
    startTime: Date;
    endTime: Date;
    caloriesBurned: number;
    exercises: any[];
  }): Promise<void> {
    const workoutSession: WorkoutSession = {
      id: `fittracker_${Date.now()}`,
      type: workout.type,
      startTime: workout.startTime,
      endTime: workout.endTime,
      duration: Math.floor((workout.endTime.getTime() - workout.startTime.getTime()) / 60000),
      caloriesBurned: workout.caloriesBurned,
      source: 'fittracker'
    };

    this.healthData.workouts.push(workoutSession);
    this.saveToStorage();

    // In real implementation, would sync to Apple Health and Google Fit
    console.log('Workout synced to health platforms:', workoutSession);
  }

  // Data getters
  getStepsData(days: number = 7): HealthDataPoint[] {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);
    return this.healthData.steps
      .filter(step => step.timestamp >= cutoff)
      .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
  }

  getHeartRateData(days: number = 7): HealthDataPoint[] {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);
    return this.healthData.heartRate
      .filter(hr => hr.timestamp >= cutoff)
      .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
  }

  getCaloriesData(days: number = 7): HealthDataPoint[] {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);
    return this.healthData.calories
      .filter(cal => cal.timestamp >= cutoff)
      .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
  }

  getWorkoutSessions(days: number = 30): WorkoutSession[] {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);
    return this.healthData.workouts
      .filter(workout => workout.startTime >= cutoff)
      .sort((a, b) => b.startTime.getTime() - a.startTime.getTime());
  }

  getWeightData(days: number = 30): HealthDataPoint[] {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);
    return this.healthData.weight
      .filter(weight => weight.timestamp >= cutoff)
      .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
  }

  // Analytics
  getDailyAverages(type: 'steps' | 'calories' | 'heart_rate', days: number = 7): number {
    let data: HealthDataPoint[] = [];

    switch (type) {
      case 'steps':
        data = this.getStepsData(days);
        break;
      case 'calories':
        data = this.getCaloriesData(days);
        break;
      case 'heart_rate':
        data = this.getHeartRateData(days);
        break;
    }

    if (data.length === 0) return 0;

    const total = data.reduce((sum, point) => sum + point.value, 0);
    return Math.round(total / data.length);
  }

  getConnectedServices(): { appleHealth: boolean; googleFit: boolean } {
    return {
      appleHealth: this.isAppleHealthAvailable,
      googleFit: this.isGoogleFitAvailable
    };
  }

  // Disconnect services
  disconnectAppleHealth(): void {
    this.healthData.steps = this.healthData.steps.filter(s => s.source !== 'apple_health');
    this.healthData.heartRate = this.healthData.heartRate.filter(h => h.source !== 'apple_health');
    this.healthData.calories = this.healthData.calories.filter(c => c.source !== 'apple_health');
    this.healthData.weight = this.healthData.weight.filter(w => w.source !== 'apple_health');
    this.healthData.workouts = this.healthData.workouts.filter(w => w.source !== 'apple_health');
    this.saveToStorage();
  }

  disconnectGoogleFit(): void {
    this.healthData.steps = this.healthData.steps.filter(s => s.source !== 'google_fit');
    this.healthData.heartRate = this.healthData.heartRate.filter(h => h.source !== 'google_fit');
    this.healthData.calories = this.healthData.calories.filter(c => c.source !== 'google_fit');
    this.healthData.weight = this.healthData.weight.filter(w => w.source !== 'google_fit');
    this.healthData.workouts = this.healthData.workouts.filter(w => w.source !== 'google_fit');
    this.saveToStorage();
  }
}

export const healthDataSync = new HealthDataSync();
