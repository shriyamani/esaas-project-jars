require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is a valid user if it has a name and Columbia/Barnard email" do
      expect(build(:user)).to be_valid
    end

    it "requires a name" do
      expect(build(:user, name: "")).not_to be_valid
    end

    it "requires a Columbia/Barnard email" do
      expect(build(:user, email: "")).not_to be_valid
    end

    it "rejects a duplicate email and is case insensitive" do
      create(:user, email: "sm5586@barnard.edu")
      expect(build(:user, email: "SM5586@barnard.edu")).not_to be_valid
    end

    it "stores emails in lowercase and no extra spaces" do
      user = create(:user, email: "  SM5586@Barnard.EDU ")
      expect(user.email).to eq("sm5586@barnard.edu")
    end
  end

  describe "email domain" do
    %w[sm5586@barnard.edu jsw2219@columbia.edu ay2667@columbia.edu SM5586@barnard.EDU].each do |email|
      it "accepts #{email}" do
        expect(build(:user, email: email)).to be_valid
      end
    end

    %w[lionden@gmail.com fake@notcolumbia.edu testing@columbia.edu.not.com fake@barnard.com].each do |email|
      it "rejects #{email}" do
        user = build(:user, email: email)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("must be a Columbia or Barnard address")
      end
    end
  end

  describe ".from_omniauth" do
    def auth(email, name: "Testing Tester")
      OmniAuth::AuthHash.new(info: { email: email, name: name })
    end

    it "recognizes/registers a user when they first sign-in" do
      expect { User.from_omniauth(auth("rc3934@columbia.edu")) }.to change(User, :count).by(1)
    end

    it "saves the name and email from Google" do
      user = User.from_omniauth(auth("sm5586@barnard.edu"))
      expect(user.name).to eq("Testing Tester")
      expect(user.email).to eq("sm5586@barnard.edu")
    end

    it "identifies returning users" do
      User.from_omniauth(auth("rc3934@columbia.edu"))
      user = nil
      expect {
        user = User.from_omniauth(auth("rc3934@columbia.edu", name: "Ritika Calyanakoti"))
      }.not_to change(User, :count)
      expect(user.name).to eq("Ritika Calyanakoti")
    end

    it "is case insensitive when matching emails" do
      User.from_omniauth(auth("sm5586@barnard.edu"))
      expect { User.from_omniauth(auth("SM5586@Barnard.edu")) }.not_to change(User, :count)
    end

    it "returns an error for a non-Columbia or Barnard email" do
      user = User.from_omniauth(auth("lionden@gmail.com"))
      expect(user).not_to be_persisted
      expect(user.errors[:email]).to include("must be a Columbia or Barnard address")
    end
  end
end