module NavigationHelpers
    def path_to(page_name)
        case page_name
        when "the home page"    then root_path
        when "the log in page"  then new_user_session_path
        else raise "No path mapped for '#{page_name}' in navigation_steps.rb"
        end
    end
end
World(NavigationHelpers)

Given(/^I am on (.+)$/)         { |page_name| visit path_to(page_name) }
When(/^I go to (.+)$/)          { |page_name| visit path_to(page_name) }
Then(/^I should be on (.+)$/)   { |page_name| expect(page).to have_current_path(path_to(page_name)) }

Then("I should see {string}")               { |test| expect(page).to have_content(text)}
Then("I should not see {string}")           { |test| expect(page).not_to have_content(text)}
When("I press {string}")                    { |button| click_button button}
When("I fill in {string} with {string}")    { |field, value| fill_in field, with: value}