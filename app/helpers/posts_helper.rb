module PostsHelper
  def expiration_label(time)
    time = time.in_time_zone
    today = Time.zone.today
    date = time.to_date

    day =
      if date == today then "Today"
      elsif date == today + 1 then "Tomorrow"
      elsif date < today + 7 then time.strftime("%a")
      elsif date.year == today.year then time.strftime("%b %-d")
      else time.strftime("%b %-d, %Y")
      end

    "#{day}, #{time.strftime('%-l:%M %p')}"
  end
  
  def time_remaining(time)
    minutes = ((time - Time.current) / 60).ceil
    return "less than a minute" if minutes < 1
    return pluralize(minutes, "minute") if minutes < 60
    
    distance_of_time_in_words(Time.current, time).delete_prefix("about ")
  end

end