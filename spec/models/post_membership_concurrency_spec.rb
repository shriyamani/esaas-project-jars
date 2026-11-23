
require "rails_helper"

RSpec.describe "Post membership concurrency", type: :model do
  self.use_transactional_tests = false

  around do |example|
    DatabaseCleaner.clean_with(:truncation)
    example.run
  ensure
    DatabaseCleaner.clean_with(:truncation)
  end

  it "prevents two students from taking the last spot simultaneously" do
    author = create(:user)
    student1 = create(:user)
    student2 = create(:user)
    post_record = create(:post, user: author, spots_available: 1)

    start = Queue.new
    results = Queue.new

    threads = [student1.id, student2.id].map do |user_id|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          start.pop

          begin
            Post.transaction do
              Post.where(id: post_record.id)
                  .update_all("updated_at = updated_at")

              current_post = Post.find(post_record.id)

              if current_post.full?
                raise ActiveRecord::RecordNotSaved, "Post is full"
              end

              current_post.post_memberships.create!(user_id: user_id)
            end

            results << :joined
          rescue ActiveRecord::RecordNotSaved
            results << :full
          rescue ActiveRecord::StatementInvalid => e
            if e.cause.is_a?(SQLite3::BusyException)
              results << :busy
            else
              results << e
            end
          rescue StandardError => e
            results << e
          end
        end
      end
    end

    2.times { start << true }
    threads.each(&:join)

    outcomes = 2.times.map { results.pop }

    expect(outcomes.grep(Exception)).to be_empty
    expect(outcomes.count(:joined)).to eq(1)
    expect(post_record.reload.spots_filled).to eq(1)
    expect(post_record.full?).to be true
  end
end
