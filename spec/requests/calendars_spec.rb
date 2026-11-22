require "rails_helper"

RSpec.describe "Calendars", type: :request do
  let(:student) { create(:user) }
  let(:other_student) { create(:user) }

  describe "GET /calendar" do
    it "requires login" do
      get calendar_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when signed in" do
      before { sign_in student }

      it "renders the calendar page with all events" do
        event = create(:post, user: other_student, event_date: Date.tomorrow, category: "Social")
        get calendar_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Calendar")
        expect(response.body).to include("All events")
        expect(response.body).to include("My events")
        expect(response.body).to include(event.title)
      end

      it "filters events for 'My events' tab" do
        my_post = create(:post, user: student, title: "My Study Group", event_date: Date.tomorrow)
        rsvped_post = create(:post, user: other_student, title: "Fun Party", event_date: Date.tomorrow)
        create(:rsvp, user: student, post: rsvped_post)
        unrelated_post = create(:post, user: other_student, title: "Unrelated Meetup", event_date: Date.tomorrow)

        get calendar_path(tab: "my")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("My Study Group")
        expect(response.body).to include("Fun Party")
        expect(response.body).not_to include("Unrelated Meetup")
      end

      it "filters events by category" do
        social_event = create(:post, user: other_student, title: "Social Gathering", category: "Social", event_date: Date.tomorrow)
        housing_event = create(:post, user: other_student, title: "Housing Info", category: "Housing", event_date: Date.tomorrow)

        get calendar_path(category: "Social")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Social Gathering")
        expect(response.body).not_to include("Housing Info")
      end
    end
  end
end

