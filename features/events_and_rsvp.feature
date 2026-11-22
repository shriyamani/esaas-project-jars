Feature: Event posts and RSVP
  As a Columbia or Barnard student
  In order to coordinate meetups with other students
  I want to create event posts with date, time, and location, and RSVP to events

  Scenario: Create an event post
    Given I am logged in as "student@columbia.edu"
    When I go to the new post page
    And I fill in "Title" with "Campus Fall Picnic"
    And I fill in "Body" with "Join us for snacks on the lawn!"
    And I choose "Social"
    And I choose "Custom"
    And I fill in "Custom expiration" with a custom expiration date
    And I fill in "Event Date" with tomorrow's date
    And I fill in "Event Time" with "4:00 PM"
    And I fill in "Location" with "South Lawn"
    And I press "Create Post"
    Then I should see "Post was successfully created."
    And I should see "Campus Fall Picnic"
    And I should see "South Lawn"
    And I should see "4:00 PM"
    And the attendee count should be "0"
    And I should see a "I'm going" button

  Scenario: RSVP and un-RSVP
    Given I am logged in as "student@columbia.edu"
    And an event post exists with title "Board Game Night" in category "Social" on "tomorrow" at "7:00 PM" in "Lerner Hall" authored by "organizer@columbia.edu"
    When I go to the post page for "Board Game Night"
    Then the attendee count should be "0"
    When I press "I'm going"
    Then I should see "You have RSVP'd to this event."
    And the attendee count should be "1"
    And I should see a "Un-RSVP" button
    When I press "Un-RSVP"
    Then I should see "You have un-RSVP'd from this event."
    And the attendee count should be "0"
    And I should see a "I'm going" button
