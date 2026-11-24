# README
COMSW4152 Engineering Software-as-a-Service

### LionDen: Everything happening at Columbia 

**Group Members**
- Angelina Yeh (ay2667)
- Ritika Calyanakoti (rc3934)
- Janice Wong (jsw2219)
- Shriya Mani (sm5586)

## Heroku deployed app
https://lionden-cu-57aca13d2150.herokuapp.com \
Sign in with a Columbia or Barnard email account.

## Running locally
Requires Ruby 3.3.12 and Bundler.
```bash
git clone https://github.com/shriyamani/esaas-project-jars.git
cd esaas-project-jars
bundle config set --local without production
bundle install
bin/rails db:prepare
```
Create a `.env` file in the project root (provided in Courseworks submission):
```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
```
Then run `bin/rails server` and visit http://localhost:3000.

## Running tests
No real Google credentials are needed for tests.
```bash
bundle exec rspec       # RSpec validations
bundle exec cucumber    # Cucumber stories
```
Run both suites sequentially, then review `coverage/index.html` for missed lines.
`bin/ci` runs both suites as part of the project checks.

## Current features
#### 1. Google O-Auth
Currently, LionDen is authenticated via Google O-Auth. When the application is accessed, it will prompt users to
sign-in with Google.\
Only Columbia or Barnard email addresses will be allowed to sign-in and access LionDen. 
- On sign-in success, the Home Page will display the message "Coming soon!"
- On sign-in failure (ex: logging with a non-Columbia or Barnard email), the log-in page displays again with the message 
"Google sign-in failed. Please try again." at the top of the page.

#### 2. Login Screen
On the login screen, when a user isn't signed in, they can see the following three tabs:
- **About**: Overview of COMSW4152 and the project
- **FAQ**: Information about LionDen
- **Contact**: Emails of group members

#### 3. Posts
After signing in, users land on the **All** tab, which displays all the posts on the platform.
- **Posts:** show the author (or "Anonymous"), how long ago it was posted, the title, a preview of the body, the category, likes, reply count, and when the post ends. Clicking on a post opens its individual page.
- **Categories:** All · Following · Social · Academics · Housing · Buy/Sell · Travel · Help
  - If you click on a category, the posts are filtered to only those in that category
  - Clicking on a category's **bookmark** follows it. Anytime a post is posted under that category, you get a notification. Followed categories move to the front.
  - **Following** shows posts only from followed categories (if no categories are followed, it prompts you to follow a category).
- **Sort:** Newest (default) or **Trending**, which classifies posts by likes and replies from other students within the last 48 hours.
- **Search:** keyword search across post titles and bodies, combined with the current category/view and sort.
- **Expiration:** every post disappears from the board automatically when it ends.

#### 4. New Post
The **+** button in the top bar opens the New Post card. Users choose between making a regular post or event.
- Title, body, and category
- **Expires:** Tonight, This week, or a custom date and time
- **Post anonymously:** the author's name is hidden everywhere (cards, the post page, chats about the post)
- **Event details** (optional): date, time, and location, included on the calendar event.
- **Spots** (optional): how many people the author is looking for

Authors can **edit** or **delete** their own posts from the post page. Editing keeps the original expiration selected unless a new one is chosen.

#### 5. Individual Post Page
- Full post with author, time posted, category, likes, reply count, and expiration.
- **Likes:** heart a post (once per user) – the count is shown on cards and the post page.
- **Replies:** newest first, with the reply box at the top. Long threads show the 5 newest with a "Show older replies" link. Replies can be anonymous, the post's author is marked with an **Author** badge, and students can edit or delete their own replies. Expired posts can't receive new replies.
- **Events:** shows the date, time, location, and attendee count, with **I'm going / Un-RSVP**.
- **Joining:** posts with spots show "X of Y spots filled" and a **Join** button. Joining adds you to the post's group chat; **Leave** frees your spot and removes you from the chat.

#### 6. Messaging
The **✉** icon in the top bar (with an unread count) opens the Messages page.
- **Chats** tab: every private chat and group chat, newest activity first, with unread chats in bold with a red dot.
- **Contacts** tab: everyone you've had a private conversation with, A–Z, with their email and a **Message** button.
- **Starting a chat:**
  - Click a student's **avatar** on a post or reply, then **Message** (not available for anonymous posts/replies or yourself), or
  - Click **+ New message** and enter their Columbia/Barnard email.
- **In a chat:** can see your messages and their messages, with Instagram-style timestamps (Just now, 5 min ago, 3h ago, 2d ago, 12w ago).
  - **Read receipts:** your latest message shows **Sent**, then **Seen** once they open the chat (in group chats, **Seen by** each person).
  - **Edit** your own messages within 15 minutes; edited messages are labeled.
- **Group chats** are created automatically for posts with spots specified by the author. The post's author can rename the group chat.

#### 7. Calendar
The **calendar** icon in the top bar opens a calendar in month-view with all events/posts on it.
- **All events** or **My events** (events you posted or RSVP'd to)
- Filter by category with the categories
- An **Upcoming Events** list below the calendar

#### 8. Notifications
Students are notified when:
- Someone posts in a category they follow
- Someone replies to their post
- Someone RSVPs to their event
- Someone joins or leaves their post
- They receive a message

Notifications can be accessed via the **🔔** icon in the top right corner.

#### 9. My Activity
Click the "My Activity" tab or open the profile menu (your avatar in the top right) and choose **My Activity** to see:
- **My posts**
- **Posts I joined**
- **Events I RSVP'd to**

