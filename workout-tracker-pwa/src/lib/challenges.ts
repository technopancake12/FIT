export interface Challenge {
  id: string;
  title: string;
  description: string;
  type: 'individual' | 'team' | 'global';
  category: 'workout' | 'nutrition' | 'steps' | 'strength' | 'endurance' | 'consistency';
  difficulty: 'Easy' | 'Medium' | 'Hard' | 'Extreme';
  duration: number; // days
  startDate: Date;
  endDate: Date;
  status: 'upcoming' | 'active' | 'completed' | 'cancelled';

  // Challenge requirements
  requirements: ChallengeRequirement[];

  // Participants
  participants: Participant[];
  maxParticipants?: number;

  // Rewards
  rewards: Reward[];

  // Leaderboard
  leaderboard: LeaderboardEntry[];

  // Meta
  createdBy: string;
  createdAt: Date;
  featured: boolean;
  tags: string[];
  imageUrl?: string;

  // Progress tracking
  progressMetric: 'total' | 'average' | 'best' | 'completion_rate';
  progressUnit: string;
}

export interface ChallengeRequirement {
  id: string;
  type: 'workout_count' | 'exercise_reps' | 'weight_lifted' | 'calories_burned' | 'steps' | 'distance' | 'duration';
  target: number;
  unit: string;
  description: string;
  exerciseId?: string; // for exercise-specific challenges
}

export interface Participant {
  userId: string;
  username: string;
  displayName: string;
  avatar?: string;
  joinedAt: Date;
  progress: { [requirementId: string]: number };
  completed: boolean;
  rank?: number;
  team?: string;
}

export interface Reward {
  id: string;
  type: 'badge' | 'points' | 'title' | 'streak_multiplier';
  name: string;
  description: string;
  value: number;
  imageUrl?: string;
  condition: 'completion' | 'top_3' | 'top_10' | 'participation';
}

export interface LeaderboardEntry {
  userId: string;
  username: string;
  displayName: string;
  avatar?: string;
  score: number;
  progress: number; // percentage
  rank: number;
  team?: string;
  lastUpdate: Date;
}

export interface UserAchievement {
  id: string;
  userId: string;
  challengeId: string;
  rewardId: string;
  earnedAt: Date;
  title: string;
  description: string;
  imageUrl?: string;
}

export interface Team {
  id: string;
  name: string;
  description: string;
  captain: string;
  members: string[];
  totalScore: number;
  averageScore: number;
  createdAt: Date;
  color: string;
  motto?: string;
}

export class ChallengeManager {
  private challenges: Challenge[] = [];
  private userAchievements: UserAchievement[] = [];
  private teams: Team[] = [];
  private currentUserId: string = 'user_1';

  constructor() {
    this.loadFromStorage();
    this.initializeChallenges();
  }

  private loadFromStorage(): void {
    if (typeof window !== 'undefined') {
      const challenges = localStorage.getItem('challenges');
      const achievements = localStorage.getItem('user_achievements');
      const teams = localStorage.getItem('teams');

      if (challenges) {
        this.challenges = JSON.parse(challenges).map((c: any) => ({
          ...c,
          startDate: new Date(c.startDate),
          endDate: new Date(c.endDate),
          createdAt: new Date(c.createdAt),
          participants: c.participants.map((p: any) => ({
            ...p,
            joinedAt: new Date(p.joinedAt)
          }))
        }));
      }

      if (achievements) {
        this.userAchievements = JSON.parse(achievements).map((a: any) => ({
          ...a,
          earnedAt: new Date(a.earnedAt)
        }));
      }

      if (teams) {
        this.teams = JSON.parse(teams).map((t: any) => ({
          ...t,
          createdAt: new Date(t.createdAt)
        }));
      }
    }
  }

