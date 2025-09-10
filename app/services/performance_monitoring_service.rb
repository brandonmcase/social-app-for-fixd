class PerformanceMonitoringService
  def self.log_slow_queries(threshold_ms = 100)
    ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)

      if event.duration > threshold_ms
        Rails.logger.warn "SLOW QUERY (#{event.duration.round(2)}ms): #{event.payload[:sql]}"
        Rails.logger.warn "Bindings: #{event.payload[:binds]}" if event.payload[:binds].present?
      end
    end
  end

  def self.log_request_performance(threshold_ms = 500)
    ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)

      if event.duration > threshold_ms
        Rails.logger.warn "SLOW REQUEST (#{event.duration.round(2)}ms): #{event.payload[:method]} #{event.payload[:path]}"
        Rails.logger.warn "View: #{event.payload[:view_runtime]}ms, DB: #{event.payload[:db_runtime]}ms"
      end
    end
  end

  def self.optimize_database_queries
    # Enable query optimization logging in development
    if Rails.env.development?
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ActiveRecord::Base.logger.level = Logger::DEBUG
    end
  end

  def self.cache_key_for_posts(posts)
    # Generate cache key based on post IDs and timestamps
    post_ids = posts.pluck(:id, :updated_at).flatten.join("-")
    Digest::MD5.hexdigest(post_ids)
  end

  def self.benchmark_query(name, &block)
    start_time = Time.current
    result = yield
    duration = (Time.current - start_time) * 1000

    Rails.logger.info "QUERY BENCHMARK: #{name} took #{duration.round(2)}ms"
    result
  end
end
