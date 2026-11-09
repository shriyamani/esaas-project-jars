When("I select {string} from {string}") do |value, field|
  select value, from: field
end

When("I check {string}") do |field|
  check field
end

When("I uncheck {string}") do |field|
  uncheck field
end

When("I click link {string}") do |link_text|
  click_link link_text
end

Given("a post exists with title {string} authored by {string}") do |title, email|
  user = User.find_by(email: email) || create(:user, email: email)
  create(:post, title: title, user: user)
end

When("I attempt to edit {string}") do |title|
  post = Post.find_by!(title: title)
  visit edit_post_path(post)
end

Then("the post author should be {string}") do |expected_author|
  expect(find(".author-name")).to have_content(expected_author)
end

Then("the post author should not be {string}") do |forbidden_author|
  expect(find(".author-name")).not_to have_content(forbidden_author)
end
