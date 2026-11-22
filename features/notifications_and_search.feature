Feature: Category notifications and post search
  As a student
  I want to hear about posts in categories I follow and find current posts

  Background:
    Given I am logged in as "student@columbia.edu"

  Scenario: Following a category notifies me when another student posts there
    When I go to the posts page
    And I press "Follow Housing"
    And another user has an active post with title "Room near campus" in category "Housing"
    And I go to the posts page
    Then the notifications bell should show 1 unread
    When I open notifications
    Then I should see "New post in Housing: Room near campus"
    And the notification for "Room near campus" should be unread

  Scenario: An unfollowed category does not notify me
    When I go to the posts page
    And I press "Follow Housing"
    And I press "Unfollow Housing"
    And another user has an active post with title "Room near campus" in category "Housing"
    And I go to the posts page
    Then the notifications bell should show 0 unread
    When I open notifications
    Then I should see "No notifications yet."

  Scenario: I can mark new post notifications read
    Given I am following the "Housing" category
    And another user has an active post with title "Room near campus" in category "Housing"
    And another user has an active post with title "Apartment share" in category "Housing"
    When I go to the posts page
    Then the notifications bell should show 2 unread
    When I open notifications
    And I press "Mark all read"
    Then the notifications bell should show 0 unread
    And the notification for "Room near campus" should be read
    And the notification for "Apartment share" should be read

  Scenario: Search finds matching active posts and hides expired ones
    Given an active post exists with title "Campus Orchestra" in category "Social"
    And an active post exists with title "Music meetup" and body "Bring your ORCHESTRA friends" in category "Social"
    And an active post exists with title "Study group" in category "Academics"
    And an expired post exists with title "Orchestra archive" in category "Social"
    When I go to the posts page
    And I fill in "Search posts" with "ORCHESTRA"
    And I press "Search"
    Then the page heading should be "Search results"
    And I should see "Campus Orchestra"
    And I should see "Music meetup"
    And I should not see "Study group"
    And I should not see "Orchestra archive"
