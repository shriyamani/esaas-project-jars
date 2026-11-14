Feature: Log out and protected pages
  As a signed-in authenticated student
  To make sure nobody else can impersonate me on a shared device
  I want to log out, and logged-out users should be sent back to sign-in
  
  Scenario: Log out
    Given I am logged in as "sm5586@barnard.edu"
    And I am on the home page
    When I press "Log out"
    Then I should be on the log in page

  Scenario: Logged-out users are redirected to log in page
    Given I am not logged in
    When I go to the home page
    Then I should be on the log in page