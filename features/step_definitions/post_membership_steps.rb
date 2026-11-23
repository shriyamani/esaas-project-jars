
Given("a post titled {string} has {int} available spots") do |title, spots|
  @join_post = create(
    :post,
    title: title,
    spots_available: spots,
    user: create(:user, email: "join-author@barnard.edu")
  )
end

Given("the post with available spots is full") do
  @join_post.spots_available.times do |index|
    user = create(:user, email: "joiner#{index}@columbia.edu")
    create(:post_membership, post: @join_post, user: user)
  end
end

Given("I am the author of the post with available spots") do
  @join_post.update!(user: User.find_by!(email: "student@columbia.edu"))
end

Given("the post with available spots has expired") do
  @join_post.update_column(:expires_at, 1.hour.ago)
end

Given("I have joined the post with available spots") do
  visit post_path(@join_post)
  click_button "Join"
end

When("I open the post with available spots") do
  visit post_path(@join_post)
end

When("I visit the expired post directly") do
  visit post_path(@join_post)
end
