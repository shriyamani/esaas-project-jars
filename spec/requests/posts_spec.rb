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
      back_link = response.parsed_body.at_css("a.back_link")
      expect(back_link.text.strip).to eq("← Back to My Activity")
      expect(back_link["href"]).to eq(my_activity_path)
    end

    it "allows creating an event post with date, time, and location" do
      expect {
        post posts_path, params: {
          post: {
            title: "Campus Meetup",
            body: "Meeting in front of Low",
            category: "Social",
            expiration_preset: "Custom",
            custom_expires_at: 1.week.from_now.to_s,
            event_date: Date.tomorrow,
            event_time: "5:00 PM",
            location: "Low Steps"
          }
        }
      }.to change(Post, :count).by(1)

      created_post = Post.last
      expect(created_post.location).to eq("Low Steps")
      expect(created_post.event_date).to eq(Date.tomorrow)
      expect(created_post.event_time).to eq("5:00 PM")
      expect(response).to redirect_to(post_path(created_post))
      follow_redirect!
      expect(response.body).to include("Low Steps")
      expect(response.body).to include("5:00 PM")
      expect(response.body).to include("I&#39;m going")
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
      expect(response).to have_http_status(:unprocessable_content)
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

  describe "feed views" do
    before { sign_in other_user }

    def heading
      response.parsed_body.at_css("main h1").text.strip
    end

    it "titles the default view 'All posts'" do
      get posts_path
      expect(heading).to eq("All posts")
    end

    it "titles a category view with the category name" do
      get posts_path, params: { category: "Housing" }
      expect(heading).to eq("Housing")
    end

    it "shows only posts from followed categories under Following" do
      create(:category_follow, user: other_user, category: "Housing")
      create(:post, user: author, title: "Academic Post", category: "Academics")

      get posts_path, params: { feed: "following" }

      expect(heading).to eq("Following")
      expect(response.body).to include("Original Title")
      expect(response.body).not_to include("Academic Post")
    end

    it "shows the follow prompt when the user follows nothing" do
      get posts_path, params: { feed: "following" }

      expect(response.body).to include("You're not following any categories yet.")
      expect(response.body).not_to include("Original Title")
    end

    it "says when followed categories have no active posts" do
      create(:category_follow, user: other_user, category: "Travel")
      get posts_path, params: { feed: "following" }
      expect(response.body).to include("No active posts in the categories you follow.")
    end

    it "does not show expired posts under Following" do
      create(:category_follow, user: other_user, category: "Housing")
      post_record.update_column(:expires_at, 1.day.ago)

      get posts_path, params: { feed: "following" }

      expect(response.body).not_to include("Original Title")
    end

    it "lists followed categories first in the category bar" do
      create(:category_follow, user: other_user, category: "Travel")
      get posts_path

      labels = response.parsed_body.css(".category_bar .category_tab .category_label").map(&:text)
      expect(labels).to eq([ "Travel" ] + (Post::CATEGORIES - [ "Travel" ]))
    end

    it "links a selected category back to All posts" do
      get posts_path, params: { category: "Housing" }
      link = response.parsed_body.at_css('.category_tab a[aria-current="page"]')
      expect(link["href"]).to eq(posts_path)
    end
  end

  describe "My Posts feed" do
    before { sign_in author }

    def heading
      response.parsed_body.at_css("main h1").text.strip
    end

    it "shows only the current user's posts" do
      create(:post, user: other_user, title: "Someone Else's Post")

      get posts_path, params: { feed: "mine" }

      expect(heading).to eq("My Posts")
      expect(response.body).to include("Original Title")
      expect(response.body).not_to include("Someone Else's Post")
    end

    it "still shows the user's posts in the main feed and category feeds" do
      get posts_path
      expect(response.body).to include("Original Title")

      get posts_path, params: { category: "Housing" }
      expect(response.body).to include("Original Title")
    end

    it "does not show the user's expired posts" do
      post_record.update_column(:expires_at, 1.day.ago)

      get posts_path, params: { feed: "mine" }

      expect(response.body).not_to include("Original Title")
      expect(response.body).to include("You don't have any active posts yet.")
    end

    it "keeps the My Posts filter when sorting" do
      get posts_path, params: { feed: "mine" }
      sort_link = response.parsed_body.css(".feed_sort a").find { |a| a.text.strip == "Trending" }
      expect(sort_link["href"]).to eq(posts_path(feed: "mine", sort: "trending"))
    end

    it "links to My Activity from the category bar" do
      get posts_path, params: { feed: "mine" }
      link = response.parsed_body.at_css("a.my_activity_tab")
      expect(link["href"]).to eq(my_activity_path)
    end
  end

  describe "feed cards and sorting" do
    before { sign_in other_user }

    def card_titles
      response.parsed_body.css(".post_card_title").map { |node| node.text.strip }
    end

    it "sorts by trending when asked" do
      busy = create(:post, user: author, title: "Busy Post", category: "Social")
      busy.update_column(:created_at, 2.days.ago)
      create_list(:reply, 2, post: busy)

      get posts_path, params: { sort: "trending" }

      expect(card_titles.first).to eq("Busy Post")
    end

    it "falls back to newest first for an unknown sort" do
      post_record.update_column(:created_at, 2.days.ago)
      create(:post, user: author, title: "Newest Post")

      get posts_path, params: { sort: "bogus" }

      expect(response).to have_http_status(:ok)
      expect(card_titles.first).to eq("Newest Post")
    end

    it "keeps the category filter while sorting" do
      create(:post, user: author, title: "Social Post", category: "Social")

      get posts_path, params: { category: "Housing", sort: "trending" }

      expect(card_titles).to eq([ "Original Title" ])
    end

    it "keeps the current filter in the sort links" do
      get posts_path, params: { category: "Housing" }

      link = response.parsed_body.css(".feed_sort_option").find { |a| a.text.strip == "Trending" }
      expect(link["href"]).to eq(posts_path(category: "Housing", sort: "trending"))
    end

    it "shows the reply count on each card" do
      create_list(:reply, 2, post: post_record)

      get posts_path

      expect(response.parsed_body.at_css(".post_card").text).to include("2 replies")
    end

    it "shows Anonymous instead of the author on anonymous posts" do
      post_record.update!(anonymous: true)

      get posts_path

      card = response.parsed_body.at_css(".post_card").text
      expect(card).to include("Anonymous")
      expect(card).not_to include("Author User")
    end

    it "does not put edit or delete controls on cards" do
      sign_in author

      get posts_path

      cards = response.parsed_body.css(".post_card")
      expect(cards.text).not_to include("Edit", "Delete")
      expect(cards.css("button").map { |b| b["aria-label"] }).to all(match(/\A(Like|Unlike) /))
    end

    it "shows the like count and whether I liked each card" do
      create(:like, post: post_record, user: other_user)

      get posts_path

      button = response.parsed_body.at_css(".post_card .like_button")
      expect(button.at_css(".like_count").text).to eq("1")
      expect(button["aria-label"]).to eq("Unlike Original Title")
    end
  end

  describe "main navigation" do
    before { sign_in other_user }

    def home_link
      response.parsed_body.at_css("a.nav_icon[aria-label='Home']")
    end

    it "marks the Home icon as current only on the unfiltered feed" do
      get posts_path
      expect(home_link["href"]).to eq(root_path)
      expect(home_link["aria-current"]).to eq("page")

      get posts_path, params: { category: "Housing" }
      expect(home_link["aria-current"]).to be_nil
    end

    it "shows the signed-in user's name and email in the profile menu" do
      get posts_path

      menu = response.parsed_body.at_css(".profile_menu")
      expect(menu.at_css("summary.avatar").text.strip).to eq("O")
      expect(menu.text).to include("Other User", "other@barnard.edu")
    end

    it "links the + button to the new post form and marks it current there" do
      get posts_path
      button = response.parsed_body.at_css("a.new_post_button")
      expect(button["href"]).to eq(new_post_path)
      expect(button["aria-current"]).to be_nil

      get new_post_path
      expect(response.parsed_body.at_css("a.new_post_button")["aria-current"]).to eq("page")
    end
  end

  describe "new and edit post forms" do
    before { sign_in author }

    def form
      response.parsed_body.at_css("form.post_form")
    end

    it "offers every category and expiration preset as a choice on the new form" do
      get new_post_path

      back_link = response.parsed_body.at_css("a.back_link")
      expect(back_link.text.strip).to eq("← Back to My Activity")
      expect(back_link["href"]).to eq(my_activity_path)

      categories = form.css("input[type=radio][name='post[category]']").map { |r| r["value"] }
      presets = form.css("input[type=radio][name='post[expiration_preset]']").map { |r| r["value"] }
      expect(categories).to eq(Post::CATEGORIES)
      expect(presets).to eq(Post::EXPIRATION_PRESETS)
      expect(form.at_css("a", text: "Cancel")["href"]).to eq(posts_path)
    end

    it "keeps what was typed when creating fails" do
      post posts_path, params: { post: { title: "", body: "Keep me", category: "Social", expiration_preset: "Tonight" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Title can&#39;t be blank", "Keep me")
      expect(form.at_css("input[name='post[category]'][value='Social']")["checked"]).to eq("checked")
    end

    it "prefills the edit form with the current category and expiration" do
      get edit_post_path(post_record)

      expect(form.at_css("input[name='post[category]'][value='Housing']")["checked"]).to eq("checked")
      expect(form.at_css("input[name='post[expiration_preset]'][value='Custom']")["checked"]).to eq("checked")
      expect(form.at_css("input[name='post[custom_expires_at]']")["value"])
        .to eq(post_record.expires_at.strftime("%Y-%m-%dT%H:%M:%S"))
      expect(form.at_css("a", text: "Cancel")["href"]).to eq(post_path(post_record))
    end

    it "sends Cancel on the edit form to the feed once the post has expired" do
      post_record.update_column(:expires_at, 1.day.ago)

      get edit_post_path(post_record)

      expect(form.at_css("a", text: "Cancel")["href"]).to eq(posts_path)
    end

    it "keeps the expiration when only the title is edited" do
      original = post_record.expires_at

      get edit_post_path(post_record)
      prefilled = form.at_css("input[name='post[custom_expires_at]']")["value"]
      patch post_path(post_record), params: { post: { title: "Renamed", expiration_preset: "Custom", custom_expires_at: prefilled } }

      expect(post_record.reload).to have_attributes(title: "Renamed", expires_at: original)
    end

    it "shows when a post ends on its card and its page" do
      get posts_path
      expect(response.parsed_body.at_css(".post_card .post_expiration").text).to include("ENDS:")

      get post_path(post_record)
      expect(response.parsed_body.at_css(".post_detail .post_expiration time")["datetime"])
        .to eq(post_record.expires_at.iso8601)
    end
  end
end
