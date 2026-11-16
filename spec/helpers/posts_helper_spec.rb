require "rails_helper"

RSpec.describe PostsHelper, type: :helper do
  around { |example| travel_to(Time.zone.local(2026, 11, 16, 10, 0)) { example.run } }

  describe "#expiration_label" do
    it "describes the day in a friendly way" do
      expect(helper.expiration_label(Time.zone.local(2026, 11, 16, 23, 59))).to eq("Today, 11:59 PM")
      expect(helper.expiration_label(Time.zone.local(2026, 11, 17, 9, 0))).to eq("Tomorrow, 9:00 AM")
      expect(helper.expiration_label(Time.zone.local(2026, 11, 20, 18, 30))).to eq("Fri, 6:30 PM")
      expect(helper.expiration_label(Time.zone.local(2026, 12, 25, 12, 0))).to eq("Dec 25, 12:00 PM")
      expect(helper.expiration_label(Time.zone.local(2027, 1, 5, 12, 0))).to eq("Jan 5, 2027, 12:00 PM")
    end
  end

  describe "#time_remaining" do
    it "counts minutes under an hour and rounds longer times" do
      expect(helper.time_remaining(20.seconds.from_now)).to eq("1 minute")
      expect(helper.time_remaining(1.second.ago)).to eq("less than a minute")
      expect(helper.time_remaining(45.minutes.from_now)).to eq("45 minutes")
      expect(helper.time_remaining(3.hours.from_now)).to eq("3 hours")
    end
  end
end
