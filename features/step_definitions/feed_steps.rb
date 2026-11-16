Given("an anonymous active post exists with title {string} in category {string}") do |title, category|
  user = User.find_by!(email: "student@columbia.edu")
  create(:post, title: title, body: "Details for #{title}", category: category,
                user: user, anonymous: true, expires_at: 3.days.from_now)
end

Given("{string} has {int} reply/replies") do |title, count|
  create_list(:reply, count, post: Post.find_by!(title: title))
end

Given("{string} was posted {int} days ago") do |title, days|
  Post.find_by!(title: title).update_column(:created_at, days.days.ago)
end

Then("the card for {string} should show {string}") do |title, text|
  expect(find(".post_card", text: title)).to have_content(text)
end

Then("the card for {string} should not show {string}") do |title, text|
  expect(find(".post_card", text: title)).not_to have_content(text)
end

Then("{string} should appear before {string}") do |first, second|
  titles = all(".post_card_title").map(&:text)
  expect(titles).to include(first, second)
  expect(titles.index(first)).to be < titles.index(second)
end

Then("I should not see a {string} button") do |text|
  expect(page).not_to have_button(text)
end
