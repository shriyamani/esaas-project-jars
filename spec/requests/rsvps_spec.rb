require "rails_helper"

RSpec.describe "Rsvps", type: :request do
  let(:student) { create(:user) }
  let(:post_record) { create(:post, event_date: Date.tomorrow) }

  describe "POST /posts/:post_id/rsvp" do
    it "requires login" do
      expect {
        post post_rsvp_path(post_record)
      }.not_to change(Rsvp, :count)
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when signed in" do
      before { sign_in student }

      it "creates an RSVP for the logged-in user" do
        expect {
          post post_rsvp_path(post_record)
        }.to change(Rsvp, :count).by(1)

        expect(Rsvp.last).to have_attributes(user: student, post: post_record)
        expect(response).to redirect_to(post_record)
        expect(flash[:notice]).to eq("You have RSVP'd to this event.")
      end

      it "does not duplicate RSVP if already RSVP'd" do
        create(:rsvp, user: student, post: post_record)

        expect {
          post post_rsvp_path(post_record)
        }.not_to change(Rsvp, :count)

        expect(response).to redirect_to(post_record)
      end
    end
  end

  describe "DELETE /posts/:post_id/rsvp" do
    it "requires login" do
      delete post_rsvp_path(post_record)
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when signed in" do
      before { sign_in student }

      it "removes an existing RSVP" do
        create(:rsvp, user: student, post: post_record)

        expect {
          delete post_rsvp_path(post_record)
        }.to change(Rsvp, :count).by(-1)

        expect(response).to redirect_to(post_record)
        expect(flash[:notice]).to eq("You have un-RSVP'd from this event.")
      end

      it "handles un-RSVP when no RSVP exists" do
        expect {
          delete post_rsvp_path(post_record)
        }.not_to change(Rsvp, :count)

        expect(response).to redirect_to(post_record)
      end
    end
  end
end

