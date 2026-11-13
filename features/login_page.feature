Feature: Sign-in page
  As a Columbia or Barnard student
  So that I can authenticate myself
  I want a clear sign-in page

  Scenario: The sign-in page explains the app and shows the sign-in button
    Given I am not logged in
    When I go to the log in page
    Then I should see "Everything happening at Columbia"
    And I should see "Sign in with your Columbia or Barnard email address"
    And I should see a "Sign in with Google" button

  Scenario: The sign-in page shows only the public nav
    Given I am not logged in
    When I go to the log in page
    Then I should see a link "About"
    And I should see a link "FAQ"
    And I should see a link "Contact us"
    And I should not see "Log out"
    And I should not see a link "New Post"

  Scenario: A rejected sign-in shows an error on the sign-in page
    When I sign in with Google as "roaree@gmail.com"
    Then I should be on the log in page
    And I should see "Email must be a Columbia or Barnard address"
    And I should see a "Sign in with Google" button

  Scenario: Signing out returns me to the log in page
    Given I am logged in as "rl1234@columbia.edu"
    And I am on the home page
    When I press "Log out"
    Then I should be on the log in page
    And I should see a "Sign in with Google" button