return if Rails.env.test?

# Create demo users
users = [
  { name: "Angelina Yeh ", email: "ay2667@columbia.edu" },
  { name: "Shriya Mani", email: "sm5586@barnard.edu" },
  { name: "Janice Wong", email: "jsw2219@columbia.edu" },
  { name: "Ritika Calyanakoti", email: "rc3934@columbia.edu" }
]

users.each do |attributes|
  User.find_or_create_by!(email: attributes[:email]) do |user|
    user.name = attributes[:name]
  end
end

# Create demo posts
posts = [
  {
    title: "Looking for a roommate",
    body: "Looking for a roommate near Columbia for next semester.",
    category: "Housing",
    anonymous: false,
    email: "ay2667@columbia.edu"
  },
  {
    title: "CS study group",
    body: "Anyone want to study together at Butler Library?",
    category: "Academics",
    anonymous: false,
    email: "sm5586@barnard.edu"
  },
  {
    title: "Selling mini fridge",
    body: "Selling a mini fridge for $50.",
    category: "Buy/Sell",
    anonymous: true,
    email: "jsw2219@columbia.edu"
  },
  {
    title: "Weekend campus meetup",
    body: "Planning a book club meeting near campus this weekend.",
    category: "Social",
    anonymous: true,
    email: "rc3934@columbia.edu"
  },
  {
    title: "Travel buddies for Thanksgiving",
    body: "Anyone traveling to Philadelphia for Thanksgiving?",
    category: "Travel",
    anonymous: false,
    email: "ay2667@columbia.edu"
  },
  {
    title: "Help moving furniture",
    body: "Looking for someone to help move a desk this week.",
    category: "Help",
    anonymous: false,
    email: "sm5586@barnard.edu"
  }
]

posts.each do |attributes|
  user = User.find_by!(email: attributes[:email])

  Post.find_or_create_by!(title: attributes[:title], user: user) do |post|
    post.body = attributes[:body]
    post.category = attributes[:category]
    post.anonymous = attributes[:anonymous]
    post.expires_at = 30.days.from_now
  end
end

puts "Seed data created successfully."
