require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#short_time_ago" do
    it "uses short labels for minutes, hours, days and weeks" do
      expect(helper.short_time_ago(30.seconds.ago)).to eq("Just now")
      expect(helper.short_time_ago(5.minutes.ago)).to eq("5 min ago")
      expect(helper.short_time_ago(3.hours.ago)).to eq("3h ago")
      expect(helper.short_time_ago(2.days.ago)).to eq("2d ago")
      expect(helper.short_time_ago(15.days.ago)).to eq("2w ago")
    end
  end
end
