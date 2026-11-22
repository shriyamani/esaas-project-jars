class RsvpsController < ApplicationController
  before_action :set_post

  def create
    rsvp = @post.rsvps.find_or_initialize_by(user: current_user)
    if rsvp.save
      redirect_to @post, notice: "You have RSVP'd to this event."
    else
      redirect_to @post, alert: rsvp.errors.full_messages.to_sentence
    end
  end

  def destroy
    rsvp = @post.rsvps.find_by(user: current_user)
    rsvp&.destroy
    redirect_to @post, notice: "You have un-RSVP'd from this event.", status: :see_other
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end

