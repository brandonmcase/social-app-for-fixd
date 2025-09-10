class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :rating, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :post_id }

  # When a rating changes, update cached stats atomically
  after_commit :refresh_post_caches, on: [ :create, :update, :destroy ]

  private

  def refresh_post_caches
    return unless post.persisted?

    # Use a separate transaction to ensure cache updates are atomic
    # even if the main transaction fails
    ActiveRecord::Base.transaction do
      post.with_lock do
        counts = post.ratings.count
        avg    = counts.zero? ? 0 : post.ratings.average(:rating).to_f.round(2)
        post.update!(rating_count: counts, average_rating: avg)
      end
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::StaleObjectError => e
    # Log the error but don't fail the rating operation
    Rails.logger.warn "Failed to update post cache for rating #{id}: #{e.message}"
  end
end
