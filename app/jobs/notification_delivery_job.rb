class NotificationDeliveryJob < ApplicationJob
  queue_as :notifications

  def perform(post_id, rating_user_id, rating_value)
    post = Post.find(post_id)
    rating_user = User.find(rating_user_id)

    # Skip notification if user is rating their own post
    return if post.user_id == rating_user_id

    # Create notification for post owner
    notification = {
      type: "post_rated",
      post_id: post_id,
      post_title: post.title,
      rater_username: rating_user.username,
      rating: rating_value,
      created_at: Time.current
    }

    # In a real application, you might:
    # 1. Store notification in database
    # 2. Send email notification
    # 3. Send push notification
    # 4. Update real-time feed

    Rails.logger.info "Notification: #{notification}"

    # Example: Store in Redis for real-time notifications (skip in test)
    unless Rails.env.test?
      redis_key = "notifications:#{post.user_id}"
      Redis.current.lpush(redis_key, notification.to_json)
      Redis.current.expire(redis_key, 7.days.to_i) # Keep notifications for 7 days
    end

    # Example: Send email notification (uncomment if you have email configured)
    # NotificationMailer.post_rated(post.user, post, rating_user, rating_value).deliver_now

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "NotificationDeliveryJob failed: #{e.message}"
  end
end
