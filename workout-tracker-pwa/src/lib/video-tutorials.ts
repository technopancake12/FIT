export interface VideoTutorial {
  id: string;
  exerciseId: string;
  title: string;
  description: string;
  videoUrl: string;
  thumbnailUrl: string;
  duration: number; // seconds
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  type: 'form_tutorial' | 'common_mistakes' | 'variations' | 'progression' | 'quick_demo';
  instructor: {
    name: string;
    credentials: string;
    avatar?: string;
  };
  keyPoints: string[];
  commonMistakes: string[];
  safetyTips: string[];
  equipment: string[];
  targetMuscles: string[];
  views: number;
  rating: number;
  ratings: number[];
  createdAt: Date;
  updatedAt: Date;
  tags: string[];
  transcript?: string;
  chapters?: VideoChapter[];
}

export interface VideoChapter {
  id: string;
  title: string;
  startTime: number; // seconds
  endTime: number; // seconds
  description: string;
  keyPoint?: string;
}

export interface ExerciseVideoCollection {
  exerciseId: string;
  exerciseName: string;
  formTutorial?: VideoTutorial;
  commonMistakes?: VideoTutorial;
  variations: VideoTutorial[];
  progressions: VideoTutorial[];
  quickDemo?: VideoTutorial;
  totalDuration: number;
  averageRating: number;
}

export interface VideoProgress {
  userId: string;
  videoId: string;
  watchTime: number; // seconds
  completed: boolean;
  lastWatched: Date;
  bookmarked: boolean;
  notes: string;
}

export interface VideoPlaylist {
  id: string;
  name: string;
  description: string;
  videos: string[]; // video IDs
  createdBy: string;
  isPublic: boolean;
  category: string;
  tags: string[];
  createdAt: Date;
  followers: number;
  totalDuration: number;
}

export class VideoTutorialManager {
  private videos: VideoTutorial[] = [];
  private videoProgress: VideoProgress[] = [];
  private playlists: VideoPlaylist[] = [];
  private currentUserId: string = 'user_1';