  private saveToStorage(): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('challenges', JSON.stringify(this.challenges));
      localStorage.setItem('user_achievements', JSON.stringify(this.userAchievements));
      localStorage.setItem('teams', JSON.stringify(this.teams));
    }
  }

  private initializeChallenges(): void {
    if (this.challenges.length === 0) {
      const now = new Date();

      // Initialize sample challenges
      this.challenges = [
        {
          id: 'challenge_1',
          title: '100 Push-ups Challenge',
          description: 'Complete 100 push-ups in 7 days. Build upper body strength and endurance!',
          type: 'individual',
          category: 'strength',
          difficulty: 'Medium',
          duration: 7,
          startDate: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000), // started 2 days ago
          endDate: new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000), // ends in 5 days
          status: 'active',
          requirements: [
            {
              id: 'req_1',
              type: 'exercise_reps',
              target: 100,
              unit: 'reps',
              description: 'Complete 100 push-ups total',
              exerciseId: 'push-up'
            }
          ],
          participants: [
            {
              userId: 'user_1',
              username: 'you',
              displayName: 'You',
              joinedAt: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000),
              progress: { 'req_1': 45 },
              completed: false
            },
            {
              userId: 'user_2',
              username: 'mikefitness',
              displayName: 'Mike Johnson',
              joinedAt: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000),
              progress: { 'req_1': 78 },
              completed: false
            },
            {
              userId: 'user_3',
              username: 'sarahstrong',
              displayName: 'Sarah Williams',
              joinedAt: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000),
              progress: { 'req_1': 100 },
              completed: true
            }
          ],
          rewards: [
            {
              id: 'reward_1',
              type: 'badge',
              name: 'Push-up Master',
              description: 'Completed 100 push-ups in 7 days',
              value: 100,
              condition: 'completion'
            },
            {
              id: 'reward_2',
              type: 'points',
              name: 'Strength Points',
              description: 'Bonus points for upper body strength',
              value: 50,
              condition: 'completion'
            }
          ],
          leaderboard: [],
          createdBy: 'system',
          createdAt: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000),
          featured: true,
          tags: ['strength', 'upper-body', 'bodyweight'],
          progressMetric: 'total',
          progressUnit: 'reps'
        },
        {
          id: 'challenge_2',
          title: 'Team Cardio Blast',
          description: 'Teams compete to burn the most calories in 2 weeks. Join a team and crush it together!',
          type: 'team',
          category: 'endurance',
          difficulty: 'Hard',
          duration: 14,
          startDate: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000),
          endDate: new Date(now.getTime() + 9 * 24 * 60 * 60 * 1000),
          status: 'active',
          requirements: [
            {
              id: 'req_2',
              type: 'calories_burned',
              target: 5000,
              unit: 'calories',
              description: 'Burn 5000 calories per team member'
            }
          ],
          participants: [
            {
              userId: 'user_1',
              username: 'you',
              displayName: 'You',
              joinedAt: new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000),
              progress: { 'req_2': 1200 },
              completed: false,
              team: 'Fire Dragons'
            },
            {
              userId: 'user_2',
              username: 'mikefitness',
              displayName: 'Mike Johnson',
              joinedAt: new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000),
              progress: { 'req_2': 2100 },
              completed: false,
              team: 'Fire Dragons'
            },
            {
              userId: 'user_3',
              username: 'sarahstrong',
              displayName: 'Sarah Williams',
              joinedAt: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000),
              progress: { 'req_2': 1800 },
              completed: false,
              team: 'Lightning Bolts'
            },
            {
              userId: 'user_4',
              username: 'alexruns',
              displayName: 'Alex Chen',
              joinedAt: new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000),
              progress: { 'req_2': 2400 },
              completed: false,
              team: 'Lightning Bolts'
            }
          ],
          rewards: [
            {
              id: 'reward_3',
              type: 'badge',
              name: 'Cardio Champion',
              description: 'Dominated the team cardio challenge',
              value: 200,
              condition: 'top_3'
            }
          ],
          leaderboard: [],
          createdBy: 'system',
          createdAt: new Date(now.getTime() - 6 * 24 * 60 * 60 * 1000),
          featured: true,
          tags: ['cardio', 'team', 'calories'],
          progressMetric: 'total',
          progressUnit: 'calories'
        },
        {
          id: 'challenge_3',
          title: 'Daily Steps Marathon',
          description: 'Walk 10,000 steps every day for 30 days. Build the habit of daily movement!',
          type: 'global',
          category: 'steps',
          difficulty: 'Easy',
          duration: 30,
          startDate: new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000),
          endDate: new Date(now.getTime() + 20 * 24 * 60 * 60 * 1000),
          status: 'active',
          requirements: [
            {
              id: 'req_3',
              type: 'steps',
              target: 300000, // 10k steps × 30 days
              unit: 'steps',
              description: 'Walk 300,000 steps total (10k per day)'
            }
          ],
          participants: [
            {
              userId: 'user_1',
              username: 'you',
              displayName: 'You',
              joinedAt: new Date(now.getTime() - 8 * 24 * 60 * 60 * 1000),
              progress: { 'req_3': 85000 },
              completed: false
            }
          ],
          maxParticipants: 1000,
          rewards: [
            {
              id: 'reward_4',
              type: 'title',
              name: 'Step Master',
              description: 'Earned by walking 300k steps in 30 days',
              value: 1,
              condition: 'completion'
            }
          ],
          leaderboard: [],
          createdBy: 'system',
          createdAt: new Date(now.getTime() - 12 * 24 * 60 * 60 * 1000),
          featured: false,
          tags: ['steps', 'consistency', 'habit'],
          progressMetric: 'total',
          progressUnit: 'steps'
        }
      ];

      // Initialize teams
      this.teams = [
        {
          id: 'team_1',
          name: 'Fire Dragons',
          description: 'Breathing fire through every workout! 🔥',
          captain: 'user_2',
          members: ['user_1', 'user_2'],
          totalScore: 3300,
          averageScore: 1650,
          createdAt: new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000),
          color: '#ef4444',
          motto: 'Rise from the ashes, stronger than before'
        },
        {
          id: 'team_2',
          name: 'Lightning Bolts',
          description: 'Fast as lightning, strong as thunder! ⚡',
          captain: 'user_3',
          members: ['user_3', 'user_4'],
          totalScore: 4200,
          averageScore: 2100,
          createdAt: new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000),
          color: '#3b82f6',
          motto: 'Speed, strength, victory'
        }
      ];

      this.updateLeaderboards();
      this.saveToStorage();
    }
  }

  // Challenge management
  createChallenge(challenge: Omit<Challenge, 'id' | 'createdAt' | 'leaderboard' | 'participants'>): Challenge {
    const newChallenge: Challenge = {
      ...challenge,
      id: `challenge_${Date.now()}`,
      createdAt: new Date(),
      leaderboard: [],
      participants: []
    };

    this.challenges.push(newChallenge);
    this.saveToStorage();
    return newChallenge;
  }

  joinChallenge(challengeId: string, team?: string): boolean {
    const challenge = this.challenges.find(c => c.id === challengeId);
    if (!challenge) return false;

    // Check if already participating
    if (challenge.participants.some(p => p.userId === this.currentUserId)) {
      return false;
    }

    // Check max participants
    if (challenge.maxParticipants && challenge.participants.length >= challenge.maxParticipants) {
      return false;
    }

    // Add participant
    const participant: Participant = {
      userId: this.currentUserId,
      username: 'you',
      displayName: 'You',
      joinedAt: new Date(),
      progress: {},
      completed: false,
      team
    };

    challenge.participants.push(participant);
    this.updateLeaderboards();
    this.saveToStorage();
    return true;
  }

  leaveChallenge(challengeId: string): boolean {
    const challenge = this.challenges.find(c => c.id === challengeId);
    if (!challenge) return false;

    const participantIndex = challenge.participants.findIndex(p => p.userId === this.currentUserId);
    if (participantIndex === -1) return false;

    challenge.participants.splice(participantIndex, 1);
    this.updateLeaderboards();
    this.saveToStorage();
    return true;
  }

  // Progress tracking
  updateProgress(challengeId: string, requirementId: string, value: number): void {
    const challenge = this.challenges.find(c => c.id === challengeId);
    if (!challenge) return;

    const participant = challenge.participants.find(p => p.userId === this.currentUserId);
    if (!participant) return;

    // Update progress
    participant.progress[requirementId] = (participant.progress[requirementId] || 0) + value;

    // Check if requirement completed
    const requirement = challenge.requirements.find(r => r.id === requirementId);
    if (requirement && participant.progress[requirementId] >= requirement.target) {
      // Check if all requirements completed
      const allCompleted = challenge.requirements.every(req =>
        (participant.progress[req.id] || 0) >= req.target
      );

      if (allCompleted && !participant.completed) {
        participant.completed = true;
        this.awardRewards(challengeId, this.currentUserId);
      }
    }

    this.updateLeaderboards();
    this.saveToStorage();
  }

  private awardRewards(challengeId: string, userId: string): void {
    const challenge = this.challenges.find(c => c.id === challengeId);
    if (!challenge) return;

    // Award completion rewards
    const completionRewards = challenge.rewards.filter(r => r.condition === 'completion');

    completionRewards.forEach(reward => {
      const achievement: UserAchievement = {
        id: `achievement_${Date.now()}_${Math.random()}`,
        userId,
        challengeId,
        rewardId: reward.id,
        earnedAt: new Date(),
        title: reward.name,
        description: reward.description,
        imageUrl: reward.imageUrl
      };

      this.userAchievements.push(achievement);
    });
  }

  private updateLeaderboards(): void {
    this.challenges.forEach(challenge => {
      challenge.leaderboard = challenge.participants
        .map(participant => {
          let score = 0;
          let totalProgress = 0;

          challenge.requirements.forEach(req => {
            const progress = participant.progress[req.id] || 0;
            const progressPercent = Math.min((progress / req.target) * 100, 100);
            totalProgress += progressPercent;
            score += progress;
          });

          const avgProgress = totalProgress / challenge.requirements.length;

          return {
            userId: participant.userId,
            username: participant.username,
            displayName: participant.displayName,
            avatar: participant.avatar,
            score,
            progress: avgProgress,
            rank: 0, // Will be set after sorting
            team: participant.team,
            lastUpdate: new Date()
          };
        })
        .sort((a, b) => {
          if (challenge.progressMetric === 'total') {
            return b.score - a.score;
          } else {
            return b.progress - a.progress;
          }
        })
        .map((entry, index) => ({ ...entry, rank: index + 1 }));
    });
  }

  // Team management
  createTeam(team: Omit<Team, 'id' | 'createdAt' | 'totalScore' | 'averageScore'>): Team {
    const newTeam: Team = {
      ...team,
      id: `team_${Date.now()}`,
      createdAt: new Date(),
      totalScore: 0,
      averageScore: 0
    };

    this.teams.push(newTeam);
    this.saveToStorage();
    return newTeam;
  }

  joinTeam(teamId: string): boolean {
    const team = this.teams.find(t => t.id === teamId);
    if (!team) return false;

    if (!team.members.includes(this.currentUserId)) {
      team.members.push(this.currentUserId);
      this.saveToStorage();
      return true;
    }

    return false;
  }

  leaveTeam(teamId: string): boolean {
    const team = this.teams.find(t => t.id === teamId);
    if (!team) return false;

    const memberIndex = team.members.indexOf(this.currentUserId);
    if (memberIndex !== -1) {
      team.members.splice(memberIndex, 1);
      this.saveToStorage();
      return true;
    }

    return false;
  }

  // Getters
  getActiveChallenges(): Challenge[] {
    return this.challenges.filter(c => c.status === 'active')
      .sort((a, b) => {
        if (a.featured && !b.featured) return -1;
        if (!a.featured && b.featured) return 1;
        return a.endDate.getTime() - b.endDate.getTime();
      });
  }

  getUpcomingChallenges(): Challenge[] {
    return this.challenges.filter(c => c.status === 'upcoming')
      .sort((a, b) => a.startDate.getTime() - b.startDate.getTime());
  }

  getUserChallenges(): Challenge[] {
    return this.challenges.filter(c =>
      c.participants.some(p => p.userId === this.currentUserId)
    );
  }

  getUserAchievements(): UserAchievement[] {
    return this.userAchievements
      .filter(a => a.userId === this.currentUserId)
      .sort((a, b) => b.earnedAt.getTime() - a.earnedAt.getTime());
  }

  getTeams(): Team[] {
    return this.teams.sort((a, b) => b.averageScore - a.averageScore);
  }

  getUserTeams(): Team[] {
    return this.teams.filter(t => t.members.includes(this.currentUserId));
  }

  getChallenge(id: string): Challenge | undefined {
    return this.challenges.find(c => c.id === id);
  }

  getTeam(id: string): Team | undefined {
    return this.teams.find(t => t.id === id);
  }

  // Search and filter
  searchChallenges(query: string): Challenge[] {
    const lowerQuery = query.toLowerCase();
    return this.challenges.filter(challenge =>
      challenge.title.toLowerCase().includes(lowerQuery) ||
      challenge.description.toLowerCase().includes(lowerQuery) ||
      challenge.tags.some(tag => tag.toLowerCase().includes(lowerQuery))
    );
  }

  filterChallenges(filters: {
    type?: string[];
    category?: string[];
    difficulty?: string[];
    status?: string[];
  }): Challenge[] {
    return this.challenges.filter(challenge => {
      if (filters.type && !filters.type.includes(challenge.type)) return false;
      if (filters.category && !filters.category.includes(challenge.category)) return false;
      if (filters.difficulty && !filters.difficulty.includes(challenge.difficulty)) return false;
      if (filters.status && !filters.status.includes(challenge.status)) return false;
      return true;
    });
  }

  // Statistics
  getUserStats(): {
    challengesJoined: number;
    challengesCompleted: number;
    achievementsEarned: number;
    teamsJoined: number;
    totalPoints: number;
  } {
    const challengesJoined = this.getUserChallenges().length;
    const challengesCompleted = this.getUserChallenges().filter(c =>
      c.participants.find(p => p.userId === this.currentUserId)?.completed
    ).length;
    const achievementsEarned = this.getUserAchievements().length;
    const teamsJoined = this.getUserTeams().length;
    const totalPoints = this.userAchievements
      .filter(a => a.userId === this.currentUserId)
      .reduce((sum, achievement) => {
        const challenge = this.challenges.find(c => c.id === achievement.challengeId);
        const reward = challenge?.rewards.find(r => r.id === achievement.rewardId);
        return sum + (reward?.value || 0);
      }, 0);

    return {
      challengesJoined,
      challengesCompleted,
      achievementsEarned,
      teamsJoined,
      totalPoints
    };
  }
}

export const challengeManager = new ChallengeManager();
