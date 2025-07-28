"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Separator } from "@/components/ui/separator";
import {
  Heart,
  MessageCircle,
  Share,
  Camera,
  Image as ImageIcon,
  MoreHorizontal,
  Send,
  Trophy,
  Dumbbell,
  TrendingUp,
  Users,
  Plus,
  X,
  CheckCircle,
  UserPlus,
  UserMinus,
  Loader2
} from "lucide-react";
import { socialManager, FeedItem, SocialPost, User, Comment } from "@/lib/social";

export function SocialFeed() {
  const [feed, setFeed] = useState<FeedItem[]>([]);
  const [showCreatePost, setShowCreatePost] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    const feedData = socialManager.getFeed();
    setFeed(feedData);
  }, [refreshKey]);

  const refreshFeed = () => {
    setRefreshKey(prev => prev + 1);
  };

  return (
    <div className="space-y-4">
      {/* Create Post Button */}
      <Card>
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            <Avatar>
              <AvatarFallback>Y</AvatarFallback>
            </Avatar>
            <Button
              variant="outline"
              className="flex-1 justify-start text-muted-foreground"
              onClick={() => setShowCreatePost(true)}
            >
              Share your workout progress...
            </Button>
            <Button size="icon" onClick={() => setShowCreatePost(true)}>
              <Plus className="h-4 w-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Feed */}
      <div className="space-y-4">
        {feed.map(item => (
          <PostCard
            key={item.id}
            post={item}
            onUpdate={refreshFeed}
          />
        ))}

        {feed.length === 0 && (
          <Card>
            <CardContent className="p-8 text-center">
              <Users className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <h3 className="font-medium mb-2">No posts yet</h3>
              <p className="text-sm text-muted-foreground mb-4">
                Follow other users or create your first post to see content here
              </p>
              <Button onClick={() => setShowCreatePost(true)}>
                <Plus className="h-4 w-4 mr-2" />
                Create First Post
              </Button>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Create Post Dialog */}
      <CreatePostDialog
        isOpen={showCreatePost}
        onClose={() => setShowCreatePost(false)}
        onPostCreated={refreshFeed}
      />
    </div>
  );
}

interface PostCardProps {
  post: FeedItem;
  onUpdate: () => void;
}

