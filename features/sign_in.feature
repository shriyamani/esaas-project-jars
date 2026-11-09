Feature: Sign in with Google
  As a Columbia or Barnard student
  In order for others to know I'm a verified student
  I want to sign in with my .edu Google account

  Scenario Outline: First sign-in authenticates and recognizes user
    When I sign in with Google as "<email>"
    Then I should see "Successfully authenticated from Google account."
    And I should see "Testing Tester"

    Examples:
      | email                   |
      | sm5586@barnard.edu      |
      | jsw2219@columbia.edu    |
    
    Scenario: Returning student user signs in with same account
      Given a user exists with email "sm5586@barnard.edu"
      When I sign in with Google as "sm5586@barnard.edu"
      Then there should be exactly 1 account for "sm5586@barnard.edu"
    
    Scenario: A Gmail account is rejected
      When I sign in with Google as "shriyamani@gmail.com"
      Then I should be on the log in page
      And I should see "Email must be a Columbia or Barnard address"
      And no account should exist for "shriyamani@gmail.com"
    
    Scenario: Google sign-in fails
      Given Google sign-in will fail
      When I am on the log in page
      And I press "Sign in with Google"
      Then I should see "Google sign-in failed. Please try again."