module MultiUserHelpers
  def switch_to_student(name)
    user = User.find_by!(name: name)
    Capybara.session_name = "student_#{user.id}"
    @current_user = user

    @signed_in_student_ids ||= []
    return if @signed_in_student_ids.include?(user.id)

    login_as(user, scope: :user)
    visit root_path
    @signed_in_student_ids << user.id
  end
end
World(MultiUserHelpers)

After { Capybara.session_name = :default }

Given("the following students exist:") do |table|
  table.hashes.each { |row| create(:user, name: row.fetch("name"), email: row.fetch("email")) }
end

When("I switch to {string}") { |name| switch_to_student(name) }

Given("{string} has a post titled {string} with {int} spot(s)") do |name, title, spots|
  create(:post, title: title, spots_available: spots, user: User.find_by!(name: name))
end

Given("{string} has an event titled {string}") do |name, title|
  create(:post, title: title, category: "Social", user: User.find_by!(name: name),
                event_date: Date.tomorrow, event_time: "7:00 PM", location: "Lerner Hall")
end

When("I reload the page") { visit current_url }

When("I open the notification {string}") do |text|
  visit notifications_path
  find(".notifications_page .notification_item", text: text).click
end

When("I open the chat {string}") do |title|
  visit conversations_path
  click_link title
end

When("I like the post {string}") do |title|
  click_button "Like #{title}"
end

When("I send the message {string}") do |body|
  fill_in "Message", with: body
  click_button "Send"
end

Then("the like count for {string} should be {int}") do |title, count|
  button = find("button.like_button[aria-label$='ike #{title}']")
  expect(button.find(".like_count")).to have_text(count.to_s)
end

Then("I should see a {string} button for {string}") do |label, title|
  expect(page).to have_button("#{label} #{title}")
end

Then("I should see {string} in the chat list") do |text|
  within(".conversation_list") { expect(page).to have_content(text) }
end

Then("I should not see {string} in the chat list") do |text|
  if page.has_css?(".conversation_list")
    within(".conversation_list") { expect(page).not_to have_content(text) }
  else
    expect(page).not_to have_content(text)
  end
end

Then("the message {string} should be from {string}") do |body, author|
  message = find(".message", text: body)
  expect(message.find(".message_author")).to have_text(author)
end

Then("I should see the read receipt {string}") do |receipt|
  expect(find(".message_receipt")).to have_text(receipt)
end

Then("the reply {string} should not have Edit or Delete controls") do |body|
  within(find("#replies .reply", text: body)) do
    expect(page).not_to have_link("Edit")
    expect(page).not_to have_button("Delete")
  end
end
