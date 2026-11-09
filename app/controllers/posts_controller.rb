class PostsController < ApplicationController
  before_action :set_active_post, only: [ :show ]
  before_action :set_post, only: [ :edit, :update, :destroy ]
  before_action :authorize_author!, only: [ :edit, :update, :destroy ]

  # allows users to view posts under specific categories, only from predefined categories in the Post model
  def index
    @posts = Post.active.order(created_at: :desc)

    if Post::CATEGORIES.include?(params[:category])
      @posts = @posts.where(category: params[:category])
    end
  end

  def show
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
