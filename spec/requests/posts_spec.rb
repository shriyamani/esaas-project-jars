require "rails_helper"

RSpec.describe "Posts", type: :request do
  let(:author) { create(:user, email: "author@columbia.edu", name: "Author User") }
  let(:other_user) { create(:user, email: "other@barnard.edu", name: "Other User") }
  let!(:post_record) { create(:post, user: author, title: "Original Title") }

  describe "unauthenticated access" do
    it "redirects index to sign in" do
      get posts_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects new to sign in" do
      get new_post_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects create to sign in" do
      post posts_path, params: { post: { title: "New" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects edit to sign in" do
      get edit_post_path(post_record)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects update to sign in" do
      patch post_path(post_record), params: { post: { title: "Hacked" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects destroy to sign in" do
      delete post_path(post_record)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "author actions" do
    before { sign_in author }

    it "allows viewing index" do
      get posts_path
      expect(response).to have_http_status(:ok)
    end

    it "allows viewing post" do
      get post_path(post_record)
      expect(response).to have_http_status(:ok)
    end

    it "allows viewing edit page" do
      get edit_post_path(post_record)
      expect(response).to have_http_status(:ok)
    end

    it "allows updating their post" do
      patch post_path(post_record), params: { post: { title: "Updated Title" } }
      expect(response).to redirect_to(post_path(post_record))
      expect(post_record.reload.title).to eq("Updated Title")
    end

    it "allows deleting their post" do
      expect {
        delete post_path(post_record)
      }.to change(Post, :count).by(-1)
      expect(response).to redirect_to(posts_path)
    end
  end

  describe "controller authorization for non-authors" do
    before { sign_in other_user }

    it "denies access to edit another user's post" do
      get edit_post_path(post_record)
      expect(response).to redirect_to(posts_path)
      expect(flash[:alert]).to eq("You are not authorized to edit this post.")
    end

    it "denies updating another user's post" do
      patch post_path(post_record), params: { post: { title: "Unauthorized Edit" } }
      expect(response).to redirect_to(posts_path)
      expect(flash[:alert]).to eq("You are not authorized to edit this post.")
      expect(post_record.reload.title).to eq("Original Title")
    end

    it "denies deleting another user's post" do
      expect {
        delete post_path(post_record)
      }.not_to change(Post, :count)
      expect(response).to redirect_to(posts_path)
      expect(flash[:alert]).to eq("You are not authorized to edit this post.")
    end
  end
end