  constructor() {
    this.loadFromStorage();
    this.initializeVideos();
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const videos = localStorage.getItem('video_tutorials');
      const progress = localStorage.getItem('video_progress');
      const playlists = localStorage.getItem('video_playlists');

      if (videos) {
        this.videos = JSON.parse(videos).map((v: any) => ({
          ...v,
          createdAt: new Date(v.createdAt),
          updatedAt: new Date(v.updatedAt)
        }));
      }

      if (progress) {
        this.videoProgress = JSON.parse(progress).map((p: any) => ({
          ...p,
          lastWatched: new Date(p.lastWatched)
        }));
      }

      if (playlists) {
        this.playlists = JSON.parse(playlists).map((p: any) => ({
          ...p,
          createdAt: new Date(p.createdAt)
        }));
      }
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('video_tutorials', JSON.stringify(this.videos));
      localStorage.setItem('video_progress', JSON.stringify(this.videoProgress));
      localStorage.setItem('video_playlists', JSON.stringify(this.playlists));
    }
  }

  private initializeVideos(): void {
    if (this.videos.length === 0) {
      // Initialize sample video tutorials
      this.videos = [
        {
          id: 'video_1',
          exerciseId: 'push-up',
          title: 'Perfect Push-up Form Tutorial',
          description: 'Learn the fundamentals of proper push-up form to maximize effectiveness and prevent injury.',
          videoUrl: 'https://sample-videos.com/push-up-form.mp4',
          thumbnailUrl: 'https://sample-images.com/push-up-thumb.jpg',
          duration: 180, // 3 minutes
          difficulty: 'Beginner',
          type: 'form_tutorial',
          instructor: {
            name: 'Coach Sarah Martinez',
            credentials: 'NASM-CPT, CSCS',
            avatar: 'https://sample-images.com/coach-sarah.jpg'
          },
          keyPoints: [
            'Keep your body in a straight line from head to heels',
            'Lower your chest to within 1-2 inches of the ground',
            'Keep your elbows at a 45-degree angle to your body',
            'Engage your core throughout the movement',
            'Breathe in on the way down, out on the way up'
          ],
          commonMistakes: [
            'Letting hips sag or pike up',
            'Not going low enough',
            'Flaring elbows too wide',
            'Moving too fast without control',
            'Holding breath during the movement'
          ],
          safetyTips: [
            'Start with modified push-ups if needed',
            'Stop if you feel wrist pain',
            'Warm up shoulders and wrists before starting',
            'Focus on quality over quantity'
          ],
          equipment: ['Bodyweight'],
          targetMuscles: ['Chest', 'Triceps', 'Shoulders'],
          views: 1250,
          rating: 4.8,
          ratings: [5, 5, 4, 5, 5, 4, 5, 4, 5, 5],
          createdAt: new Date('2024-01-15'),
          updatedAt: new Date('2024-01-15'),
          tags: ['push-up', 'form', 'beginner', 'chest'],
          transcript: 'Welcome to this push-up form tutorial. Today we\'ll cover the essential elements of performing a perfect push-up...',
          chapters: [
            {
              id: 'chapter_1',
              title: 'Setup and Starting Position',
              startTime: 0,
              endTime: 45,
              description: 'Learn the proper starting position for push-ups',
              keyPoint: 'Body alignment is crucial for effective push-ups'
            },
            {
              id: 'chapter_2',
              title: 'The Descent',
              startTime: 45,
              endTime: 90,
              description: 'How to lower yourself with control',
              keyPoint: 'Control the negative portion of the movement'
            },
            {
              id: 'chapter_3',
              title: 'The Push',
              startTime: 90,
              endTime: 135,
              description: 'Pushing back to the starting position',
              keyPoint: 'Drive through your palms to return to start'
            },
            {
              id: 'chapter_4',
              title: 'Common Mistakes',
              startTime: 135,
              endTime: 180,
              description: 'What to avoid when doing push-ups',
              keyPoint: 'Avoid these common form errors'
            }
          ]
        },
        {
          id: 'video_2',
          exerciseId: 'squat',
          title: 'Squat Fundamentals: Master Your Form',
          description: 'Complete guide to perfect squat form, from setup to execution.',
          videoUrl: 'https://sample-videos.com/squat-form.mp4',
          thumbnailUrl: 'https://sample-images.com/squat-thumb.jpg',
          duration: 240, // 4 minutes
          difficulty: 'Beginner',
          type: 'form_tutorial',
          instructor: {
            name: 'Dr. Mike Thompson',
            credentials: 'PhD Exercise Science, NSCA-CSCS',
            avatar: 'https://sample-images.com/coach-mike.jpg'
          },
          keyPoints: [
            'Feet shoulder-width apart with toes slightly out',
            'Keep your chest up and core engaged',
            'Descend by pushing hips back first',
            'Knees track over toes',
            'Go down until thighs are parallel to ground',
            'Drive through heels to stand up'
          ],
          commonMistakes: [
            'Knees caving inward',
            'Rising from the balls of feet',
            'Leaning too far forward',
            'Not going deep enough',
            'Rounding the back'
          ],
          safetyTips: [
            'Start with bodyweight before adding load',
            'Warm up thoroughly',
            'Focus on mobility if you can\'t reach depth',
            'Stop if you feel knee or back pain'
          ],
          equipment: ['Bodyweight'],
          targetMuscles: ['Quadriceps', 'Glutes', 'Hamstrings'],
          views: 2100,
          rating: 4.9,
          ratings: [5, 5, 5, 4, 5, 5, 5, 5, 4, 5],
          createdAt: new Date('2024-01-10'),
          updatedAt: new Date('2024-01-10'),
          tags: ['squat', 'form', 'legs', 'beginner'],
          chapters: [
            {
              id: 'chapter_5',
              title: 'Squat Setup',
              startTime: 0,
              endTime: 60,
              description: 'Proper foot position and stance',
              keyPoint: 'Setup determines success'
            },
            {
              id: 'chapter_6',
              title: 'The Descent',
              startTime: 60,
              endTime: 120,
              description: 'How to squat down with proper form',
              keyPoint: 'Hips lead the movement'
            },
            {
              id: 'chapter_7',
              title: 'The Ascent',
              startTime: 120,
              endTime: 180,
              description: 'Standing up from the squat',
              keyPoint: 'Drive through your heels'
            },
            {
              id: 'chapter_8',
              title: 'Troubleshooting',
              startTime: 180,
              endTime: 240,
              description: 'Common issues and solutions',
              keyPoint: 'Address mobility limitations'
            }
          ]
        },
        {
          id: 'video_3',
          exerciseId: 'deadlift',
          title: 'Deadlift: Common Mistakes to Avoid',
          description: 'Learn what NOT to do when deadlifting to stay safe and maximize gains.',
          videoUrl: 'https://sample-videos.com/deadlift-mistakes.mp4',
          thumbnailUrl: 'https://sample-images.com/deadlift-mistakes-thumb.jpg',
          duration: 300, // 5 minutes
          difficulty: 'Intermediate',
          type: 'common_mistakes',
          instructor: {
            name: 'Coach Alex Rivera',
            credentials: 'USAPL Coach, NASM-CPT',
            avatar: 'https://sample-images.com/coach-alex.jpg'
          },
          keyPoints: [
            'Keep the bar close to your body',
            'Maintain neutral spine throughout',
            'Engage lats to keep bar path straight',
            'Drive through heels, not toes',
            'Lock out hips and knees simultaneously'
          ],
          commonMistakes: [
            'Bar drifting away from body',
            'Rounding the back',
            'Looking up during the lift',
            'Hyperextending at the top',
            'Dropping the weight instead of controlling descent'
          ],
          safetyTips: [
            'Start with light weight to learn form',
            'Use proper footwear (flat, stable shoes)',
            'Warm up thoroughly',
            'Don\'t ego lift - leave your ego at the door'
          ],
          equipment: ['Barbell'],
          targetMuscles: ['Hamstrings', 'Glutes', 'Back'],
          views: 890,
          rating: 4.7,
          ratings: [5, 4, 5, 5, 4, 5, 4, 5],
          createdAt: new Date('2024-01-20'),
          updatedAt: new Date('2024-01-20'),
          tags: ['deadlift', 'mistakes', 'safety', 'intermediate'],
          chapters: [
            {
              id: 'chapter_9',
              title: 'Setup Mistakes',
              startTime: 0,
              endTime: 75,
              description: 'Common errors in deadlift setup',
              keyPoint: 'Setup determines lifting success'
            },
            {
              id: 'chapter_10',
              title: 'Mid-Lift Errors',
              startTime: 75,
              endTime: 150,
              description: 'What goes wrong during the lift',
              keyPoint: 'Maintain position throughout'
            },
            {
              id: 'chapter_11',
              title: 'Lockout Problems',
              startTime: 150,
              endTime: 225,
              description: 'Issues at the top of the movement',
              keyPoint: 'Proper lockout technique'
            },
            {
              id: 'chapter_12',
              title: 'Recovery Mistakes',
              startTime: 225,
              endTime: 300,
              description: 'Errors when lowering the weight',
              keyPoint: 'Control the eccentric phase'
            }
          ]
        },
        {
          id: 'video_4',
          exerciseId: 'pull-up',
          title: 'Pull-up Progressions: From Zero to Hero',
          description: 'Step-by-step progression to achieve your first pull-up and beyond.',
          videoUrl: 'https://sample-videos.com/pullup-progressions.mp4',
          thumbnailUrl: 'https://sample-images.com/pullup-progressions-thumb.jpg',
          duration: 420, // 7 minutes
          difficulty: 'Beginner',
          type: 'progression',
          instructor: {
            name: 'Coach Jennifer Lee',
            credentials: 'ACSM-CPT, Gymnastics Coach',
            avatar: 'https://sample-images.com/coach-jennifer.jpg'
          },
          keyPoints: [
            'Build up hanging strength first',
            'Use assistance bands or machines initially',
            'Focus on negative (eccentric) reps',
            'Engage lats and pull elbows down',
            'Practice scapular pull-ups'
          ],
          commonMistakes: [
            'Swinging or using momentum',
            'Not going through full range of motion',
            'Rushing the progression',
            'Neglecting grip strength',
            'Poor shoulder blade engagement'
          ],
          safetyTips: [
            'Build gradually - don\'t rush',
            'Warm up shoulders thoroughly',
            'Use proper grip width',
            'Stop if you feel shoulder pain'
          ],
          equipment: ['Pull-up Bar', 'Resistance Band'],
          targetMuscles: ['Back', 'Biceps', 'Shoulders'],
          views: 1650,
          rating: 4.6,
          ratings: [5, 4, 5, 4, 5, 4, 5, 4, 5],
          createdAt: new Date('2024-01-25'),
          updatedAt: new Date('2024-01-25'),
          tags: ['pull-up', 'progression', 'beginner', 'back'],
          chapters: [
            {
              id: 'chapter_13',
              title: 'Building Foundation',
              startTime: 0,
              endTime: 90,
              description: 'Exercises to build pull-up strength',
              keyPoint: 'Foundation exercises are crucial'
            },
            {
              id: 'chapter_14',
              title: 'Assisted Pull-ups',
              startTime: 90,
              endTime: 180,
              description: 'Using bands and machines for assistance',
              keyPoint: 'Gradually reduce assistance'
            },
            {
              id: 'chapter_15',
              title: 'Negative Reps',
              startTime: 180,
              endTime: 270,
              description: 'Eccentric training for pull-ups',
              keyPoint: 'Control the descent'
            },
            {
              id: 'chapter_16',
              title: 'Your First Pull-up',
              startTime: 270,
              endTime: 360,
              description: 'Achieving that first unassisted rep',
              keyPoint: 'Celebrate every milestone'
            },
            {
              id: 'chapter_17',
              title: 'Beyond the First',
              startTime: 360,
              endTime: 420,
              description: 'Building to multiple reps',
              keyPoint: 'Consistency leads to progress'
            }
          ]
        }
      ];

      // Initialize sample playlists
      this.playlists = [
        {
          id: 'playlist_1',
          name: 'Essential Form Tutorials',
          description: 'Master the basics with these fundamental exercise form videos',
          videos: ['video_1', 'video_2'],
          createdBy: 'system',
          isPublic: true,
          category: 'Form & Technique',
          tags: ['beginner', 'form', 'basics'],
          createdAt: new Date('2024-01-01'),
          followers: 0,
          totalDuration: 420
        },
        {
          id: 'playlist_2',
          name: 'Common Mistakes Series',
          description: 'Learn what NOT to do with these mistake-focused tutorials',
          videos: ['video_3'],
          createdBy: 'system',
          isPublic: true,
          category: 'Safety & Mistakes',
          tags: ['mistakes', 'safety', 'intermediate'],
          createdAt: new Date('2024-01-15'),
          followers: 0,
          totalDuration: 300
        }
      ];

      this.saveToStorage();
    }
  }

  // Video management
  getVideosByExercise(exerciseId: string): ExerciseVideoCollection {
    const exerciseVideos = this.videos.filter(v => v.exerciseId === exerciseId);

    const formTutorial = exerciseVideos.find(v => v.type === 'form_tutorial');
    const commonMistakes = exerciseVideos.find(v => v.type === 'common_mistakes');
    const variations = exerciseVideos.filter(v => v.type === 'variations');
    const progressions = exerciseVideos.filter(v => v.type === 'progression');
    const quickDemo = exerciseVideos.find(v => v.type === 'quick_demo');

    const totalDuration = exerciseVideos.reduce((sum, video) => sum + video.duration, 0);
    const averageRating = exerciseVideos.length > 0
      ? exerciseVideos.reduce((sum, video) => sum + video.rating, 0) / exerciseVideos.length
      : 0;

    return {
      exerciseId,
      exerciseName: this.getExerciseName(exerciseId),
      formTutorial,
      commonMistakes,
      variations,
      progressions,
      quickDemo,
      totalDuration,
      averageRating
    };
  }

  private getExerciseName(exerciseId: string): string {
    // This would normally come from the exercise database
    const exerciseNames: { [key: string]: string } = {
      'push-up': 'Push-up',
      'squat': 'Squat',
      'deadlift': 'Deadlift',
      'pull-up': 'Pull-up',
      'bench-press': 'Bench Press',
      'overhead-press': 'Overhead Press'
    };
    return exerciseNames[exerciseId] || exerciseId;
  }

  getVideo(id: string): VideoTutorial | undefined {
    return this.videos.find(v => v.id === id);
  }

  getFeaturedVideos(): VideoTutorial[] {
    return this.videos
      .sort((a, b) => b.rating - a.rating)
      .slice(0, 6);
  }

  getPopularVideos(): VideoTutorial[] {
    return this.videos
      .sort((a, b) => b.views - a.views)
      .slice(0, 8);
  }

  getRecentVideos(): VideoTutorial[] {
    return this.videos
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, 6);
  }

  // Progress tracking
  updateVideoProgress(videoId: string, watchTime: number, completed: boolean = false): void {
    let progress = this.videoProgress.find(p =>
      p.userId === this.currentUserId && p.videoId === videoId
    );

    if (!progress) {
      progress = {
        userId: this.currentUserId,
        videoId,
        watchTime: 0,
        completed: false,
        lastWatched: new Date(),
        bookmarked: false,
        notes: ''
      };
      this.videoProgress.push(progress);
    }

    progress.watchTime = Math.max(progress.watchTime, watchTime);
    progress.completed = completed || progress.completed;
    progress.lastWatched = new Date();

    // Auto-complete if watched 90% or more
    const video = this.getVideo(videoId);
    if (video && watchTime >= video.duration * 0.9) {
      progress.completed = true;
    }

    this.saveToStorage();
  }

  getVideoProgress(videoId: string): VideoProgress | undefined {
    return this.videoProgress.find(p =>
      p.userId === this.currentUserId && p.videoId === videoId
    );
  }

  toggleBookmark(videoId: string): boolean {
    let progress = this.getVideoProgress(videoId);

    if (!progress) {
      progress = {
        userId: this.currentUserId,
        videoId,
        watchTime: 0,
        completed: false,
        lastWatched: new Date(),
        bookmarked: true,
        notes: ''
      };
      this.videoProgress.push(progress);
    } else {
      progress.bookmarked = !progress.bookmarked;
    }

    this.saveToStorage();
    return progress.bookmarked;
  }

  addVideoNote(videoId: string, note: string): void {
    let progress = this.getVideoProgress(videoId);

    if (!progress) {
      progress = {
        userId: this.currentUserId,
        videoId,
        watchTime: 0,
        completed: false,
        lastWatched: new Date(),
        bookmarked: false,
        notes: note
      };
      this.videoProgress.push(progress);
    } else {
      progress.notes = note;
    }

    this.saveToStorage();
  }

  // Playlist management
  createPlaylist(playlist: Omit<VideoPlaylist, 'id' | 'createdAt' | 'followers' | 'totalDuration'>): VideoPlaylist {
    const totalDuration = playlist.videos.reduce((sum, videoId) => {
      const video = this.getVideo(videoId);
      return sum + (video?.duration || 0);
    }, 0);

    const newPlaylist: VideoPlaylist = {
      ...playlist,
      id: `playlist_${Date.now()}`,
      createdAt: new Date(),
      followers: 0,
      totalDuration
    };

    this.playlists.push(newPlaylist);
    this.saveToStorage();
    return newPlaylist;
  }

  addVideoToPlaylist(playlistId: string, videoId: string): boolean {
    const playlist = this.playlists.find(p => p.id === playlistId);
    if (!playlist || playlist.videos.includes(videoId)) return false;

    playlist.videos.push(videoId);

    // Update total duration
    const video = this.getVideo(videoId);
    if (video) {
      playlist.totalDuration += video.duration;
    }

    this.saveToStorage();
    return true;
  }

  removeVideoFromPlaylist(playlistId: string, videoId: string): boolean {
    const playlist = this.playlists.find(p => p.id === playlistId);
    if (!playlist) return false;

    const videoIndex = playlist.videos.indexOf(videoId);
    if (videoIndex === -1) return false;

    playlist.videos.splice(videoIndex, 1);

    // Update total duration
    const video = this.getVideo(videoId);
    if (video) {
      playlist.totalDuration -= video.duration;
    }

    this.saveToStorage();
    return true;
  }

  getPlaylists(): VideoPlaylist[] {
    return this.playlists.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  getUserPlaylists(): VideoPlaylist[] {
    return this.playlists.filter(p => p.createdBy === this.currentUserId);
  }

  getPlaylist(id: string): VideoPlaylist | undefined {
    return this.playlists.find(p => p.id === id);
  }

  // Search and filtering
  searchVideos(query: string): VideoTutorial[] {
    const lowerQuery = query.toLowerCase();
    return this.videos.filter(video =>
      video.title.toLowerCase().includes(lowerQuery) ||
      video.description.toLowerCase().includes(lowerQuery) ||
      video.tags.some(tag => tag.toLowerCase().includes(lowerQuery)) ||
      video.instructor.name.toLowerCase().includes(lowerQuery)
    );
  }

  filterVideos(filters: {
    difficulty?: string[];
    type?: string[];
    duration?: { min: number; max: number };
    equipment?: string[];
    muscles?: string[];
  }): VideoTutorial[] {
    return this.videos.filter(video => {
      if (filters.difficulty && !filters.difficulty.includes(video.difficulty)) return false;
      if (filters.type && !filters.type.includes(video.type)) return false;

      if (filters.duration) {
        if (video.duration < filters.duration.min || video.duration > filters.duration.max) {
          return false;
        }
      }

      if (filters.equipment && filters.equipment.length > 0) {
        const hasEquipment = video.equipment.some(eq => filters.equipment!.includes(eq));
        if (!hasEquipment) return false;
      }

      if (filters.muscles && filters.muscles.length > 0) {
        const hasTargetMuscle = video.targetMuscles.some(muscle =>
          filters.muscles!.includes(muscle)
        );
        if (!hasTargetMuscle) return false;
      }

      return true;
    });
  }

  // Rating system
  rateVideo(videoId: string, rating: number): boolean {
    if (rating < 1 || rating > 5) return false;

    const video = this.getVideo(videoId);
    if (!video) return false;

    video.ratings.push(rating);
    video.rating = video.ratings.reduce((sum, r) => sum + r, 0) / video.ratings.length;

    this.saveToStorage();
    return true;
  }

  // Analytics
  incrementViews(videoId: string): void {
    const video = this.getVideo(videoId);
    if (video) {
      video.views++;
      this.saveToStorage();
    }
  }

  getUserStats(): {
    videosWatched: number;
    totalWatchTime: number; // minutes
    videosCompleted: number;
    bookmarkedVideos: number;
    playlistsCreated: number;
  } {
    const userProgress = this.videoProgress.filter(p => p.userId === this.currentUserId);

    return {
      videosWatched: userProgress.length,
      totalWatchTime: Math.round(userProgress.reduce((sum, p) => sum + p.watchTime, 0) / 60),
      videosCompleted: userProgress.filter(p => p.completed).length,
      bookmarkedVideos: userProgress.filter(p => p.bookmarked).length,
      playlistsCreated: this.getUserPlaylists().length
    };
  }

  getWatchHistory(): VideoTutorial[] {
    const userProgress = this.videoProgress
      .filter(p => p.userId === this.currentUserId)
      .sort((a, b) => b.lastWatched.getTime() - a.lastWatched.getTime());

    return userProgress
      .map(p => this.getVideo(p.videoId))
      .filter((video): video is VideoTutorial => video !== undefined)
      .slice(0, 10);
  }

  getBookmarkedVideos(): VideoTutorial[] {
    const bookmarkedProgress = this.videoProgress
      .filter(p => p.userId === this.currentUserId && p.bookmarked);

    return bookmarkedProgress
      .map(p => this.getVideo(p.videoId))
      .filter((video): video is VideoTutorial => video !== undefined);
  }
}

export const videoTutorialManager = new VideoTutorialManager();
