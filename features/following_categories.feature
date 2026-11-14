Feature: Browse, filter, and follow categories
  As a Columbia or Barnard student
  So that I can see posts on campus life and to connect with other students
  I want to browse All posts, filter by category, and follow categories

  Background:
    Given I am logged in as "student@columbia.edu"
    And an active post exists with title "Looking for Roommate" in category "Housing"
    And an active post exists with title "CS Study Group" in category "Academics"

  Scenario: I see All posts when I arrive
    When I go to the home page
    Then the page heading should be "All posts"
    And I should see "Looking for Roommate"
    And I should see "CS Study Group"

  Scenario: Filter to a category
    When I go to the posts page
    And I click link "Housing"
    Then the page heading should be "Housing"
    And I should see "Looking for Roommate"
    And I should not see "CS Study Group"

  Scenario: Clicking a selected category again returns to All posts
    When I go to the posts page
    And I click link "Housing"
    And I click link "Housing"
    Then the page heading should be "All posts"
    And I should see "CS Study Group"

  Scenario: Follow a category with its bookmark
    When I go to the posts page
    And I press "Follow Housing"
    Then I should see a "Unfollow Housing" button
    And the first category should be "Housing"

  Scenario: Following shows only posts from followed categories
    Given I am following the "Housing" category
    When I go to the posts page
    And I click link "Following"
    Then the page heading should be "Following"
    And I should see "Looking for Roommate"
    And I should not see "CS Study Group"

  Scenario: Clicking Following again returns to All posts
    Given I am following the "Housing" category
    When I go to the posts page
    And I click link "Following"
    And I click link "Following"
    Then the page heading should be "All posts"
    And I should see "CS Study Group"

  Scenario: Following with nothing followed shows a prompt
    When I go to the posts page
    And I click link "Following"
    Then I should see "You're not following any categories yet."
    And I should not see "Looking for Roommate"

  Scenario: Follow a category from the prompt
    When I go to the posts page
    And I click link "Following"
    And I press "+ Housing"
    Then the page heading should be "Following"
    And I should see "Looking for Roommate"
    And I should not see "CS Study Group"

  Scenario: Unfollow a category
    Given I am following the "Housing" category
    When I go to the posts page
    And I press "Unfollow Housing"
    Then I should see a "Follow Housing" button
    And the first category should be "Social"

  Scenario: Following a category keeps my current filter
    When I go to the posts page
    And I click link "Academics"
    And I press "Follow Housing"
    Then the page heading should be "Academics"
    And I should see "CS Study Group"
    And I should not see "Looking for Roommate"