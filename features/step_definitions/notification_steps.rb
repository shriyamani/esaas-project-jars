When("I open notifications") do
  find(".notifications_trigger").click
  click_link "View all notifications" if page.has_link?("View all notifications")
end

Then("the notifications bell should show {int} unread") do |count|
  expect(find(".notifications_trigger")["aria-label"]).to eq("Notifications, #{count} unread")
  if count.zero?
    expect(page).not_to have_css(".notifications_badge")
  else
    expect(find(".notifications_badge")).to have_text(count.to_s)
  end
end

Then("the notification for {string} should be unread") do |title|
  expect(find(".notifications_page .notification_item", text: title)[:class].split).to include("is-unread")
end

Then("the notification for {string} should be read") do |title|
  expect(find(".notifications_page .notification_item", text: title)[:class].split).not_to include("is-unread")
end
