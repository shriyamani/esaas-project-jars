require "rails_helper"

RSpec.describe "My Activity", type: :request do
  let(:student) { create(:user, name: "Student User") }
  let(:other_student) { create(:user, name: "Other Student") }

  it "requires sign in" do
    get my_activity_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "shows authored, joined, and RSVP'd posts in their own sections" do
    own_post = create(:post, user: student, title: "My housing post")
    replied_post = create(:post, user: other_student, title: "A post I replied to")
    create_list(:reply, 2, user: student, post: replied_post)
    group_post = create(:post, user: other_student, title: "A discussion I joined")
    group = create(:conversation, kind: "group", post: group_post)
    group.participants << student
    event_post = create(:post, user: other_student, title: "An event I will attend", event_date: Date.tomorrow, location: "Low Steps")
    create(:rsvp, user: student, post: event_post)
    create(:post, user: other_student, title: "Unrelated post")

    sign_in student
    get my_activity_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("main h1").text).to eq("My Activity")
    expect(section_titles("my-posts")).to eq([ own_post.title ])
    expect(section_titles("joined-posts")).to eq([ group_post.title, replied_post.title ])
    expect(section_titles("my-rsvps")).to eq([ event_post.title ])
    expect(response.parsed_body.at_css("#my-rsvps .activity_event_details").text).to include("Low Steps", event_post.event_date.strftime("%B %-d, %Y"))
    expect(response.parsed_body.at_css("a.my_activity_tab")["aria-current"]).to eq("page")
    expect(response.parsed_body.at_css(".profile_activity_link")["href"]).to eq(my_activity_path)
  end

  it "does not show expired posts or count an authored post as joined" do
    own_post = create(:post, user: student, title: "My post")
    create(:reply, user: student, post: own_post)
    expired_post = create(:post, user: other_student, title: "Expired discussion")
    create(:reply, user: student, post: expired_post)
    expired_post.update_column(:expires_at, 1.day.ago)

    sign_in student
    get my_activity_path

    expect(section_titles("my-posts")).to eq([ own_post.title ])
    expect(section_titles("joined-posts")).to be_empty
    expect(response.body).to include("You haven't joined any active posts yet.")
    expect(response.body).not_to include("Expired discussion")
  end

  private

  def section_titles(section_id)
    response.parsed_body.css("##{section_id} .post_card_title").map { |node| node.text.strip }
  end
end
