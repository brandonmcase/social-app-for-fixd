class TimelineCacheService
  CACHE_EXPIRY = 5.minutes
  CACHE_KEY_PREFIX = "timeline"

  def self.fetch_timeline(page: 1, per_page: 20, min_rating: nil)
    cache_key = build_cache_key(page, per_page, min_rating)

    Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
      fetch_timeline_from_db(page, per_page, min_rating)
    end
  end

  def self.invalidate_cache
    # Invalidate all timeline cache keys
    Rails.cache.delete_matched("#{CACHE_KEY_PREFIX}:*")
  end

  def self.invalidate_user_cache(user_id)
    # Invalidate timeline cache when user creates/updates/deletes posts
    Rails.cache.delete_matched("#{CACHE_KEY_PREFIX}:*")
  end

  private

  def self.build_cache_key(page, per_page, min_rating)
    key_parts = [ CACHE_KEY_PREFIX, page, per_page ]
    key_parts << "min_rating_#{min_rating}" if min_rating.present?
    key_parts.join(":")
  end

  def self.fetch_timeline_from_db(page, per_page, min_rating)
    posts = Post.active
                .includes(:user)
                .order(created_at: :desc)
                .page(page)
                .per(per_page)

    # Apply minimum rating filter if provided
    if min_rating.present?
      posts = posts.where("average_rating >= ?", min_rating.to_f)
    end

    posts.as_json(
      only: [ :id, :title, :body, :view_count, :average_rating, :rating_count, :created_at ],
      methods: [ :username ],
      include: {
        user: {
          only: [ :id, :username ]
        }
      }
    )
  end
end
