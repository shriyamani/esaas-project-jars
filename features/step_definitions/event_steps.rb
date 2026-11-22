Given("an event post exists with title {string} in category {string} on {string} at {string} in {string} authored by {string}") do |title, category, date_str, time_str, location, email|
  author = User.find_by(email: email) || create(:user, email: email)
  event_date =
    case date_str
    when "tomorrow" then Date.tomorrow
    when "yesterday" then Date.yesterday
    else Date.parse(date_str)
    end

  create(
    :post,
    title: title,
    category: category,
    body: "Details for #{title}",
    user: author,
    event_date: event_date,
    event_time: time_str,
    location: location,
    expires_at: 1.month.from_now
  )
end

Given("an event post exists with title {string} in category {string} on {string}") do |title, category, date_str|
  author = User.find_by(email: "student@columbia.edu") || create(:user, email: "student@columbia.edu")
  event_date =
    case date_str
    when "tomorrow" then Date.tomorrow
    when "yesterday" then Date.yesterday
    else Date.parse(date_str)
    end

  create(
    :post,
    title: title,
    category: category,
    body: "Details for #{title}",
    user: author,
    event_date: event_date,
    event_time: "6:00 PM",
    location: "Campus Center",
    expires_at: 1.month.from_now
  )
end

Given("a past event post exists with title {string} in category {string}") do |title, category|
  author = User.find_by(email: "student@columbia.edu") || create(:user, email: "student@columbia.edu")
  post = build(
    :post,
    title: title,
    category: category,
    body: "Past event details",
    user: author,
    event_date: Date.yesterday,
    event_time: "1:00 PM",
    location: "Campus",
    expires_at: 1.month.from_now
  )
  post.save(validate: false)
end

Given("I have RSVP'd to the event {string}") do |title|
  post = Post.find_by!(title: title)
  user = @current_user || User.find_by(email: "student@columbia.edu")
  create(:rsvp, user: user, post: post)
end

Then("the attendee count should be {string}") do |expected_count|
  expect(find(".attendee-count")).to have_content(expected_count)
end

Then("I should see {string} under upcoming events") do |title|
  within("#upcoming-events") do
    expect(page).to have_content(title)
  end
end

Then("I should not see {string} under upcoming events") do |title|
  within("#upcoming-events") do
    expect(page).not_to have_content(title)
  end
end

When("I fill in {string} with tomorrow's date") do |field|
  fill_in field, with: Date.tomorrow.to_s
end

When("I fill in {string} with a custom expiration date") do |field|
  fill_in field, with: 1.week.from_now.strftime("%Y-%m-%dT%H:%M")
end
