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