function PostCard({ post, onUpdate }: PostCardProps) {
  const [showComments, setShowComments] = useState(false);
  const [newComment, setNewComment] = useState("");
  const [isLiked, setIsLiked] = useState(post.isLiked);
  const [likesCount, setLikesCount] = useState(post.likes);

  const handleLike = () => {
    const newLikedState = socialManager.likePost(post.id);
    setIsLiked(newLikedState);
    setLikesCount(prev => newLikedState ? prev + 1 : prev - 1);
  };

  const handleComment = () => {
    if (!newComment.trim()) return;

    const comment = socialManager.addComment(post.id, newComment);
    if (comment) {
      setNewComment("");
      onUpdate();
    }
  };

  const handleFollow = () => {
    socialManager.followUser(post.userId);
    onUpdate();
  };

  const formatTimeAgo = (date: Date) => {
    const now = new Date();
    const diffInMs = now.getTime() - new Date(date).getTime();
    const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60));

    if (diffInHours < 1) return 'Just now';
    if (diffInHours < 24) return `${diffInHours}h ago`;
    return `${Math.floor(diffInHours / 24)}d ago`;
  };

  return (
    <Card>
      <CardContent className="p-0">
        {/* Post Header */}
        <div className="p-4 pb-0">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Avatar>
                <AvatarImage src={post.user.avatar} />
                <AvatarFallback>{post.user.displayName.slice(0, 2).toUpperCase()}</AvatarFallback>
              </Avatar>
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-medium">{post.user.displayName}</span>
                  {post.user.isVerified && (
                    <CheckCircle className="h-4 w-4 text-blue-500" />
                  )}
                  {post.type === 'workout' && <Dumbbell className="h-3 w-3 text-muted-foreground" />}
                  {post.type === 'achievement' && <Trophy className="h-3 w-3 text-yellow-500" />}
                  {post.type === 'progress' && <TrendingUp className="h-3 w-3 text-green-500" />}
                </div>
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <span>@{post.user.username}</span>
                  <span>•</span>
                  <span>{formatTimeAgo(post.createdAt)}</span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              {post.userId !== socialManager.getCurrentUser()?.id && (
                <Button
                  size="sm"
                  variant={post.isFollowing ? "outline" : "default"}
                  onClick={handleFollow}
                >
                  {post.isFollowing ? (
                    <>
                      <UserMinus className="h-3 w-3 mr-1" />
                      Unfollow
                    </>
                  ) : (
                    <>
                      <UserPlus className="h-3 w-3 mr-1" />
                      Follow
                    </>
                  )}
                </Button>
              )}
              <Button variant="ghost" size="icon">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>

        {/* Post Content */}
        <div className="p-4 pt-3">
          <p className="mb-3">{post.content}</p>

          {/* Workout Data */}
          {post.workoutData && (
            <Card className="mb-3 bg-muted/30">
              <CardContent className="p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{post.workoutData.exerciseName}</p>
                    <p className="text-sm text-muted-foreground">
                      {post.workoutData.weight > 0 && `${post.workoutData.weight}kg × `}
                      {post.workoutData.sets} sets × {post.workoutData.reps} reps
                    </p>
                  </div>
                  {post.workoutData.duration && (
                    <Badge variant="outline">{post.workoutData.duration}min</Badge>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Achievement Data */}
          {post.achievementData && (
            <Card className="mb-3 bg-gradient-to-r from-yellow-50 to-orange-50 border-yellow-200">
              <CardContent className="p-3">
                <div className="flex items-center gap-2">
                  <Trophy className="h-5 w-5 text-yellow-600" />
                  <div>
                    <p className="font-medium text-yellow-800">{post.achievementData.title}</p>
                    <p className="text-sm text-yellow-700">{post.achievementData.value}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Tags */}
          {post.tags.length > 0 && (
            <div className="flex flex-wrap gap-1 mb-3">
              {post.tags.map(tag => (
                <Badge key={tag} variant="secondary" className="text-xs">
                  #{tag}
                </Badge>
              ))}
            </div>
          )}
        </div>

        {/* Post Actions */}
        <div className="px-4 pb-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button
                variant="ghost"
                size="sm"
                onClick={handleLike}
                className={isLiked ? "text-red-500 hover:text-red-600" : ""}
              >
                <Heart className={`h-4 w-4 mr-1 ${isLiked ? 'fill-current' : ''}`} />
                {likesCount}
              </Button>

              <Button
                variant="ghost"
                size="sm"
                onClick={() => setShowComments(!showComments)}
              >
                <MessageCircle className="h-4 w-4 mr-1" />
                {post.comments.length}
              </Button>

              <Button variant="ghost" size="sm">
                <Share className="h-4 w-4 mr-1" />
                Share
              </Button>
            </div>
          </div>
        </div>

        {/* Comments Section */}
        {showComments && (
          <div className="border-t bg-muted/30">
            <div className="p-4 space-y-3">
              {/* Add Comment */}
              <div className="flex gap-3">
                <Avatar className="w-8 h-8">
                  <AvatarFallback>Y</AvatarFallback>
                </Avatar>
                <div className="flex-1 flex gap-2">
                  <Input
                    placeholder="Add a comment..."
                    value={newComment}
                    onChange={(e) => setNewComment(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && handleComment()}
                  />
                  <Button size="icon" onClick={handleComment}>
                    <Send className="h-4 w-4" />
                  </Button>
                </div>
              </div>

              {/* Comments List */}
              {post.comments.map(comment => (
                <CommentItem
                  key={comment.id}
                  comment={comment}
                  postId={post.id}
                  onUpdate={onUpdate}
                />
              ))}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

interface CommentItemProps {
  comment: Comment;
  postId: string;
  onUpdate: () => void;
}

function CommentItem({ comment, postId, onUpdate }: CommentItemProps) {
  const [isLiked, setIsLiked] = useState(comment.likedBy.includes(socialManager.getCurrentUser()?.id || ''));
  const [likesCount, setLikesCount] = useState(comment.likes);

  const user = socialManager.getUser(comment.userId);

  const handleLike = () => {
    const newLikedState = socialManager.likeComment(postId, comment.id);
    setIsLiked(newLikedState);
    setLikesCount(prev => newLikedState ? prev + 1 : prev - 1);
  };

  const formatTimeAgo = (date: Date) => {
    const now = new Date();
    const diffInMs = now.getTime() - new Date(date).getTime();
    const diffInMinutes = Math.floor(diffInMs / (1000 * 60));

    if (diffInMinutes < 1) return 'now';
    if (diffInMinutes < 60) return `${diffInMinutes}m`;
    return `${Math.floor(diffInMinutes / 60)}h`;
  };

  return (
    <div className="flex gap-3">
      <Avatar className="w-8 h-8">
        <AvatarImage src={user?.avatar} />
        <AvatarFallback>{user?.displayName.slice(0, 2).toUpperCase() || 'U'}</AvatarFallback>
      </Avatar>
      <div className="flex-1">
        <div className="bg-background rounded-lg p-3">
          <div className="flex items-center gap-2 mb-1">
            <span className="font-medium text-sm">{user?.displayName || 'Unknown'}</span>
            <span className="text-xs text-muted-foreground">{formatTimeAgo(comment.createdAt)}</span>
          </div>
          <p className="text-sm">{comment.content}</p>
        </div>
        <div className="flex items-center gap-4 mt-1 ml-3">
          <Button
            variant="ghost"
            size="sm"
            onClick={handleLike}
            className={`h-6 px-2 text-xs ${isLiked ? 'text-red-500' : 'text-muted-foreground'}`}
          >
            <Heart className={`h-3 w-3 mr-1 ${isLiked ? 'fill-current' : ''}`} />
            {likesCount > 0 && likesCount}
          </Button>
          <Button variant="ghost" size="sm" className="h-6 px-2 text-xs text-muted-foreground">
            Reply
          </Button>
        </div>
      </div>
    </div>
  );
}

interface CreatePostDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onPostCreated: () => void;
}

function CreatePostDialog({ isOpen, onClose, onPostCreated }: CreatePostDialogProps) {
  const [content, setContent] = useState("");
  const [postType, setPostType] = useState<SocialPost['type']>('general');
  const [photos, setPhotos] = useState<string[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [workoutData, setWorkoutData] = useState({
    exerciseName: '',
    weight: 0,
    reps: 0,
    sets: 0
  });

  const handlePhotoUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (!files) return;

    setIsUploading(true);
    try {
      const uploadPromises = Array.from(files).map(file => socialManager.uploadPhoto(file));
      const uploadedUrls = await Promise.all(uploadPromises);
      setPhotos(prev => [...prev, ...uploadedUrls]);
    } catch (error) {
      console.error('Photo upload failed:', error);
    } finally {
      setIsUploading(false);
    }
  };

  const handleCreatePost = () => {
    if (!content.trim()) return;

    const newPost = socialManager.createPost({
      userId: socialManager.getCurrentUser()?.id || 'user_1',
      type: postType,
      content,
      photos,
      workoutData: postType === 'workout' ? workoutData : undefined,
      tags: [],
      visibility: 'public'
    });

    onPostCreated();
    onClose();

    // Reset form
    setContent("");
    setPostType('general');
    setPhotos([]);
    setWorkoutData({ exerciseName: '', weight: 0, reps: 0, sets: 0 });
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Create Post</DialogTitle>
          <DialogDescription>Share your fitness journey with the community</DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Post Type */}
          <Select value={postType} onValueChange={(value: any) => setPostType(value)}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="general">General Post</SelectItem>
              <SelectItem value="workout">Workout</SelectItem>
              <SelectItem value="progress">Progress Update</SelectItem>
              <SelectItem value="achievement">Achievement</SelectItem>
            </SelectContent>
          </Select>

          {/* Content */}
          <Textarea
            placeholder="What's on your mind?"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            rows={4}
          />

          {/* Workout Data */}
          {postType === 'workout' && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Workout Details</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <Input
                  placeholder="Exercise name"
                  value={workoutData.exerciseName}
                  onChange={(e) => setWorkoutData(prev => ({ ...prev, exerciseName: e.target.value }))}
                />
                <div className="grid grid-cols-3 gap-2">
                  <Input
                    type="number"
                    placeholder="Sets"
                    value={workoutData.sets || ''}
                    onChange={(e) => setWorkoutData(prev => ({ ...prev, sets: parseInt(e.target.value) || 0 }))}
                  />
                  <Input
                    type="number"
                    placeholder="Reps"
                    value={workoutData.reps || ''}
                    onChange={(e) => setWorkoutData(prev => ({ ...prev, reps: parseInt(e.target.value) || 0 }))}
                  />
                  <Input
                    type="number"
                    placeholder="Weight (kg)"
                    value={workoutData.weight || ''}
                    onChange={(e) => setWorkoutData(prev => ({ ...prev, weight: parseFloat(e.target.value) || 0 }))}
                  />
                </div>
              </CardContent>
            </Card>
          )}

          {/* Photos */}
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => document.getElementById('photo-upload')?.click()}
                disabled={isUploading}
              >
                {isUploading ? (
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Camera className="h-4 w-4 mr-2" />
                )}
                Add Photos
              </Button>
              <input
                id="photo-upload"
                type="file"
                accept="image/*"
                multiple
                className="hidden"
                onChange={handlePhotoUpload}
              />
            </div>

            {photos.length > 0 && (
              <div className="grid grid-cols-3 gap-2">
                {photos.map((photo, index) => (
                  <div key={index} className="relative">
                    <img
                      src={photo}
                      alt="Upload"
                      className="w-full h-20 object-cover rounded"
                    />
                    <Button
                      variant="destructive"
                      size="icon"
                      className="absolute -top-2 -right-2 h-6 w-6"
                      onClick={() => setPhotos(prev => prev.filter((_, i) => i !== index))}
                    >
                      <X className="h-3 w-3" />
                    </Button>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose} className="flex-1">
              Cancel
            </Button>
            <Button onClick={handleCreatePost} disabled={!content.trim()} className="flex-1">
              Post
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
