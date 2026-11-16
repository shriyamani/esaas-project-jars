Feature: Post cards on the feed
  As a Columbia or Barnard student
  So that I can see what events are happening on campus
  I want posts shown as cards that I can filter and access

  Background:
    Given I am logged in as "student@columbia.edu"

  Scenario: A card shows who posted, when, and the category
    Given an active post exists with title "CS Study Group" in category "Academics"
    When I go to the posts page
    Then the card for "CS Study Group" should show "Testing Tester"
    And the card for "CS Study Group" should show "less than a minute ago"
    And the card for "CS Study Group" should show "Academics"

  Scenario: An anonymous post's card hides the author
    Given an anonymous active post exists with title "Secret tips" in category "Social"
    When I go to the posts page
    Then the card for "Secret tips" should show "Anonymous"
    And the card for "Secret tips" should not show "Testing Tester"

  Scenario: A card shows how many replies the post has
    Given an active post exists with title "CS Study Group" in category "Academics"
    And "CS Study Group" has 2 replies
    When I go to the posts page
    Then the card for "CS Study Group" should show "2 replies"

  Scenario: Clicking a card opens the post
    Given an active post exists with title "CS Study Group" in category "Academics"
    When I go to the posts page
    And I click link "CS Study Group"
    Then I should see "Details for CS Study Group"

  Scenario: Cards don't show edit or delete controls
    Given an active post exists with title "Not My Post" in category "Social"
    When I go to the posts page
    Then I should not see a link "Edit"
    And I should not see a "Delete" button

  Scenario: Posts are sorted newest first by default
    Given an active post exists with title "Older Post" in category "Social"
    And "Older Post" was posted 2 days ago
    And an active post exists with title "Newer Post" in category "Social"
    When I go to the posts page
    Then "Newer Post" should appear before "Older Post"

  Scenario: Sort by most replies
    Given an active post exists with title "Busy Post" in category "Social"
    And "Busy Post" was posted 2 days ago
    And "Busy Post" has 3 replies
    And an active post exists with title "Quiet Post" in category "Social"
    When I go to the posts page
    Then "Quiet Post" should appear before "Busy Post"
    When I click link "Most replies"
    Then "Busy Post" should appear before "Quiet Post"

  Scenario: Sorting keeps my category filter
    Given an active post exists with title "Roommate search" in category "Housing"
    And "Roommate search" has 1 reply
    And an active post exists with title "CS Study Group" in category "Academics"
    When I go to the posts page
    And I click link "Housing"
    And I click link "Most replies"
    Then the page heading should be "Housing"
    And I should see "Roommate search"
    And I should not see "CS Study Group"
