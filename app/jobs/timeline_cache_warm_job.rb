class TimelineCacheWarmJob < ApplicationJob
  queue_as :timeline_cache

  def perform(user_id = nil)
    if user_id
      # Warm cache for specific user
      TimelineCacheService.warm_user_cache(user_id)
      Rails.logger.info "Warmed timeline cache for user #{user_id}"
    else
      # Warm cache for all active users
      User.find_each do |user|
        TimelineCacheService.warm_user_cache(user.id)
      end
      Rails.logger.info "Warmed timeline cache for all users"
    end

  rescue => e
    Rails.logger.error "TimelineCacheWarmJob failed: #{e.message}"
    raise e
  end
end
