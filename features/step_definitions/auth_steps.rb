When("I sign in with Google as {string}") do |email|
  mock_google_login(email: email)
  visit new_user_session_path
  click_button "Sign in with Google"
end

Given("Google sign-in will fail") do
  OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
end

Given("a user exists with email {string}") do |email|
  create(:user, email: email)
end

Given("I am logged in as {string}") do |email|
  user = User.find_by(email: email) || create(:user, email: email)
  login_as(user, scope: :user)
end

Given("I am not logged in") { logout(:user) }

Then("there should be exactly {int} account(s) for {string}") do |count, email|
  expect(User.where(email: email).count).to eq(count)
end

Then("no account should exist for {string}") do |email|
  expect(User.exists?(email: email)).to be false
end