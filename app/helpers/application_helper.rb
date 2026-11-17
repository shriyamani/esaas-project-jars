module ApplicationHelper
  def short_time_ago(time)
    seconds = (Time.current - time).to_i
    minutes = seconds / 60
    hours   = minutes / 60
    days    = hours / 24

    if minutes < 1     then "Just now"
    elsif hours < 1    then "#{minutes} min ago"
    elsif days < 1     then "#{hours}h ago"
    elsif days < 7     then "#{days}d ago"
    else                    "#{days / 7}w ago"
    end
  end
end