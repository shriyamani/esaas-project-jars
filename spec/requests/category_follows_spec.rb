require "rails_helper"

RSpec.describe "Category follows", type: :request do
  let(:user) { create(:user) }

  describe "when logged out" do
    it "redirects follow to sign in" do
      post category_follow_path, params: { category: "Housing" }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects unfollow to sign in" do
      delete category_follow_path, params: { category: "Housing" }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "when logged in" do
    before { sign_in user }

    it "follows a category" do
      expect {
        post category_follow_path, params: { category: "Housing" }
      }.to change { user.category_follows.count }.by(1)
    end

    it "does not create a duplicate when following twice" do
      post category_follow_path, params: { category: "Housing" }
      expect {
        post category_follow_path, params: { category: "Housing" }
      }.not_to change(CategoryFollow, :count)
    end

    it "ignores a category that doesn't exist" do
      expect {
        post category_follow_path, params: { category: "Memes" }
      }.not_to change(CategoryFollow, :count)
    end

    it "unfollows a category" do
      create(:category_follow, user: user, category: "Housing")
      expect {
        delete category_follow_path, params: { category: "Housing" }
      }.to change { user.category_follows.count }.by(-1)
    end

    it "only unfollows for the current user" do
      other = create(:category_follow, category: "Housing")
      delete category_follow_path, params: { category: "Housing" }
      expect(CategoryFollow.exists?(other.id)).to be true
    end

    it "returns to the page the user was on" do
      post category_follow_path, params: { category: "Housing" },
           headers: { "HTTP_REFERER" => posts_url(category: "Academics") }
      expect(response).to redirect_to(posts_url(category: "Academics"))
    end

    it "falls back to the posts page with no previous page" do
      post category_follow_path, params: { category: "Housing" }
      expect(response).to redirect_to(posts_path)
    end
  end
end