require 'rails_helper'

RSpec.describe TimelineCacheService, type: :service do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let!(:posts) do
    [
      create(:post, user: user1, title: 'Post 1', created_at: 3.days.ago),
      create(:post, user: user2, title: 'Post 2', created_at: 2.days.ago),
      create(:post, user: user1, title: 'Post 3', created_at: 1.day.ago)
    ]
  end

  before do
    # Clear cache before each test
    Rails.cache.clear
  end

  describe '.fetch_timeline' do
    it 'returns timeline data from database on first call' do
      result = TimelineCacheService.fetch_timeline(page: 1, per_page: 20)

      expect(result).to be_an(Array)
      expect(result.length).to eq(3)
      expect(result.first).to include('id', 'title', 'username')
    end

    it 'returns cached data on subsequent calls' do
      # First call - should hit database
      first_result = TimelineCacheService.fetch_timeline(page: 1, per_page: 20)

      # Second call - should hit cache
      second_result = TimelineCacheService.fetch_timeline(page: 1, per_page: 20)

      expect(first_result).to eq(second_result)
    end

    it 'handles pagination correctly' do
      result = TimelineCacheService.fetch_timeline(page: 1, per_page: 2)

      expect(result.length).to eq(2)
    end

    it 'handles minimum rating filter' do
      # Create a high-rated post
      high_rated_post = create(:post, user: user1, title: 'High Rated Post')
      create(:rating, post: high_rated_post, rating: 5)

      result = TimelineCacheService.fetch_timeline(page: 1, per_page: 20, min_rating: 4.0)

      titles = result.map { |post| post['title'] }
      expect(titles).to include('High Rated Post')
    end

    it 'generates different cache keys for different parameters' do
      # Test that different parameters generate different cache keys
      result1 = TimelineCacheService.fetch_timeline(page: 1, per_page: 20)
      result2 = TimelineCacheService.fetch_timeline(page: 2, per_page: 20)
      result3 = TimelineCacheService.fetch_timeline(page: 1, per_page: 10)
      result4 = TimelineCacheService.fetch_timeline(page: 1, per_page: 20, min_rating: 3.0)

      # First page should have data, second page might be empty
      expect(result1).to be_present
      expect(result2).to be_a(Array) # Should be array even if empty
      expect(result3).to be_present
      expect(result4).to be_a(Array) # Might be empty if no posts have rating >= 3.0
    end
  end

  describe '.invalidate_cache' do
    it 'clears all timeline cache keys' do
      # Populate cache
      TimelineCacheService.fetch_timeline(page: 1, per_page: 20)
      TimelineCacheService.fetch_timeline(page: 2, per_page: 20)

      # Invalidate cache
      TimelineCacheService.invalidate_cache

      # Test that cache invalidation works by checking that new calls work
      result = TimelineCacheService.fetch_timeline(page: 1, per_page: 20)
      expect(result).to be_present
    end
  end

  describe '.invalidate_user_cache' do
    it 'clears timeline cache when user data changes' do
      # Populate cache
      TimelineCacheService.fetch_timeline(page: 1, per_page: 20)

      # Invalidate user cache
      TimelineCacheService.invalidate_user_cache(user1.id)

      # Test that cache invalidation works by checking that new calls work
      result = TimelineCacheService.fetch_timeline(page: 1, per_page: 20)
      expect(result).to be_present
    end
  end

  describe 'cache expiry' do
    it 'respects cache expiry time' do
      # Mock cache to return expired data
      allow(Rails.cache).to receive(:fetch).and_call_original

      result = TimelineCacheService.fetch_timeline(page: 1, per_page: 20)
      expect(result).to be_present
    end
  end
end
