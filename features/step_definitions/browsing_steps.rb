
Given("an active post exists with title {string} in category {string}") do |title, category|
  user = User.find_by(email: "student@columbia.edu")

  create(
    :post,
    title: title,
    body: "Details for #{title}",
    category: category,
    user: user,
    expires_at: 3.days.from_now
  )
end

Given("an expired post exists with title {string} in category {string}") do |title, category|
  user = User.find_by(email: "student@columbia.edu")

  post = create(
    :post,
    title: title,
    category: category,
    user: user,
    expires_at: 3.days.from_now
  )

  post.update_column(:expires_at, 1.day.ago)
end
