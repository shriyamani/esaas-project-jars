class CalendarsController < ApplicationController
  def show
    @tab = params[:tab] == "my" ? "my" : "all"
    @selected_category = params[:category]

    events_scope = Post.active.where.not(event_date: nil)

    if @tab == "my"
      events_scope = events_scope.for_user(current_user)
    end

    if @selected_category.present? && Post::CATEGORIES.include?(@selected_category)
      events_scope = events_scope.where(category: @selected_category)
    end

    @calendar_events = events_scope
    @upcoming_events = events_scope.upcoming
  end
end

