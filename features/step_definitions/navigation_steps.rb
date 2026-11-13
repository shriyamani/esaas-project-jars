module NavigationHelpers
    def path_to(page_name)
        case page_name
        when "the home page", "the LionDen homepage" then root_path
        when "the log in page"   then new_user_session_path
        when "the posts page"    then posts_path
        when "the new post page" then new_post_path
        when /^the edit page for "(.+)"$/
          Post.find_by!(title: $1).then { |p| edit_post_path(p) }
        when "the FAQ page"      then faq_path
        when "the about page"    then about_path
        when "the contact page"  then contact_path
        else raise "No path mapped for '#{page_name}' in navigation_steps.rb"
        end
    end
end
World(NavigationHelpers)

Given(/^I am on (.+)$/)         { |page_name| visit path_to(page_name) }
When(/^I go to (.+)$/)          { |page_name| visit path_to(page_name) }
Then(/^I should be on (.+)$/)   { |page_name| expect(page).to have_current_path(path_to(page_name)) }

Then("I should see {string}")               { |text| expect(page).to have_content(text) }
Then("I should not see {string}")           { |text| expect(page).not_to have_content(text) }
When("I press {string}")                    { |button| click_button button }
When("I fill in {string} with {string}")    { |field, value| fill_in field, with: value }

When("I follow {string}")                   { |link| click_link link }
Then("I should see a link {string}")        { |text| expect(page).to have_link(text) }
Then("I should see a {string} button")      { |text| expect(page).to have_button(text) }
Then('I should not see a link {string}')    { |text| expect(page).not_to have_link(text) }