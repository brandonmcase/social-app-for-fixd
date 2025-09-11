class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :rating, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :post_id }

  # When a rating changes, update cached stats atomically
  after_commit :refresh_post_caches, on: [ :create, :update, :destroy ]
  after_commit :bust_search_cache, on: [ :create, :update, :destroy ]

  # Send notification when a new rating is created
  after_commit :send_notification, on: :create

  private

  def refresh_post_caches
    return unless post.persisted?

    # Use distributed lock to prevent race conditions when updating post cache
    DistributedLockService.with_post_cache_lock(post.id) do
      # Use a separate transaction to ensure cache updates are atomic
      # even if the main transaction fails
      ActiveRecord::Base.transaction do
        post.with_lock do
          counts = post.ratings.count
          avg    = counts.zero? ? 0 : post.ratings.average(:rating).to_f.round(2)
          post.update!(rating_count: counts, average_rating: avg)
        end
      end
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::StaleObjectError => e
    # Log the error but don't fail the rating operation
    Rails.logger.warn "Failed to update post cache for rating #{id}: #{e.message}"
  rescue DistributedLockService::LockTimeout => e
    # Log the error but don't fail the rating operation
    Rails.logger.warn "Failed to acquire lock for post cache update #{post.id}: #{e.message}"
  end

  def send_notification
    # Queue notification delivery asynchronously
    NotificationDeliveryJob.perform_later(post_id, user_id, rating)
  end

  def bust_search_cache
    Rails.cache.delete_matched("search:v1:*")
  end
end
