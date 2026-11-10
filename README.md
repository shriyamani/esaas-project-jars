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

## Current features
1. **Google O-Auth**\
Currently, LionDen is authenticated via Google O-Auth. When the application is accessed, it will prompt users to
sign-in with Google.\
Only Columbia or Barnard email addresses will be allowed to sign-in and access LionDen. 
- On sign-in success, the Home Page will display the message "Coming soon!"
- On sign-in failure (ex: logging with a non-Columbia or Barnard email), the log-in page displays again with the message 
"Google sign-in failed. Please try again." at the top of the page.

2. **View Posts**\
Clicking on "Posts" in the top left of the page will display a page of all the current posts made on LionDen.\
At the top, you will see all the different categories that posts can be tagged under. The posts page can be filtered
to only display posts under a specific category by clicking on the category.

> - All Posts 
> - Social 
> - Academics 
> - Housing 
> - Buy/Sell 
> - Travel 
> - Help

Underneath the category filters, there is the "New Post" function which, when clicked, allows users to create a new post 
to be published on LionDen.

The posts page displays the following information about each post:
> - Post title
> - Category
> - Author
> - Expiration date
> - Post description

And a "View" functionality that when clicked, allows users to view the individual post.

If the post was authored by the user who is currently logged in, there will additionally be the following functionalities under the Post
- **Edit**: allows the authoring user to edit any of the fields mentioned above on the post
- **Delete**: allows the authoring user to delete the post, such that it no longer displays on the Post page

3. **New Post**\
Clicking on "New Post" in top left of the page will take users to a form where they can make a post.\
These are the following fields that need to be filled out:
> - Title
> - Body
> - Category
> - *Option to post anonymously (if left unchecked, user's name will display alongside the post)*
> - Expiration date
>   - Either "Today", "This week" or a custom expiration date which the user chooses


### Expanded UI and additional features coming soon!