require "rails_helper"

RSpec.describe CategoryFollow, type: :model do
  it "is valid with a user and a real category" do
    expect(build(:category_follow)).to be_valid
  end

  it "requires a user" do
    expect(build(:category_follow, user: nil)).not_to be_valid
  end

  it "rejects a category that doesn't exist" do
    expect(build(:category_follow, category: "Memes")).not_to be_valid
  end

  it "rejects 'All posts', which is not a real category" do
    expect(build(:category_follow, category: "All posts")).not_to be_valid
  end

  it "rejects following the same category twice" do
    user = create(:user)
    create(:category_follow, user: user, category: "Housing")
    expect(build(:category_follow, user: user, category: "Housing")).not_to be_valid
    expect { create(:category_follow, user: user, category: "Housing") }
      .to raise_error(ActiveRecord::RecordInvalid)
    expect(user.category_follows.where(category: "Housing").count).to eq(1)
  end

  it "allows one user to follow different categories" do
    user = create(:user)
    create(:category_follow, user: user, category: "Housing")

    expect(create(:category_follow, user: user, category: "Academics")).to be_persisted
  end

  it "lets two different users follow the same category" do
    create(:category_follow, category: "Housing")
    expect(build(:category_follow, category: "Housing")).to be_valid
  end
end
