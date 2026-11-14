require "rails_helper"

RSpec.describe "Public pages", type: :request do
  PUBLIC_PATHS = {
    "/faq"     => "What is LionDen?",
    "/about"   => "About",
    "/contact" => "Contact"
  }.freeze

  describe "when logged out" do
    PUBLIC_PATHS.each do |path, text|
      it "shows #{path} without requiring sign-in" do
        get path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(text)
      end

      it "shows the public nav on #{path}" do
        get path
        expect(response.body).to include("About", "FAQ", "Contact")
        expect(response.body).not_to include("Log out")
      end
    end
  end

  describe "when logged in" do
    before { sign_in create(:user) }

    PUBLIC_PATHS.each_key do |path|
      it "still shows #{path}" do
        get path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "the sign-in page" do
    before { get new_user_session_path }

    it "loads without signing in" do
      expect(response).to have_http_status(:ok)
    end

    it "shows the tagline and the Google button" do
      expect(response.body).to include("Everything happening at Columbia")
      expect(response.body).to include("Sign in with Google")
    end

    it "posts to the Google OmniAuth path" do
      expect(response.body).to include(user_google_oauth2_omniauth_authorize_path)
    end

    it "sets the tab title" do
      expect(response.body).to match(%r{<title>[^<]*LionDen[^<]*</title>})
    end

    it "links to the info pages" do
      expect(response.body).to include(faq_path, about_path, contact_path)
    end
  end

  describe "the FAQ page" do
    before { get faq_path }

    it "lists every question" do
      [
        "What is LionDen?",
        "Who can join?",
        "Can I post anonymously?",
        "Why do posts expire?",
        "Is this an official Columbia app?"
      ].each { |q| expect(response.body).to include(q) }
    end

    it "says only Columbia and Barnard students can join" do
      expect(response.body).to include("@columbia.edu or @barnard.edu")
    end
  end
end