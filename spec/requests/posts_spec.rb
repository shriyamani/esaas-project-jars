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

    it "renders validation errors without saving an invalid update" do
      patch post_path(post_record), params: { post: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(post_record.reload.title).to eq("Original Title")
      expect(response.body).to include("Title can&#39;t be blank")
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

  describe "expiration protection" do
    before { sign_in author }

    it "allows viewing an active post" do
      get post_path(post_record)

      expect(response).to have_http_status(:ok)
    end

    it "returns not found after a post expires" do
      start_time = Time.zone.local(2026, 11, 9, 12, 0, 0)

      travel_to start_time do
        post_record.update_column(:expires_at, 1.hour.from_now)

        get post_path(post_record)
        expect(response).to have_http_status(:ok)
      end

      travel_to start_time + 2.hours do
        get post_path(post_record)
        expect(response).to have_http_status(:not_found)
      end
    end
  end


  describe "post feed sorting" do
    before { sign_in author }

    it "displays active posts newest first" do
      older_post = create(:post, user: author, title: "Older Post")
      newer_post = create(:post, user: author, title: "Newer Post")

      older_post.update_column(:created_at, 2.days.ago)
      newer_post.update_column(:created_at, 1.day.ago)

      get posts_path

      expect(response).to have_http_status(:ok)

      titles = response.parsed_body.css("#posts h2").map(&:text)

      expect(titles.index("Newer Post")).to be < titles.index("Older Post")
    end
  end


  describe "category filtering" do
    before { sign_in author }

    it "displays only posts from the selected category" do
      create(:post, user: author, title: "Housing Post", category: "Housing")
      create(:post, user: author, title: "Academic Post", category: "Academics")

      get posts_path, params: { category: "Housing" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Housing Post")
      expect(response.body).not_to include("Academic Post")
    end

    it "shows all active categories when no filter is selected" do
      create(:post, user: author, title: "Housing Post", category: "Housing")
      create(:post, user: author, title: "Academic Post", category: "Academics")

      get posts_path

      expect(response.body).to include("Housing Post")
      expect(response.body).to include("Academic Post")
    end

    it "does not display expired posts even when their category matches" do
      active_post = create(:post, user: author, title: "Active Housing", category: "Housing")
      expired_post = create(:post, user: author, title: "Expired Housing", category: "Housing")

      expired_post.update_column(:expires_at, 1.day.ago)

      get posts_path, params: { category: "Housing" }

      expect(response.body).to include(active_post.title)
      expect(response.body).not_to include(expired_post.title)
    end
  end
end
