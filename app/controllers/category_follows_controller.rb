class CategoryFollowsController < ApplicationController
  def create
    current_user.category_follows.find_or_create_by(category: params[:category])
    redirect_back fallback_location: posts_path
  end

  def destroy
    current_user.category_follows.where(category: params[:category]).destroy_all
    redirect_back fallback_location: posts_path
  end
end