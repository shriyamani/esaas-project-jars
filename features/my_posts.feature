Feature: View my own posts
  As a Columbia or Barnard student
  So that I can keep track of what I have posted
  I want a My Posts view that shows only my posts

  Background:
    Given I am logged in as "student@columbia.edu"
    And an active post exists with title "Looking for Roommate" in category "Housing"
    And another user has an active post with title "Selling a Desk" in category "Buy/Sell"

  Scenario: My Posts shows only my posts
    When I go to the posts page
    And I click link "My Posts"
    Then the page heading should be "My Posts"
    And I should see "Looking for Roommate"
    And I should not see "Selling a Desk"

  Scenario: My posts still appear in the main feed
    When I go to the posts page
    Then the page heading should be "All posts"
    And I should see "Looking for Roommate"
    And I should see "Selling a Desk"

  Scenario: Clicking My Posts again returns to All posts
    When I go to the posts page
    And I click link "My Posts"
    And I click link "My Posts"
    Then the page heading should be "All posts"
    And I should see "Selling a Desk"
