Feature: Creating and managing posts
  As a Columbia or Barnard student
  In order to share information and coordinate with other students
  I want to create, manage, and view posts on LionDen

  Scenario: Create a post
    Given I am logged in as "student@columbia.edu"
    When I go to the new post page
    And I fill in "Title" with "Study group for Algorithms"
    And I fill in "Body" with "Meeting at Butler Library on Thursday"
    And I choose "Academics"
    And I choose "This week"
    And I press "Create Post"
    Then I should see "Post was successfully created."
    And I should see "Study group for Algorithms"
    And I should see "Meeting at Butler Library on Thursday"
    And I should see "Academics"
    And the post author should be "Testing Tester"

  Scenario: An anonymous post shows Anonymous instead of the author's name
    Given I am logged in as "student@columbia.edu"
    When I go to the new post page
    And I fill in "Title" with "Secret study tips"
    And I fill in "Body" with "Use flashcards for CS theory."
    And I choose "Social"
    And I choose "Tonight"
    And I check "Post anonymously"
    And I press "Create Post"
    Then I should see "Post was successfully created."
    And I should see "Secret study tips"
    And the post author should be "Anonymous"
    And the post author should not be "Testing Tester"

  Scenario: Edit my own post
    Given a post exists with title "Original Post Title" authored by "student@columbia.edu"
    And I am logged in as "student@columbia.edu"
    When I go to the edit page for "Original Post Title"
    And I fill in "Title" with "Updated Post Title"
    And I press "Update Post"
    Then I should see "Post was successfully updated."
    And I should see "Updated Post Title"

  Scenario: Open the new post form from the + button
    Given I am logged in as "student@columbia.edu"
    When I go to the posts page
    And I click link "New post"
    Then I should be on the new post page
    When I click link "Cancel"
    Then I should be on the posts page

  Scenario: Change my post's category while editing
    Given a post exists with title "Original Post Title" authored by "student@columbia.edu"
    And I am logged in as "student@columbia.edu"
    When I go to the edit page for "Original Post Title"
    And I choose "Travel"
    And I press "Update Post"
    Then I should see "Post was successfully updated."
    And I should see "Travel"

  Scenario: I can't edit someone else's post
    Given a post exists with title "Other Student Post" authored by "author@columbia.edu"
    And I am logged in as "intruder@barnard.edu"
    When I attempt to edit "Other Student Post"
    Then I should be on the posts page
    And I should see "You are not authorized to edit this post."

  Scenario: A post without a title is rejected
    Given I am logged in as "student@columbia.edu"
    When I go to the new post page
    And I fill in "Body" with "Content without a title"
    And I choose "Social"
    And I choose "Tonight"
    And I press "Create Post"
    Then I should see "Title can't be blank"
