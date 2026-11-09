Feature: Replies on posts
  Background:
    Given an active discussion exists
    And I am logged in as "reader@columbia.edu"

  Scenario: Reply to a post
    When I open the discussion
    And I fill in "Write a reply" with "I can help!"
    And I press "Post Reply"
    Then the discussion replies include "I can help!"

  Scenario: Cannot reply after expiration
    When I open the discussion
    And I fill in "Write a reply" with "Too late"
    And the discussion has expired
    And I press "Post Reply"
    Then I should see "This post has expired."
    And the discussion has no replies

  Scenario: The post author sees anonymous replies
    When I open the discussion
    And I fill in "Write a reply" with "An anonymous suggestion"
    And I check "Reply anonymously"
    And I press "Post Reply"
    And I am logged in as "author@barnard.edu"
    And I open the discussion
    Then the discussion replies include "An anonymous suggestion"
    And the reply author is anonymous
