class ViewCountUpdateJob < ApplicationJob
  queue_as :view_counts

  def perform(post_id, user_id = nil)
    post = Post.find(post_id)

    # Use distributed lock to prevent race conditions
    DistributedLockService.with_post_cache_lock(post.id) do
      # Increment view count atomically
      post.with_lock do
        post.increment!(:view_count)
      end
    end

    Rails.logger.info "Updated view count for post #{post_id} to #{post.reload.view_count}"

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "ViewCountUpdateJob failed: #{e.message}"
  rescue DistributedLockService::LockTimeout => e
    Rails.logger.warn "ViewCountUpdateJob failed to acquire lock: #{e.message}"
    # Retry the job if lock acquisition fails
    raise e
  end
end
