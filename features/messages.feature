Feature: Messaging other students
  As a Columbia or Barnard student
  So that I can coordinate privately with other students
  I want to send direct messages on LionDen

  Background:
    Given a user named "Friend Lion" exists with email "friend@barnard.edu"
    And I am logged in as "student@columbia.edu"

  Scenario: Start a chat by email and send a message
    When I go to the messages page
    And I follow "New message"
    And I fill in "Email:" with "friend@barnard.edu"
    And I press "Start chat"
    Then I should see "Friend Lion"
    And I should see "Say hi to start the conversation."
    When I fill in "Message" with "Want to study for the midterm?"
    And I press "Send"
    Then I should see "Want to study for the midterm?"
    And I should see "Sent"

  Scenario: Starting a chat with an unknown email
    When I go to the new message page
    And I fill in "Email:" with "nobody@columbia.edu"
    And I press "Start chat"
    Then I should see "No LionDen account uses that email."

  Scenario: Message a post's author from their avatar
    Given "friend@barnard.edu" has a post titled "Selling a desk"
    When I go to the posts page
    And I open the avatar menu for "Friend Lion"
    And I press "Message Friend Lion"
    And I fill in "Message" with "Is the desk still available?"
    And I press "Send"
    Then I should see "Is the desk still available?"

  Scenario: A new message shows as unread until I open it
    Given "friend@barnard.edu" has sent "student@columbia.edu" the message "Are you coming tonight?"
    When I go to the posts page
    Then the Messages icon should show 1 unread
    When I follow "Messages"
    Then I should see "Are you coming tonight?"
    When I follow "Friend Lion"
    Then the Messages icon should not show an unread count

  Scenario: People I have chatted with appear in Contacts
    Given "friend@barnard.edu" has sent "student@columbia.edu" the message "Hello!"
    When I go to the messages page
    And I follow "Contacts"
    Then I should see "Friend Lion"
    And I should see "friend@barnard.edu"
    When I press "Message Friend Lion"
    Then I should see "Hello!"

  Scenario: Edit a message I just sent
    Given "friend@barnard.edu" has sent "student@columbia.edu" the message "Hi"
    When I go to the messages page
    And I follow "Friend Lion"
    And I fill in "Message" with "See you at Butler at 5"
    And I press "Send"
    And I follow "Edit"
    And I change my message to "See you at Butler at 6"
    And I press "Save"
    Then I should see "See you at Butler at 6"
    And I should see "Edited"
    And I should not see "See you at Butler at 5"
