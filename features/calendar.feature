Feature: Calendar and events
  As a Columbia or Barnard student
  In order to plan my schedule and see campus activities
  I want to view events on an integrated calendar and filter them

  Scenario: My event appears in "My events"
    Given I am logged in as "student@columbia.edu"
    And an event post exists with title "Algorithms Workshop" in category "Academics" on "tomorrow" at "2:00 PM" in "Mudd 501" authored by "student@columbia.edu"
    And an event post exists with title "Dance Rehearsal" in category "Social" on "tomorrow" at "6:00 PM" in "Broadway Studio" authored by "dancer@barnard.edu"
    When I go to the calendar page
    Then I should see "Algorithms Workshop"
    And I should see "Dance Rehearsal"
    When I click link "My events"
    Then I should see "Algorithms Workshop"
    And I should not see "Dance Rehearsal"

  Scenario: A past event isn't listed as upcoming
    Given I am logged in as "student@columbia.edu"
    And an event post exists with title "Future Hackathon" in category "Academics" on "tomorrow"
    And a past event post exists with title "Past Meetup" in category "Social"
    When I go to the calendar page
    Then I should see "Future Hackathon" under upcoming events
    And I should not see "Past Meetup" under upcoming events

  Scenario: Filter the calendar by category
    Given I am logged in as "student@columbia.edu"
    And an event post exists with title "Social Party" in category "Social" on "tomorrow"
    And an event post exists with title "Study Group" in category "Academics" on "tomorrow"
    When I go to the calendar page
    And I click link "Social"
    Then I should see "Social Party"
    And I should not see "Study Group"
