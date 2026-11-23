
Feature: Joining posts with available spots
  As a Columbia or Barnard student
  I want to join posts with available spots
  So that I can coordinate with other students in a group chat

  Background:
    Given I am logged in as "student@columbia.edu"
    And a post titled "Uber to JFK" has 2 available spots

  Scenario: Join a post with available spots
    When I open the post with available spots
    Then I should see "0 of 2 spots filled"
    When I press "Join"
    Then I should see "You joined this post."
    When I open the post with available spots
    Then I should see "1 of 2 spots filled"

  Scenario: Cannot join a full post
    Given the post with available spots is full
    When I open the post with available spots
    Then I should see "All spots filled"
    And I should not see "Join"

  Scenario: Cannot join my own post
    Given I am the author of the post with available spots
    When I open the post with available spots
    Then I should see "0 of 2 spots filled"
    And I should not see "Join"

  Scenario: Cannot join an expired post
    Given the post with available spots has expired
    When I go to the posts page
    Then I should not see "Uber to JFK"

  Scenario: Joining creates a group chat
    When I open the post with available spots
    And I press "Join"
    Then I should see "Uber to JFK"
    And I should see "Say hi to start the conversation."

  Scenario: Leaving frees a spot
    Given I have joined the post with available spots
    When I open the post with available spots
    And I press "Leave"
    Then I should see "You left this post."
    And I should see "0 of 2 spots filled"