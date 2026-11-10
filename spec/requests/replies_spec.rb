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
  describe "managing existing replies" do
    let!(:reply) { create(:reply, post: post_record, user: reader, body: "Original", anonymous: true) }

    it "requires login for editing, updating, and deleting" do
      get edit_post_reply_path(post_record, reply)
      expect(response).to redirect_to(new_user_session_path)
      patch post_reply_path(post_record, reply), params: { reply: { body: "Changed" } }
      expect(response).to redirect_to(new_user_session_path)
      expect { delete post_reply_path(post_record, reply) }.not_to change(Reply, :count)
      expect(response).to redirect_to(new_user_session_path)
      expect(reply.reload.body).to eq("Original")
    end

    context "as the reply author" do
      before { sign_in reader }

      it "renders the edit form and preserves anonymity when updating" do
        get edit_post_reply_path(post_record, reply)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Original", "Save Reply")
        patch post_reply_path(post_record, reply), params: { reply: { body: "Changed", user_id: post_record.user_id, post_id: 0 } }
        expect(response).to redirect_to(post_record)
        expect(reply.reload).to have_attributes(body: "Changed", anonymous: true, user: reader, post: post_record)
      end

      it "allows changing anonymity" do
        patch post_reply_path(post_record, reply), params: { reply: { anonymous: false } }
        expect(reply.reload.anonymous).to be false
      end

      it "renders errors and retains the submitted input on invalid updates" do
        patch post_reply_path(post_record, reply), params: { reply: { body: "", anonymous: false } }
        expect(response).to have_http_status(422)
        expect(response.body).to include("Body can&#39;t be blank", "Save Reply")
        expect(reply.reload.body).to eq("Original")
      end

      it "deletes a reply" do
        expect { delete post_reply_path(post_record, reply) }.to change(Reply, :count).by(-1)
        expect(response).to redirect_to(post_record)
        expect(response).to have_http_status(:see_other)
      end

      it "returns to the feed when editing or deleting after post expiration" do
        post_record.update_column(:expires_at, 1.minute.ago)
        patch post_reply_path(post_record, reply), params: { reply: { body: "Changed" } }
        expect(response).to redirect_to(posts_path)
        delete post_reply_path(post_record, reply)
        expect(response).to redirect_to(posts_path)
      end

      it "does not accept a reply nested under a different post" do
        other_post = create(:post)
        patch post_reply_path(other_post, reply), params: { reply: { body: "Changed" } }
        expect(response).to have_http_status(:not_found)
        expect(reply.reload.body).to eq("Original")
      end
    end

    it "denies the post author access to another user's reply controls and actions" do
      sign_in post_record.user
      get post_path(post_record)
      expect(response.parsed_body.at_css("#replies .action-links")).to be_nil
      get edit_post_reply_path(post_record, reply)
      expect(response).to have_http_status(:not_found)
      patch post_reply_path(post_record, reply), params: { reply: { body: "Changed" } }
      expect(response).to have_http_status(:not_found)
      expect { delete post_reply_path(post_record, reply) }.not_to change(Reply, :count)
      expect(response).to have_http_status(:not_found)
      expect(reply.reload.body).to eq("Original")
    end
  end
end
