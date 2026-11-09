require "rails_helper"

RSpec.describe "Replies", type: :request do
  let(:reader) { create(:user) }
  let(:post_record) { create(:post) }

  it "requires login" do
    expect { post post_replies_path(post_record), params: { reply: { body: "Hello" } } }.not_to change(Reply, :count)
    expect(response).to redirect_to(new_user_session_path)
  end

  context "signed in" do
    before { sign_in reader }

    it "creates a reply as the current user and ignores forged ownership" do
      expect {
        post post_replies_path(post_record), params: { reply: { body: "Hello", anonymous: true, user_id: post_record.user_id, post_id: 0 } }
      }.to change(Reply, :count).by(1)
      expect(Reply.last).to have_attributes(user: reader, post: post_record, anonymous: true)
      expect(response).to redirect_to(post_record)
    end

    it "reports invalid input" do
      expect { post post_replies_path(post_record), params: { reply: { body: "" } } }.not_to change(Reply, :count)
      expect(response).to redirect_to(post_record)
      expect(flash[:alert]).to include("Body can't be blank")
    end

    it "rejects replies to expired posts and returns to the feed" do
      post_record.update_column(:expires_at, 1.second.ago)
      expect { post post_replies_path(post_record), params: { reply: { body: "Too late" } } }.not_to change(Reply, :count)
      expect(response).to redirect_to(posts_path)
      expect(flash[:alert]).to include("expired")
    end

    it "returns not found for a missing post" do
      post post_replies_path(post_id: 0), params: { reply: { body: "Hello" } }
      expect(response).to have_http_status(:not_found)
    end

    it "shows replies to the author while hiding an anonymous replier's identity" do
      create(:reply, post: post_record, user: reader, body: "Private identity", anonymous: true)
      sign_in post_record.user
      get post_path(post_record)
      replies = response.parsed_body.at_css("#replies").text
      expect(replies).to include("Private identity", "Anonymous")
      expect(replies).not_to include(reader.name, reader.email)
    end

    it "deletes replies when the post is deleted" do
      create(:reply, post: post_record, user: reader)
      expect { post_record.destroy! }.to change(Reply, :count).by(-1)
    end
  end
end
