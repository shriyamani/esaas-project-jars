Feature: Learn about LionDen before logging in
  As a visitor who hasn't logged in yet
  So they learn more about LionDen
  I want to read about what LionDen does

  Background:
    Given I am not logged in

  Scenario Outline: Open other tabs from the log in page
    Given I am on the log in page
    When I follow "<link>"
    Then I should be on <page>
    And I should see "<heading>"

    Examples:
      | link       | page           | heading          |
      | About      | the about page | About Us         |
      | FAQ        | the FAQ page   | What is LionDen? |
      | Contact us | the contact page | Contact us     |

  Scenario: Return to the log in page from an info page
    Given I am on the FAQ page
    When I follow "Home"
    Then I should be on the log in page

  Scenario: The FAQ shows each question with its answer
    Given I am on the FAQ page
    Then I should see "Q: Who can join?"
    And I should see "A: Only students with a @columbia.edu or @barnard.edu Google account"
    And I should see "Q: Is this an official Columbia app?"

  Scenario: Info pages show the public nav on every page
    Given I am on the about page
    Then I should see a link "Home"
    And I should see a link "FAQ"
    And I should see a link "Contact us"

  Scenario: Move between info pages using the nav
    Given I am on the about page
    When I follow "FAQ"
    Then I should be on the FAQ page
    When I follow "Contact us"
    Then I should be on the contact page