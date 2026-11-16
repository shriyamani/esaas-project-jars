
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

Given("I am following the {string} category") do |category|
  User.find_by!(email: "student@columbia.edu").category_follows.create!(category: category)
end

Then("the page heading should be {string}") do |heading|
  expect(page).to have_css("main h1", text: heading, exact_text: true)
end

Then("the first category should be {string}") do |category|
  labels = all(".category_bar .category_tab .category_label").map(&:text)
  expect(labels.first).to eq(category)
end
