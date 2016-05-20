@javascript
Feature: drush site-install validation
  In order to prove Drupal 8 was installed properly
  As a developer
  I need to user the step definitions of this context

  Scenario: Open home page and find text
    Given I am on the homepage
    #And I am not logged in
    Then I should see the heading "Welcome to Site-Install"

  Scenario: Error messages
    Given I am on "/user/login"
    When I fill in "Username" with "user@example.com"
    And  I fill in "Password" with "123"
    And  I press "Log in"
    Then I should see the error message "Unrecognized username or password."
