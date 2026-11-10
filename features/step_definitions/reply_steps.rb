Given("an active discussion exists") do
  @discussion = create(:post, user: create(:user, email: "author@barnard.edu"), title: "Reply discussion")
end

Given("the discussion has expired") do
  @discussion.update_column(:expires_at, 1.second.ago)
end

When("I open the discussion") { visit post_path(@discussion) }
When("I open the post feed") { visit posts_path }

Then("the discussion replies include {string}") do |body|
  within("#replies") { expect(page).to have_content(body) }
end

Then("the discussion is absent from the feed") do
  expect(page).not_to have_content(@discussion.title)
end

Then("the reply author is anonymous") do
  within("#replies") do
    expect(page).to have_content("Anonymous")
    expect(page).not_to have_content(User.find_by!(email: "reader@columbia.edu").name)
    expect(page).not_to have_content("reader@columbia.edu")
  end
end

Then("the discussion has no replies") do
  expect(@discussion.replies.count).to eq(0)
end

When("I edit my reply") do
  within("#replies") { click_link "Edit" }
end

When("I delete my reply") do
  within("#replies") { click_button "Delete" }
end
