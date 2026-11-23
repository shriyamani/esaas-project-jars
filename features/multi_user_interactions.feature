Feature: Multi-user scenarios
  As a Columbia or Barnard student
  So that I can interact with other students
  I want to see other students' joins, messages, replies, and RSVPs in my own view

  Each student uses their own browser. "I switch to ..." changes which
  student is acting; everything after it is what that student does or sees.

  Background:
    Given the following students exist:
      | name         | email              |
      | Alice Arthur | alice@columbia.edu |
      | Bob Bowman   | bob@barnard.edu    |
      | Carol Chen   | carol@columbia.edu |
    And "Alice Arthur" has a post titled "Uber to JFK" with 2 spots


  Scenario: The author is notified and sees the spot filled when someone joins
    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I press "Join"
    Then I should see "You joined this post."

    When I switch to "Alice Arthur"
    And I go to the posts page
    Then the notifications bell should show 1 unread
    When I open the notification "Bob Bowman joined your post: Uber to JFK"
    Then I should be on the post page for "Uber to JFK"
    And I should see "1 of 2 spots filled"
    When I follow "Open group chat"
    Then I should see "Bob Bowman joined the chat"

  Scenario: Other students see the spot count go up and down
    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I press "Join"

    When I switch to "Carol Chen"
    And I go to the post page for "Uber to JFK"
    Then I should see "1 of 2 spots filled"
    And I should see a "Join" button

    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I press "Leave"

    When I switch to "Carol Chen"
    And I reload the page
    Then I should see "0 of 2 spots filled"

  Scenario: When the last spot is taken, other students can no longer join
    Given "Alice Arthur" has a post titled "Spare concert ticket" with 1 spot
    When I switch to "Bob Bowman"
    And I go to the post page for "Spare concert ticket"
    And I press "Join"

    When I switch to "Carol Chen"
    And I go to the post page for "Spare concert ticket"
    Then I should see "1 of 1 spots filled"
    And I should see "All spots filled"
    And I should not see a "Join" button

  Scenario: Users race for the last event spot
    Given "Alice Arthur" has a post titled "Spare concert ticket" with 1 spot
    When I switch to "Carol Chen"
    And I go to the post page for "Spare concert ticket"
    Then I should see a "Join" button

    When I switch to "Bob Bowman"
    And I go to the post page for "Spare concert ticket"
    And I press "Join"
    Then I should see "You joined this post."

    When I switch to "Carol Chen"
    And I press "Join"
    Then I should see "Unable to join this post. It may be full or expired."
    And I should see "All spots filled"

  Scenario: A freed spot reopens the post for other students
    Given "Alice Arthur" has a post titled "Spare concert ticket" with 1 spot
    When I switch to "Bob Bowman"
    And I go to the post page for "Spare concert ticket"
    And I press "Join"
    And I go to the post page for "Spare concert ticket"
    And I press "Leave"
    Then I should see "You left this post."

    When I switch to "Carol Chen"
    And I go to the post page for "Spare concert ticket"
    Then I should see "0 of 1 spots filled"
    When I press "Join"
    Then I should see "You joined this post."

  Scenario: The author and remaining members see when someone leaves
    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I press "Join"
    When I switch to "Carol Chen"
    And I go to the post page for "Uber to JFK"
    And I press "Join"

    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I press "Leave"

    When I switch to "Alice Arthur"
    And I go to the notifications page
    Then I should see "Bob Bowman left your post: Uber to JFK"

    When I switch to "Carol Chen"
    And I open the chat "Uber to JFK"
    Then I should see "Bob Bowman left the chat"

    When I switch to "Bob Bowman"
    And I go to the messages page
    Then I should not see "Uber to JFK" in the chat list

  Scenario: A group message reaches every user, and the sender sees who read it
    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I press "Join"
    When I switch to "Carol Chen"
    And I go to the post page for "Uber to JFK"
    And I press "Join"

    When I switch to "Bob Bowman"
    And I open the chat "Uber to JFK"
    And I send the message "Meet at the Hamilton gates at 6?"
    Then I should see the read receipt "Sent"

    When I switch to "Carol Chen"
    And I go to the posts page
    Then the Messages icon should show 1 unread
    When I open the chat "Uber to JFK"
    Then the message "Meet at the Hamilton gates at 6?" should be from "Bob Bowman"

    When I switch to "Alice Arthur"
    And I go to the notifications page
    Then I should see "New message in Uber to JFK"

    When I switch to "Bob Bowman"
    And I reload the page
    Then I should see the read receipt "Seen by Carol Chen"

  Scenario: Members see the chat name the author chooses, but cannot rename it
    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I press "Join"

    When I switch to "Alice Arthur"
    And I open the chat "Uber to JFK"
    And I follow "Rename chat"
    And I fill in "Chat name" with "JFK Crew"
    And I press "Save"
    Then I should see "Chat renamed."

    When I switch to "Bob Bowman"
    And I go to the messages page
    Then I should see "JFK Crew" in the chat list
    When I open the chat "JFK Crew"
    Then I should not see a link "Rename chat"

  Scenario: A direct message shows up for the recipient, and the sender sees it was read
    When I switch to "Bob Bowman"
    And I go to the new message page
    And I fill in "Email:" with "alice@columbia.edu"
    And I press "Start chat"
    And I send the message "Is there room for a big suitcase?"
    Then I should see the read receipt "Sent"

    When I switch to "Alice Arthur"
    And I go to the posts page
    Then the Messages icon should show 1 unread
    And the notifications bell should show 1 unread
    When I open the notification "New message in Bob Bowman"
    Then the message "Is there room for a big suitcase?" should be from "Bob Bowman"
    When I send the message "Yes, plenty of room"

    When I switch to "Bob Bowman"
    And I go to the posts page
    Then the Messages icon should show 1 unread
    When I open the chat "Alice Arthur"
    Then the message "Yes, plenty of room" should be from "Alice Arthur"

  Scenario: A direct message is private to the two people in it
    When I switch to "Bob Bowman"
    And I go to the new message page
    And I fill in "Email:" with "alice@columbia.edu"
    And I press "Start chat"
    And I send the message "Just between us"

    When I switch to "Carol Chen"
    And I go to the messages page
    Then I should see "No messages yet."
    And the Messages icon should not show an unread count

  Scenario: The author is notified of a reply and other students see it
    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I write the reply "Can we leave at 5 instead?"
    And I press "Post Reply"

    When I switch to "Alice Arthur"
    And I go to the posts page
    Then the notifications bell should show 1 unread
    When I open the notification "Bob Bowman replied to your post: Uber to JFK"
    Then the discussion replies include "Can we leave at 5 instead?"

    When I switch to "Carol Chen"
    And I go to the post page for "Uber to JFK"
    Then the discussion replies include "Can we leave at 5 instead?"
    And the reply "Can we leave at 5 instead?" should not have Edit or Delete controls

  Scenario: An anonymous reply hides the replier's name from everyone else
    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I write the reply "Is the fare split evenly?"
    And I check "Reply anonymously"
    And I press "Post Reply"

    When I switch to "Alice Arthur"
    And I go to the notifications page
    Then I should see "Someone replied to your post: Uber to JFK"
    And I should not see "Bob Bowman"

    When I switch to "Carol Chen"
    And I go to the post page for "Uber to JFK"
    Then the discussion replies include "Is the fare split evenly?"
    And I should not see "Bob Bowman"

  Scenario: Other students see a reply's edits and deletion
    When I switch to "Bob Bowman"
    And I go to the post page for "Uber to JFK"
    And I write the reply "Leaving from Butler"
    And I press "Post Reply"

    When I switch to "Carol Chen"
    And I go to the post page for "Uber to JFK"
    Then the discussion replies include "Leaving from Butler"

    When I switch to "Bob Bowman"
    And I edit my reply
    And I write the reply "Leaving from John Jay"
    And I press "Save Reply"

    When I switch to "Carol Chen"
    And I reload the page
    Then the discussion replies include "Leaving from John Jay"
    And I should not see "Leaving from Butler"

    When I switch to "Bob Bowman"
    And I delete my reply

    When I switch to "Carol Chen"
    And I reload the page
    Then I should not see "Leaving from John Jay"

  Scenario: The organizer sees RSVPs come and go
    Given "Alice Arthur" has an event titled "Board Game Night"
    When I switch to "Bob Bowman"
    And I go to the post page for "Board Game Night"
    And I press "I'm going"

    When I switch to "Alice Arthur"
    And I go to the post page for "Board Game Night"
    Then the attendee count should be "1"
    When I go to the notifications page
    Then I should see "Bob Bowman joined your post: Board Game Night"

    When I switch to "Bob Bowman"
    And I press "Un-RSVP"

    When I switch to "Alice Arthur"
    And I go to the post page for "Board Game Night"
    Then the attendee count should be "0"

  Scenario: Other students see a like in the count, but not as their own like
    When I switch to "Bob Bowman"
    And I go to the posts page
    And I like the post "Uber to JFK"
    Then I should see a "Unlike" button for "Uber to JFK"

    When I switch to "Carol Chen"
    And I go to the posts page
    Then the like count for "Uber to JFK" should be 1
    And I should see a "Like" button for "Uber to JFK"

  Scenario: Only followers of a category are notified of a new post in it
    When I switch to "Carol Chen"
    And I go to the posts page
    And I press "Follow Housing"

    When I switch to "Alice Arthur"
    And I go to the new post page
    And I fill in "Title" with "Sublet near campus"
    And I fill in "Body" with "Available for the spring semester"
    And I choose "Housing"
    And I choose "This week"
    And I press "Create Post"
    Then I should see "Post was successfully created."

    When I switch to "Carol Chen"
    And I go to the posts page
    Then the notifications bell should show 1 unread
    When I open the notification "New post in Housing: Sublet near campus"
    Then I should be on the post page for "Sublet near campus"

    When I switch to "Bob Bowman"
    And I go to the posts page
    Then the notifications bell should show 0 unread