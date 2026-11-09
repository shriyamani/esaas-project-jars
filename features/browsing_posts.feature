
Feature: Browsing posts
  As a Columbia or Barnard student
  In order to find relevant campus information
  I want to browse active posts and filter them by category

  Background:
    Given I am logged in as "student@columbia.edu"

  Scenario: Browse all active posts
    Given an active post exists with title "CS Study Group" in category "Academics"
    And an active post exists with title "Looking for Roommate" in category "Housing"
    When I go to the posts page
    Then I should see "CS Study Group"
    And I should see "Looking for Roommate"

  Scenario: Filter posts to Housing
    Given an active post exists with title "Looking for Roommate" in category "Housing"
    And an active post exists with title "CS Study Group" in category "Academics"
    When I go to the posts page
    And I click link "Housing"
    Then I should see "Looking for Roommate"
    And I should not see "CS Study Group"

  Scenario: Expired posts do not appear
    Given an active post exists with title "Current Event" in category "Social"
    And an expired post exists with title "Old Event" in category "Social"
    When I go to the posts page
    Then I should see "Current Event"
    And I should not see "Old Event"

  Scenario: View a post's details
    Given an active post exists with title "Study Session" in category "Academics"
    When I go to the posts page
    And I click link "Study Session"
    Then I should see "Study Session"
    And I should see "Details for Study Session"
    And I should see "Academics"
