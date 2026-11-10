require "rails_helper"

RSpec.describe "Authentication", type: :request do
  before { OmniAuth.config.test_mode = true }
  after  { OmniAuth.config.mock_auth[:google_oauth2] = nil }

  def mock_google(email, name: "Testing Tester")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "uid-#{email}",
      info: { email: email, name: name }
    )
  end

  def sign_in_with_google
    post user_google_oauth2_omniauth_authorize_path
    follow_redirect!
  end

  describe "protected pages" do
    it "redirects logged-out users to the sign-in page" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the sign-in page without logging in" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end

    it "keeps the sign-in alert visible when the sign-in page is revisited" do
      get root_path
      follow_redirect!
      expect(response.body).to include(I18n.t("devise.failure.unauthenticated"))

      get new_user_session_path
      expect(response.body).to include(I18n.t("devise.failure.unauthenticated"))
    end

    it "shows the home page to signed-in users" do
      sign_in create(:user)
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Google sign-in" do
    it "creates and signs in a Columbia/Barnard user" do
      mock_google("rc3934@columbia.edu")
      expect { sign_in_with_google }.to change(User, :count).by(1)
      expect(response).to redirect_to(root_path)
    end

    it "maps a returning user to same account" do
      create(:user, email: "rc3934@columbia.edu")
      mock_google("rc3934@columbia.edu")
      expect { sign_in_with_google }.not_to change(User, :count)
      expect(response).to redirect_to(root_path)
    end

    it "rejects a non-Columbia or Barnard address" do
      mock_google("lionden@gmail.com")
      expect { sign_in_with_google }.not_to change(User, :count)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include("Columbia or Barnard address")
    end

    it "handles a Google failure" do
      OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
      sign_in_with_google
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq("Google sign-in failed. Please try again.")
    end
  end

  describe "logging out" do
    it "sends users to the sign-in page" do
      sign_in create(:user)
      delete destroy_user_session_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
