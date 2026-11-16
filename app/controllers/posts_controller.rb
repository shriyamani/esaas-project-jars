class PostsController < ApplicationController
  REPLIES_PREVIEW_COUNT = 5

  before_action :set_active_post, only: [ :show ]
  before_action :set_post, only: [ :edit, :update, :destroy ]
  before_action :authorize_author!, only: [ :edit, :update, :destroy ]

  def index
    @posts = Post.active.preload(:user, :replies, :likes)
    @filter_params = {}

    if params[:feed] == "following"
      followed = current_user.followed_categories
      @posts = @posts.where(category: followed)
      @view_title = "Following"
      @follows_nothing = followed.empty?
      @filter_params = { feed: "following" }
    elsif params[:feed] == "mine"
      @posts = @posts.where(user: current_user)
      @view_title = "My Posts"
      @filter_params = { feed: "mine" }
    elsif Post::CATEGORIES.include?(params[:category])
      @posts = @posts.where(category: params[:category])
      @view_title = params[:category]
      @filter_params = { category: params[:category] }
    else
      @view_title = "All posts"
    end

    @sort = params[:sort] == "trending" ? "trending" : "newest"
    @posts = @sort == "trending" ? @posts.trending : @posts.newest_first
  end

  def show
    all_replies = @post.replies.includes(:user).order(created_at: :desc, id: :desc).to_a
    @replies_total = all_replies.size
    @showing_all_replies = params[:replies] == "all" || @replies_total <= REPLIES_PREVIEW_COUNT
    @replies = @showing_all_replies ? all_replies : all_replies.first(REPLIES_PREVIEW_COUNT)
    @hidden_replies_count = @replies_total - @replies.size
    @first_hidden_reply = all_replies[REPLIES_PREVIEW_COUNT] unless @showing_all_replies
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post was successfully deleted."
  end

  private

  def set_active_post
    @post = Post.active.find(params[:id])
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_author!
    unless @post.user == current_user
      redirect_to posts_path, alert: "You are not authorized to edit this post."
    end
  end

  def post_params
    params.require(:post).permit(
      :title,
      :body,
      :category,
      :anonymous,
      :expiration_preset,
      :custom_expires_at,
      :expires_at
    )
  end
end
