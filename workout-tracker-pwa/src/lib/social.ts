export interface User {
  id: string;
  username: string;
  displayName: string;
  avatar?: string;
  bio?: string;
  stats: {
    workouts: number;
    followers: number;
    following: number;
    totalVolume: number;
  };
  joinDate: Date;
  isVerified?: boolean;
}

export interface SocialPost {
  id: string;
  userId: string;
  type: 'workout' | 'progress' | 'achievement' | 'general';
  content: string;
  photos: string[];
  workoutData?: {
    exerciseName: string;
    weight: number;
    reps: number;
    sets: number;
    duration?: number;
  };
  achievementData?: {
    type: 'pr' | 'streak' | 'milestone';
    title: string;
    value: string;
  };
  likes: number;
  likedBy: string[];
  comments: Comment[];
  createdAt: Date;
  location?: string;
  tags: string[];
  visibility: 'public' | 'friends' | 'private';
}

export interface Comment {
  id: string;
  userId: string;
  content: string;
  createdAt: Date;
  likes: number;
  likedBy: string[];
  replies?: Comment[];
}

export interface Follow {
  followerId: string;
  followingId: string;
  createdAt: Date;
}

export interface FeedItem extends SocialPost {
  user: User;
  isLiked: boolean;
  isFollowing: boolean;
}

export class SocialManager {
  private posts: SocialPost[] = [];
  private users: User[] = [];
  private follows: Follow[] = [];
  private currentUserId: string = 'user_1'; // Mock current user

