class PeriodicTimelineCacheWarmJob < ApplicationJob
  queue_as :timeline_cache

  def perform
    # Warm cache for users who have been active in the last 24 hours
    active_users = User.joins(:posts)
                      .where(posts: { created_at: 24.hours.ago..Time.current })
                      .distinct
                      .pluck(:id)

    active_users.each do |user_id|
      TimelineCacheWarmJob.perform_later(user_id)
    end

    Rails.logger.info "Queued timeline cache warming for #{active_users.count} active users"

  rescue => e
    Rails.logger.error "PeriodicTimelineCacheWarmJob failed: #{e.message}"
    raise e
  end
end
