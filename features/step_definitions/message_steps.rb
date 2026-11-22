Given("a user named {string} exists with email {string}") do |name, email|
  create(:user, name: name, email: email)
end

Given("{string} has sent {string} the message {string}") do |sender_email, recipient_email, body|
  sender = User.find_by!(email: sender_email)
  conversation = Conversation.direct_between(sender, User.find_by!(email: recipient_email))
  create(:message, conversation: conversation, user: sender, body: body)
end

Given("{string} has a post titled {string}") do |email, title|
  create(:post, title: title, user: User.find_by!(email: email))
end

Then("the Messages icon should show {int} unread") do |count|
  expect(find("a.nav_icon[aria-label='Messages'] .nav_badge")).to have_content(count.to_s)
end

Then("the Messages icon should not show an unread count") do
  expect(page).not_to have_css("a.nav_icon[aria-label='Messages'] .nav_badge")
end

When("I open the avatar menu for {string}") do |name|
  find("summary[aria-label='Open menu for #{name}']", match: :first).click
end

When("I change my message to {string}") do |body|
  fill_in "Edit message", with: body
end