  constructor() {
    this.loadFromStorage();
    this.initializeMockData();
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const storedPosts = localStorage.getItem('social_posts');
      const storedUsers = localStorage.getItem('social_users');
      const storedFollows = localStorage.getItem('social_follows');

      if (storedPosts) this.posts = JSON.parse(storedPosts);
      if (storedUsers) this.users = JSON.parse(storedUsers);
      if (storedFollows) this.follows = JSON.parse(storedFollows);
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('social_posts', JSON.stringify(this.posts));
      localStorage.setItem('social_users', JSON.stringify(this.users));
      localStorage.setItem('social_follows', JSON.stringify(this.follows));
    }
  }

  private initializeMockData(): void {
    if (this.users.length === 0) {
      this.users = [
        {
          id: 'user_1',
          username: 'you',
          displayName: 'You',
          bio: 'Fitness enthusiast 💪',
          stats: { workouts: 45, followers: 12, following: 8, totalVolume: 15000 },
          joinDate: new Date('2024-01-15'),
          isVerified: false
        },
        {
          id: 'user_2',
          username: 'mikefitness',
          displayName: 'Mike Johnson',
          bio: 'Personal trainer | Powerlifter 🏋️‍♂️',
          stats: { workouts: 250, followers: 1200, following: 150, totalVolume: 85000 },
          joinDate: new Date('2023-06-10'),
          isVerified: true
        },
        {
          id: 'user_3',
          username: 'sarahstrong',
          displayName: 'Sarah Williams',
          bio: 'Crossfit athlete | Nutrition coach 🥗',
          stats: { workouts: 180, followers: 800, following: 95, totalVolume: 62000 },
          joinDate: new Date('2023-08-22'),
          isVerified: true
        },
        {
          id: 'user_4',
          username: 'alexruns',
          displayName: 'Alex Chen',
          bio: 'Marathon runner | Yoga instructor 🧘‍♀️',
          stats: { workouts: 120, followers: 450, following: 200, totalVolume: 25000 },
          joinDate: new Date('2024-02-01'),
          isVerified: false
        }
      ];
    }

    if (this.posts.length === 0) {
      this.posts = [
        {
          id: 'post_1',
          userId: 'user_2',
          type: 'workout',
          content: 'New PR on deadlifts today! 💀 Form felt perfect and the weight moved smoothly. Training consistency really pays off!',
          photos: [],
          workoutData: {
            exerciseName: 'Deadlift',
            weight: 180,
            reps: 5,
            sets: 3,
            duration: 45
          },
          likes: 24,
          likedBy: ['user_1', 'user_3'],
          comments: [
            {
              id: 'comment_1',
              userId: 'user_3',
              content: 'Beast mode! 🔥 What\'s your next goal?',
              createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
              likes: 3,
              likedBy: ['user_1', 'user_2']
            },
            {
              id: 'comment_2',
              userId: 'user_1',
              content: 'Incredible strength! Any tips for deadlift form?',
              createdAt: new Date(Date.now() - 1 * 60 * 60 * 1000),
              likes: 1,
              likedBy: ['user_2']
            }
          ],
          createdAt: new Date(Date.now() - 3 * 60 * 60 * 1000),
          tags: ['deadlift', 'pr', 'strength'],
          visibility: 'public'
        },
        {
          id: 'post_2',
          userId: 'user_3',
          type: 'achievement',
          content: 'Hit my 100-day workout streak! 🎉 Consistency is everything. Here\'s to the next 100!',
          photos: [],
          achievementData: {
            type: 'streak',
            title: '100 Day Streak',
            value: '100 days'
          },
          likes: 45,
          likedBy: ['user_1', 'user_2', 'user_4'],
          comments: [
            {
              id: 'comment_3',
              userId: 'user_2',
              content: 'Amazing dedication! You\'re an inspiration 💪',
              createdAt: new Date(Date.now() - 30 * 60 * 1000),
              likes: 5,
              likedBy: ['user_1', 'user_3', 'user_4']
            }
          ],
          createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000),
          tags: ['streak', 'milestone', 'motivation'],
          visibility: 'public'
        },
        {
          id: 'post_3',
          userId: 'user_4',
          type: 'progress',
          content: 'Morning yoga session complete! 🧘‍♀️ Starting the day with mindfulness and movement. Today\'s focus was on hip flexibility.',
          photos: [],
          workoutData: {
            exerciseName: 'Yoga Flow',
            weight: 0,
            reps: 1,
            sets: 1,
            duration: 30
          },
          likes: 18,
          likedBy: ['user_1', 'user_3'],
          comments: [],
          createdAt: new Date(Date.now() - 8 * 60 * 60 * 1000),
          tags: ['yoga', 'flexibility', 'mindfulness'],
          visibility: 'public'
        }
      ];
    }

    if (this.follows.length === 0) {
      this.follows = [
        { followerId: 'user_1', followingId: 'user_2', createdAt: new Date() },
        { followerId: 'user_1', followingId: 'user_3', createdAt: new Date() },
        { followerId: 'user_2', followingId: 'user_1', createdAt: new Date() },
        { followerId: 'user_3', followingId: 'user_1', createdAt: new Date() },
        { followerId: 'user_4', followingId: 'user_1', createdAt: new Date() }
      ];
    }

    this.saveToStorage();
  }

  createPost(post: Omit<SocialPost, 'id' | 'likes' | 'likedBy' | 'comments' | 'createdAt'>): SocialPost {
    const newPost: SocialPost = {
      ...post,
      id: `post_${Date.now()}`,
      likes: 0,
      likedBy: [],
      comments: [],
      createdAt: new Date()
    };

    this.posts.unshift(newPost);
    this.saveToStorage();
    return newPost;
  }

  deletePost(postId: string): boolean {
    const postIndex = this.posts.findIndex(post => post.id === postId);
    if (postIndex === -1) return false;

    const post = this.posts[postIndex];
    if (post.userId !== this.currentUserId) return false;

    this.posts.splice(postIndex, 1);
    this.saveToStorage();
    return true;
  }

  likePost(postId: string): boolean {
    const post = this.posts.find(p => p.id === postId);
    if (!post) return false;

    const isLiked = post.likedBy.includes(this.currentUserId);

    if (isLiked) {
      post.likedBy = post.likedBy.filter(id => id !== this.currentUserId);
      post.likes--;
    } else {
      post.likedBy.push(this.currentUserId);
      post.likes++;
    }

    this.saveToStorage();
    return !isLiked;
  }

  addComment(postId: string, content: string): Comment | null {
    const post = this.posts.find(p => p.id === postId);
    if (!post) return null;

    const comment: Comment = {
      id: `comment_${Date.now()}`,
      userId: this.currentUserId,
      content,
      createdAt: new Date(),
      likes: 0,
      likedBy: []
    };

    post.comments.push(comment);
    this.saveToStorage();
    return comment;
  }

  likeComment(postId: string, commentId: string): boolean {
    const post = this.posts.find(p => p.id === postId);
    if (!post) return false;

    const comment = post.comments.find(c => c.id === commentId);
    if (!comment) return false;

    const isLiked = comment.likedBy.includes(this.currentUserId);

    if (isLiked) {
      comment.likedBy = comment.likedBy.filter(id => id !== this.currentUserId);
      comment.likes--;
    } else {
      comment.likedBy.push(this.currentUserId);
      comment.likes++;
    }

    this.saveToStorage();
    return !isLiked;
  }

  followUser(userId: string): boolean {
    if (userId === this.currentUserId) return false;

    const existingFollow = this.follows.find(
      f => f.followerId === this.currentUserId && f.followingId === userId
    );

    if (existingFollow) {
      // Unfollow
      this.follows = this.follows.filter(f => f !== existingFollow);

      // Update user stats
      const user = this.users.find(u => u.id === userId);
      if (user) user.stats.followers--;

      const currentUser = this.users.find(u => u.id === this.currentUserId);
      if (currentUser) currentUser.stats.following--;

      this.saveToStorage();
      return false;
    } else {
      // Follow
      this.follows.push({
        followerId: this.currentUserId,
        followingId: userId,
        createdAt: new Date()
      });

      // Update user stats
      const user = this.users.find(u => u.id === userId);
      if (user) user.stats.followers++;

      const currentUser = this.users.find(u => u.id === this.currentUserId);
      if (currentUser) currentUser.stats.following++;

      this.saveToStorage();
      return true;
    }
  }

  getFeed(): FeedItem[] {
    const followingIds = this.follows
      .filter(f => f.followerId === this.currentUserId)
      .map(f => f.followingId);

    // Include own posts and posts from followed users
    const relevantPosts = this.posts.filter(post =>
      post.userId === this.currentUserId ||
      followingIds.includes(post.userId) ||
      post.visibility === 'public'
    );

    return relevantPosts.map(post => {
      const user = this.users.find(u => u.id === post.userId);
      const isLiked = post.likedBy.includes(this.currentUserId);
      const isFollowing = this.follows.some(
        f => f.followerId === this.currentUserId && f.followingId === post.userId
      );

      return {
        ...post,
        user: user || this.createUnknownUser(post.userId),
        isLiked,
        isFollowing: post.userId === this.currentUserId ? false : isFollowing
      };
    }).sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  getUser(userId: string): User | null {
    return this.users.find(u => u.id === userId) || null;
  }

  getCurrentUser(): User | null {
    return this.getUser(this.currentUserId);
  }

  getUserPosts(userId: string): SocialPost[] {
    return this.posts.filter(post => post.userId === userId)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  searchUsers(query: string): User[] {
    const lowerQuery = query.toLowerCase();
    return this.users.filter(user =>
      user.username.toLowerCase().includes(lowerQuery) ||
      user.displayName.toLowerCase().includes(lowerQuery)
    );
  }

  getFollowers(userId: string): User[] {
    const followerIds = this.follows
      .filter(f => f.followingId === userId)
      .map(f => f.followerId);

    return this.users.filter(user => followerIds.includes(user.id));
  }

  getFollowing(userId: string): User[] {
    const followingIds = this.follows
      .filter(f => f.followerId === userId)
      .map(f => f.followingId);

    return this.users.filter(user => followingIds.includes(user.id));
  }

  isFollowing(userId: string): boolean {
    return this.follows.some(
      f => f.followerId === this.currentUserId && f.followingId === userId
    );
  }

  private createUnknownUser(userId: string): User {
    return {
      id: userId,
      username: 'unknown',
      displayName: 'Unknown User',
      stats: { workouts: 0, followers: 0, following: 0, totalVolume: 0 },
      joinDate: new Date()
    };
  }

  // Mock photo upload (in real app, this would upload to cloud storage)
  uploadPhoto(file: File): Promise<string> {
    return new Promise((resolve) => {
      // Simulate upload delay
      setTimeout(() => {
        const photoUrl = `https://picsum.photos/400/400?random=${Date.now()}`;
        resolve(photoUrl);
      }, 1000);
    });
  }
}

export const socialManager = new SocialManager();
