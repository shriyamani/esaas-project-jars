require "rails_helper"

RSpec.describe Reply, type: :model do
  subject(:reply) { build(:reply) }

  it "accepts a reply to an active post" do
    expect(reply).to be_valid
  end

  it "requires a post and user" do
    reply.post = nil
    reply.user = nil
    expect(reply).not_to be_valid
    expect(reply.errors[:post]).to be_present
    expect(reply.errors[:user]).to be_present
  end

  it "requires a body of at most 2000 characters" do
    reply.body = " "
    expect(reply).not_to be_valid
    reply.body = "a" * 2000
    expect(reply).to be_valid
    reply.body += "a"
    expect(reply).not_to be_valid
  end

  it "rejects an expired post, including exactly at expiration" do
    travel_to Time.current.change(usec: 0) do
      reply.post.expires_at = Time.current
      expect(reply).not_to be_valid
      expect(reply.errors[:post]).to include("has expired")
    end
  end

  it "rejects a post without an expiration" do
    reply.post.expires_at = nil
    expect(reply).not_to be_valid
  end

  it "uses the user's name unless anonymous" do
    expect(reply.display_author).to eq(reply.user.name)
    reply.anonymous = true
    expect(reply.display_author).to eq("Anonymous")
  end

  it "preserves existing replies after expiration" do
    reply.save!
    reply.post.update_column(:expires_at, 1.minute.ago)
    expect(reply.reload.update(body: "Updated reply")).to be true
  end
end
