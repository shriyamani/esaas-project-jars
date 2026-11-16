require "rails_helper"

RSpec.describe Like, type: :model do
  it "is valid with a user and a post" do
    expect(build(:like)).to be_valid
  end

  it "rejects a user liking the same post twice" do
    like = create(:like)
    expect(build(:like, user: like.user, post: like.post)).not_to be_valid
  end

  it "lets two different users like the same post" do
    like = create(:like)
    expect(build(:like, post: like.post)).to be_valid
  end

  it "is deleted when its post or user is deleted" do
    like = create(:like)
    expect { like.post.destroy }.to change(Like, :count).by(-1)

    other = create(:like)
    expect { other.user.destroy }.to change(Like, :count).by(-1)
  end
end
