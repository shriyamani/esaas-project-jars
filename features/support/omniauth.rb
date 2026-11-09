"""
For Cucumber tests, we need to set up mock Google OAuth authentication
(Test Google login without actually needing to contact Google or require
users to sign in with real Google accounts)

PURPOSE: Test that only Columbia/Barnard emails can access LionDen
"""

OmniAuth.config.test_mode = true
Before { OmniAuth.config.mock_auth[:google_oauth2] = nil }

module OmniAuthHelpers
    def mock_google_login(email:, name: "Testing Tester")
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
            provider: "google_oauth2", uid: "uid-#{email}",
            info: { email: email, name: name }
        )
    end
end
World(OmniAuthHelpers)