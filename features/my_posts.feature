Feature: View my own posts
  As a Columbia or Barnard student
  So that I can keep track of what I have posted
  I want a My Activity page that keeps my posts together

  Background:
    Given I am logged in as "student@columbia.edu"
    And an active post exists with title "Looking for Roommate" in category "Housing"
    And another user has an active post with title "Selling a Desk" in category "Buy/Sell"

  Scenario: My Activity shows only my posts in My posts
    When I go to the posts page
    And I click link "My Activity"
    Then the page heading should be "My Activity"
    And I should see "Looking for Roommate"
    And I should not see "Selling a Desk"

  Scenario: My posts still appear in the main feed
    When I go to the posts page
    Then the page heading should be "All posts"
    And I should see "Looking for Roommate"
    And I should see "Selling a Desk"

  Scenario: My Activity includes joined posts and RSVPs
    When I go to the posts page
    And I click link "My Activity"
    Then the page heading should be "My Activity"
    And I should see "Posts I joined"
    And I should see "My RSVPs"
