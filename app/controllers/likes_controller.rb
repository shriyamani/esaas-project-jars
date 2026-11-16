class LikesController < ApplicationController
  before_action :set_post

  def create
    @post.likes.find_or_create_by(user: current_user)
    redirect_back fallback_location: post_path(@post)
  rescue ActiveRecord::RecordNotUnique
    redirect_back fallback_location: post_path(@post)
  end

  def destroy
    @post.likes.where(user: current_user).destroy_all
    redirect_back fallback_location: post_path(@post)
  end

  private

  def set_post
    @post = Post.active.find(params[:post_id])
  end
end