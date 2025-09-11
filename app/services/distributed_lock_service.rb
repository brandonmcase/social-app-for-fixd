class DistributedLockService
  include Redis::Lock

  # Custom exception for lock timeouts
  class LockTimeout < StandardError; end

  def self.with_lock(key, timeout: 10, retry_delay: 0.1, retry_count: 10)
    # In test environment, skip locking to avoid Redis dependency
    if Rails.env.test?
      yield
      return
    end

    begin
      redis = Redis.new(url: Rails.application.config.redis_url || "redis://localhost:6379/0")

      lock_key = "lock:#{key}"
      lock_value = SecureRandom.uuid

      # Try to acquire the lock
      acquired = redis.set(lock_key, lock_value, nx: true, ex: timeout)

      if acquired
        begin
          yield
        ensure
          # Only release the lock if we still own it
          redis.eval(
            "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end",
            [ lock_key ],
            [ lock_value ]
          )
        end
      else
        # Retry logic
        retry_count.times do
          sleep(retry_delay)
          acquired = redis.set(lock_key, lock_value, nx: true, ex: timeout)
          break if acquired
        end

        unless acquired
          raise LockTimeout, "Could not acquire lock for key: #{key}"
        end

        begin
          yield
        ensure
          redis.eval(
            "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end",
            [ lock_key ],
            [ lock_value ]
          )
        end
      end
    rescue Redis::BaseError, Errno::ECONNREFUSED => e
      # If Redis is not available, log warning and proceed without locking
      Rails.logger.warn "Redis not available for distributed locking: #{e.message}"
      yield
    end
  end

  def self.with_rating_lock(post_id, user_id, &block)
    lock_key = "rating:#{post_id}:#{user_id}"
    with_lock(lock_key, timeout: 30, &block)
  end

  def self.with_post_cache_lock(post_id, &block)
    lock_key = "post_cache:#{post_id}"
    with_lock(lock_key, timeout: 10, &block)
  end
end
