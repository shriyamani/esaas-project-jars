require "rails_helper"

RSpec.describe "Likes", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post) }

  describe "when logged out" do
    it "redirects like and unlike to sign in" do
      post post_like_path(post_record)
      expect(response).to redirect_to(new_user_session_path)

      delete post_like_path(post_record)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "when logged in" do
    before { sign_in user }

    it "likes a post as the current user" do
      expect { post post_like_path(post_record) }.to change(Like, :count).by(1)
      expect(Like.last).to have_attributes(user: user, post: post_record)
    end

    it "does not create a duplicate when liking twice" do
      post post_like_path(post_record)
      expect { post post_like_path(post_record) }.not_to change(Like, :count)
    end

    it "unlikes a post" do
      create(:like, user: user, post: post_record)
      expect { delete post_like_path(post_record) }.to change(Like, :count).by(-1)
    end

    it "only removes the current user's like" do
      create(:like, post: post_record)
      expect { delete post_like_path(post_record) }.not_to change(Like, :count)
    end

    it "returns to the page the user was on" do
      post post_like_path(post_record), headers: { "HTTP_REFERER" => posts_url(category: "Housing") }
      expect(response).to redirect_to(posts_url(category: "Housing"))
    end

    it "falls back to the post page with no previous page" do
      post post_like_path(post_record)
      expect(response).to redirect_to(post_path(post_record))
    end

    it "returns not found for an expired post" do
      post_record.update_column(:expires_at, 1.day.ago)
      expect { post post_like_path(post_record) }.not_to change(Like, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
